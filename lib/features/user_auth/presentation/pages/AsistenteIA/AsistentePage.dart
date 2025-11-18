import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

/// ---- SINGLETONS BÁSICOS ----
final FlutterTts _tts = FlutterTts();
final FirebaseFunctions functions =
    FirebaseFunctions.instanceFor(app: Firebase.app(), region: 'us-central1');

class AsistentePage extends StatefulWidget {
  const AsistentePage({super.key});

  @override
  State<AsistentePage> createState() => _AsistentePageState();
}

class _AsistentePageState extends State<AsistentePage> {
  // ===== STT =====
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _locale = 'es_ES'; // objetivo por defecto
  String _spokenText = '';
  Timer? _monitor;

  // ===== UI / Conversación =====
  final List<String> _history = [];

  // ===== TTS =====
  List<Map<String, String>> _voiceList = []; // [{name, locale, id}]
  Map<String, String>? _selectedVoice;       // voz activa
  double _rate = 0.9;
  double _pitch = 1.02;

  // ===== Preferencias =====
  static const _kVoiceKey = 'tts.voice.name';
  static const _kRateKey  = 'tts.rate';
  static const _kPitchKey = 'tts.pitch';

  @override
  void initState() {
    super.initState();
    _initEverything();
  }

  @override
  void dispose() {
    _monitor?.cancel();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initEverything() async {
    await _loadPrefs();
    await _initTTS();
    await _initSTT();
    _startListening();
  }

  // ----------------- PREFS -----------------
  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    _rate = sp.getDouble(_kRateKey) ?? 0.9;
    _pitch = sp.getDouble(_kPitchKey) ?? 1.02;
  }

  Future<void> _savePrefs() async {
    final sp = await SharedPreferences.getInstance();
    if (_selectedVoice != null) {
      await sp.setString(_kVoiceKey, _selectedVoice!['name']!);
    }
    await sp.setDouble(_kRateKey, _rate);
    await sp.setDouble(_kPitchKey, _pitch);
  }

  // ----------------- TTS -----------------
  Future<void> _initTTS() async {
    // 1) obtener voces crudas y filtrar español
    final raw = await _tts.getVoices; // dynamic list
    final list = (raw as List).cast<Map>().map((m) {
      final mm = Map<String, dynamic>.from(m);
      return {
        'name':   (mm['name'] ?? '').toString(),
        'locale': (mm['locale'] ?? '').toString(),
      };
    }).where((v) {
      final loc = v['locale']!.toLowerCase();
      return loc.startsWith('es'); // es-ES, es-US, es-MX, etc.
    }).toList();

    // Orden preferente
    list.sort((a, b) {
      int score(String loc) {
        final l = loc.toLowerCase();
        if (l.startsWith('es-es')) return 0;
        if (l.startsWith('es-mx')) return 1;
        if (l.startsWith('es-us')) return 2;
        return 3;
      }
      return score(a['locale']!).compareTo(score(b['locale']!));
    });

    _voiceList = list;

    // 2) seleccionar voz por preferencia o primera
    final sp = await SharedPreferences.getInstance();
    final preferred = sp.getString(_kVoiceKey);
    _selectedVoice = _voiceList.firstWhere(
      (v) => v['name'] == preferred,
      orElse: () => _voiceList.isNotEmpty ? _voiceList.first : {'name': '', 'locale': 'es-ES'},
    );

    // 3) aplicar voz/parametros
    await _applyVoiceAndParams();

    setState(() {});
  }

  Future<void> _applyVoiceAndParams() async {
    // Lenguaje base (fallback)
    await _tts.setLanguage((_selectedVoice?['locale'] ?? 'es-ES').replaceAll('_', '-'));
    // setVoice acepta Map<String, String>
    if (_selectedVoice != null && (_selectedVoice!['name'] ?? '').isNotEmpty) {
      await _tts.setVoice({
        'name': _selectedVoice!['name']!,
        'locale': _selectedVoice!['locale']!,
      });
    }
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(_pitch);
    await _savePrefs();
  }

  Future<void> _speak(String text) async {
    final polished = ttsPolish(text);
    await _tts.stop();
    await _tts.speak(polished);
  }

  // pequeñas pausas y cierre de frase

  String ttsPolish(String s) {
    var t = s.trim().replaceAll(RegExp(r'\s+'), ' ');

    // pequeñas pausas por conectores comunes
    t = t.replaceAllMapped(
      RegExp(r'\b(además|entonces|por ejemplo|así que|por cierto|mira)\b', caseSensitive: false),
      (Match m) => '${m.group(0)},',
    );

    // si no termina en puntuación, añade punto
    if (!RegExp(r'[.!?…]$').hasMatch(t)) t += '.';
    return t;
  }

  // ----------------- STT -----------------
  Future<void> _initSTT() async {
    final ok = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    _speechEnabled = ok;

    // Elegir locale español disponible
    final locales = await _speech.locales();
    String? chosen;
    String? fallback;

    for (final l in locales) {
      final id = l.localeId.toLowerCase();
      if (id.startsWith('es_es')) { chosen = l.localeId; break; }
      if (fallback == null && id.startsWith('es')) fallback = l.localeId;
    }
    _locale = (chosen ?? fallback ?? 'es_ES').replaceAll('-', '_');

    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechEnabled || _isListening) return;

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        partialResults: true,
        localeId: _locale,
        pauseFor: const Duration(seconds: 8),
      );
      if (mounted) setState(() => _isListening = true);
      _startMonitor();
    } catch (e) {
      debugPrint('❌ Error al iniciar escucha: $e');
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    _isListening = false;
    _monitor?.cancel();
    if (mounted) setState(() {});
  }

  void _startMonitor() {
    _monitor?.cancel();
    _monitor = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      if (!_speech.isListening && _isListening) {
        // reinicio rápido
        await _stopListening();
        await Future.delayed(const Duration(milliseconds: 200));
        await _startListening();
      }
    });
  }

  void _onSpeechStatus(String status) {
    debugPrint('🎤 STT status: $status');
    if (status == 'done' && _isListening) {
      _startMonitor();
    }
  }

  void _onSpeechError(dynamic error) async {
    debugPrint('❌ STT error: $error');
    if (mounted && _isListening) {
      await _stopListening();
      await Future.delayed(const Duration(milliseconds: 250));
      await _startListening();
    }
  }

  void _onSpeechResult(stt.SpeechRecognitionResult r) {
    if (!mounted) return;

    setState(() {
      _spokenText = r.recognizedWords.trim();
    });

    if (r.finalResult && _spokenText.isNotEmpty) {
      _history.add('Tú: $_spokenText');
      _replyWithAI(_spokenText);
    }
  }

  // -------------- IA --------------
  Future<void> _replyWithAI(String text) async {
    try {
      final reply = await _callAdan(text);
      setState(() => _history.add('ADAN: $reply'));
      await _speak(reply);
    } catch (e) {
      final msg = "Lo siento, hubo un problema al consultar la IA.";
      setState(() => _history.add('ADAN: $msg'));
      await _speak(msg);
    } finally {
      if (mounted && !_isListening) _startListening();
    }
  }

  Future<String> _callAdan(String text) async {
    final callable = functions.httpsCallable('adanChat');
    final res = await callable.call({
      'text': text,
      'profile': {'nombre': 'Jamin'}
    });
    final data = Map<String, dynamic>.from(res.data as Map);
    return (data['reply'] as String?) ?? '…';
  }

  // =============== UI ===============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente Virtual'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _initTTS();
              if (mounted) setState(() {});
            },
            tooltip: 'Recargar voces',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isListening ? Icons.mic : Icons.mic_off,
                    color: _isListening ? Colors.red : Colors.grey, size: 32),
                const SizedBox(width: 8),
                Text(_isListening ? 'Escuchando… ($_locale)' : 'No está escuchando',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),

            // Texto parcial
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(_spokenText.isEmpty ? 'Habla para comenzar…' : _spokenText),
            ),
            const SizedBox(height: 16),

            // Selector de voz
            if (_voiceList.isNotEmpty)
              Row(
                children: [
                  const Text('Voz: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<Map<String, String>>(
                      isExpanded: true,
                      value: _selectedVoice,
                      items: _voiceList.map((v) {
                        final show = '${v['name']}  (${v['locale']})';
                        return DropdownMenuItem(
                          value: v,
                          child: Text(show, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) async {
                        _selectedVoice = v;
                        await _applyVoiceAndParams();
                        if (mounted) setState(() {});
                        _speak('Listo, he cambiado mi voz.');
                      },
                    ),
                  ),
                ],
              ),

            // sliders
            Row(
              children: [
                const Text('Velocidad'),
                Expanded(
                  child: Slider(
                    value: _rate,
                    min: 0.5,
                    max: 1.3,
                    divisions: 8,
                    label: _rate.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _rate = v),
                    onChangeEnd: (_) async { await _applyVoiceAndParams(); },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Tono'),
                Expanded(
                  child: Slider(
                    value: _pitch,
                    min: 0.8,
                    max: 1.3,
                    divisions: 10,
                    label: _pitch.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _pitch = v),
                    onChangeEnd: (_) async { await _applyVoiceAndParams(); },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Historial
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Historial', style: TextStyle(fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _history.clear()),
                )
              ],
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _history.isEmpty
                    ? const Center(child: Text('Sin mensajes aún.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _history.length,
                        itemBuilder: (_, i) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.chat_bubble_outline, size: 18),
                          title: Text(_history[i]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isListening ? _stopListening : _startListening,
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}

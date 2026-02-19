import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';

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
  bool _wasListeningBeforePlayback = false;
  String _locale = 'es_ES'; // objetivo por defecto
  String _spokenText = '';
  Timer? _monitor;

  // ===== UI / Conversación =====
  final List<String> _history = [];
  final List<Map<String, String>> _conversationHistory = []; // Para enviar a la IA
  String? _lastProcessedPrompt; // evitar enviar dos veces el mismo texto seguido
  String? _userId;
  String? _currentConversationId;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ===== Campo de texto =====
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  bool _isTyping = false;

  // ===== Token Tracking =====
  int _lastPromptTokens = 0;
  int _lastCompletionTokens = 0;
  int _lastTotalTokens = 0;
  int _sessionTotalTokens = 0;

  // ===== TTS =====
  List<Map<String, String>> _voiceList = []; // [{name, locale, id}]
  Map<String, String>? _selectedVoice;       // voz activa
  double _rate = 1.0;
  double _pitch = 1.02;

  // ===== ElevenLabs =====
  bool _useElevenLabs = false; // Por defecto usar TTS nativo
  String _elevenLabsVoiceId = 'pNInz6obpgDQGcFmaJgB'; // Default: Adam
  final List<Map<String, String>> _elevenLabsVoices = [
    {'id': 'pNInz6obpgDQGcFmaJgB', 'name': 'Adam', 'desc': 'Masculino profesional'},
    {'id': 'ErXwobaYiN019PkySvjV', 'name': 'Antoni', 'desc': 'Masculino joven'},
    {'id': 'EXAVITQu4vr4xnSDxMaL', 'name': 'Bella', 'desc': 'Femenina amigable'},
    {'id': 'AZnzlk1XvdvUeBnXmlld', 'name': 'Domi', 'desc': 'Femenina fuerte'},
    {'id': 'MF3mGyEYCl7XYWbV9V6O', 'name': 'Elli', 'desc': 'Femenina calmada'},
  ];

  // ===== Control de Audio =====
  bool _isPlaying = false;
  String _currentFullMessage = ''; // Mensaje completo para mostrar en UI

  // ===== Preferencias =====
  static const _kVoiceKey = 'tts.voice.name';
  static const _kRateKey  = 'tts.rate';
  static const _kPitchKey = 'tts.pitch';
  static const _kElevenLabsVoiceKey = 'elevenlabs.voice.id';
  static const _kUseElevenLabsKey = 'tts.use.elevenlabs';

  @override
  void initState() {
    super.initState();
    _initEverything();

    // Listener para saber cuándo termina el audio
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) async {
      await _handlePlaybackFinished();
    });
  }

  @override
  void dispose() {
    _monitor?.cancel();
    _speech.stop();
    _tts.stop();
    _audioPlayer.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initEverything() async {
    // Obtener usuario actual
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;

    debugPrint('👤 Usuario actual: ${user?.email}');
    debugPrint('🆔 UserID: $_userId');

    if (_userId == null) {
      debugPrint('⚠️ No hay usuario autenticado, esperando...');
      // Esperar a que el usuario se autentique
      await Future.delayed(const Duration(seconds: 2));
      final retryUser = FirebaseAuth.instance.currentUser;
      _userId = retryUser?.uid;
      debugPrint('🔄 Reintento - UserID: $_userId');
    }

    await _loadPrefs();
    await _initTTS();
    await _initSTT();
  }

  // ----------------- PREFS -----------------
  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    _rate = sp.getDouble(_kRateKey) ?? 1.0;
    _pitch = sp.getDouble(_kPitchKey) ?? 1.02;
    _elevenLabsVoiceId = sp.getString(_kElevenLabsVoiceKey) ?? 'pNInz6obpgDQGcFmaJgB';
    _useElevenLabs = sp.getBool(_kUseElevenLabsKey) ?? false; // Por defecto TTS nativo

    // Si el valor guardado ya no existe en la lista, volver al primero disponible
    if (_elevenLabsVoices.indexWhere((v) => v['id'] == _elevenLabsVoiceId) == -1) {
      _elevenLabsVoiceId = _elevenLabsVoices.first['id']!;
      await _savePrefs();
      debugPrint('[prefs] Voz ElevenLabs invalidada, reseteada a default: $_elevenLabsVoiceId');
    }
  }

  Future<void> _savePrefs() async {
    final sp = await SharedPreferences.getInstance();
    if (_selectedVoice != null) {
      await sp.setString(_kVoiceKey, _selectedVoice!['name']!);
    }
    await sp.setDouble(_kRateKey, _rate);
    await sp.setDouble(_kPitchKey, _pitch);
    await sp.setString(_kElevenLabsVoiceKey, _elevenLabsVoiceId);
    await sp.setBool(_kUseElevenLabsKey, _useElevenLabs);
  }

  // ----------------- TTS -----------------
  Future<void> _initTTS() async {
    // Configurar listeners del TTS para saber cuándo termina
    _tts.setCompletionHandler(() {
      debugPrint('🎵 TTS completado');
      _handlePlaybackFinished();
    });

    _tts.setErrorHandler((msg) {
      debugPrint('❌ Error en TTS: $msg');
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
      _handlePlaybackFinished();
    });

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
    // Detener cualquier audio/TTS anterior primero
    await _audioPlayer.stop();
    await _tts.stop();

    // Pausar escucha mientras se reproduce para no captar la propia voz
    _wasListeningBeforePlayback = _isListening;
    if (_isListening) {
      await _stopListening();
    }

    final polished = ttsPolish(text);
    setState(() {
      _currentFullMessage = polished; // mostrar exactamente lo que se lee por TTS/ElevenLabs
    });

    debugPrint('[speak] Mensaje completo: "$text"');
    debugPrint('[speak] Mensaje limpio para TTS: "$polished"');
    debugPrint('[speak] Modo de síntesis: ${_useElevenLabs ? "ElevenLabs" : "TTS Nativo"}');

    // ===== OPCIÓN 1: TTS NATIVO (PREFERIDO POR DEFECTO) =====
    if (!_useElevenLabs) {
      try {
        debugPrint('[speak] Usando TTS nativo de alta calidad...');

        setState(() {
          _isPlaying = true;
        });

        // Configurar voz en español con mejor calidad
        if (_selectedVoice != null) {
          await _tts.setVoice({
            'name': _selectedVoice!['name']!,
            'locale': _selectedVoice!['locale']!,
          });
        }

        // Configurar parámetros optimizados para español
        await _tts.setSpeechRate(_rate);
        await _tts.setPitch(_pitch);
        await _tts.setVolume(1.0); // Volumen máximo

        // Reproducir con TTS
        await _tts.speak(polished);
        debugPrint('[speak] ✅ TTS nativo iniciado exitosamente');
        return; // Salir exitosamente
      } catch (e) {
        debugPrint('[speak] ❌ Error en TTS nativo: $e');
        setState(() {
          _isPlaying = false;
        });
        // Continuar a ElevenLabs como fallback
      }
    }

    // ===== OPCIÓN 2: ELEVENLABS (OPCIONAL) =====
    try {
      debugPrint('[speak] Intentando ElevenLabs (voz: $_elevenLabsVoiceId)...');
      final callable = functions.httpsCallable('adanSpeak');
      final res = await callable.call({
        'text': polished,
        'voiceId': _elevenLabsVoiceId
      });

      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['error'] == null && data['audioBase64'] != null) {
        final audioBase64 = data['audioBase64'] as String;
        final bytes = base64Decode(audioBase64);

        debugPrint('[speak] ElevenLabs audio recibido: ${bytes.length} bytes');

        await _audioPlayer.stop();
        await Future.delayed(const Duration(milliseconds: 150));

        setState(() {
          _isPlaying = true;
        });

        await _audioPlayer.play(BytesSource(bytes));

        debugPrint('[speak] ✅ Reproduciendo con ElevenLabs (voz: $_elevenLabsVoiceId)');
        return; // Salir exitosamente
      } else {
        final err = data['error']?.toString() ?? 'desconocido';
        final msg = data['message']?.toString() ?? 'sin detalle';
        final composed = 'ElevenLabs failed: $err ($msg)';
        debugPrint('[speak] ❌ $composed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(composed),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        throw Exception(composed);
      }
    } catch (e) {
      debugPrint('[speak] ❌ Error con ElevenLabs: $e');
    }

    // ===== FALLBACK FINAL: TTS NATIVO =====
    try {
      debugPrint('[speak] Reproduciendo con TTS nativo...');

      setState(() {
        _isPlaying = true;
      });

      // Asegurar configuración de voz
      if (_selectedVoice != null) {
        await _tts.setVoice({
          'name': _selectedVoice!['name']!,
          'locale': _selectedVoice!['locale']!,
        });
      }
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);

      // Reproducir con TTS
      await _tts.speak(polished);
      debugPrint('[speak] TTS nativo iniciado');
    } catch (e) {
      debugPrint('[speak] Error en TTS nativo: $e');
      setState(() {
        _isPlaying = false;
      });
    }

    // Si hubo error o terminó sin reproducir, retomar escucha si era necesario
    if (!_isPlaying && _wasListeningBeforePlayback && !_isListening) {
      await _startListening();
      _wasListeningBeforePlayback = false;
    }
  }

  Future<void> _handlePlaybackFinished() async {
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
    });
    _wasListeningBeforePlayback = false;
  }

  // Limpieza y formato para síntesis de voz natural

  String ttsPolish(String s) {
    var t = s.trim();

    // Eliminar formato markdown y símbolos especiales
    t = t.replaceAll('**', '');  // Negritas markdown
    t = t.replaceAll('*', '');   // Asteriscos
    t = t.replaceAll('_', '');   // Guiones bajos markdown
    t = t.replaceAll('#', '');   // Headers markdown
    t = t.replaceAll('`', '');   // Code blocks
    t = t.replaceAll('- ', '');  // Bullets
    t = t.replaceAll('• ', '');  // Bullets unicode

    // Normalizar espacios
    t = t.replaceAll(RegExp(r'\s+'), ' ');

    // Convertir emojis comunes a pausas naturales
    t = t.replaceAll(RegExp(r'[📊📁✅💡📈🎯🚀]'), ', ');

    // Pequeñas pausas por conectores comunes para tono más natural
    t = t.replaceAllMapped(
      RegExp(r'\b(además|entonces|por ejemplo|así que|por cierto|mira|bueno|pues|también)\b', caseSensitive: false),
      (Match m) => '${m.group(0)},',
    );

    // Mejorar lectura de números y porcentajes
    t = t.replaceAll('%', ' por ciento');

    // Si no termina en puntuación, añade punto
    if (!RegExp(r'[.!?…]$').hasMatch(t)) t += '.';

    return t.trim();
  }

  // ----------------- CONTROL DE AUDIO -----------------
  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    await _tts.pause();
    setState(() {
      _isPlaying = false;
    });
    debugPrint('⏸️ Audio pausado');
  }

  Future<void> _resumeAudio() async {
    await _audioPlayer.resume();
    setState(() {
      _isPlaying = true;
    });
    debugPrint('▶️ Audio reanudado');
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    await _tts.stop();
    setState(() {
      _isPlaying = false;
      _currentFullMessage = '';
    });
    _wasListeningBeforePlayback = false;
    debugPrint('⏹️ Audio detenido');
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
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
        ),
        pauseFor: const Duration(seconds: 8),
        localeId: _locale,
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

    debugPrint('🎙️ Speech result - Final: ${r.finalResult}, Text: "${r.recognizedWords}"');

    setState(() {
      _spokenText = r.recognizedWords.trim();
    });

    debugPrint('📝 Spoken text procesado: "$_spokenText" (length: ${_spokenText.length})');

    if (r.finalResult) {
      debugPrint('✅ Resultado final detectado');
      if (_spokenText.isNotEmpty) {
        debugPrint('🎯 Procesando texto: "$_spokenText"');
        _history.add('Tú: $_spokenText');
        _conversationHistory.add({'role': 'user', 'content': _spokenText});
        _replyWithAI(_spokenText);
      } else {
        debugPrint('⚠️ Texto vacío, no se procesa');
      }
    } else {
      debugPrint('⏳ Resultado parcial (esperando final)');
    }
  }

  // -------------- IA --------------
  Future<void> _replyWithAI(String text) async {
    final normalized = text.trim();
    if (normalized.isEmpty) return;

    // Evitar duplicados inmediatos (ej. STT emite doble final)
    if (_lastProcessedPrompt != null && _lastProcessedPrompt == normalized) {
      debugPrint('ℹ️ Prompt duplicado ignorado: "$normalized"');
      return;
    }
    _lastProcessedPrompt = normalized;

    try {
      // Mostrar indicador de "pensando..."
      setState(() => _history.add('ADAN: [Pensando...]'));

      debugPrint('🤖 Llamando a ADAN con userId: $_userId');
      debugPrint('📝 Texto: $text');
      debugPrint('💬 Historial: ${_conversationHistory.length} mensajes');

      final reply = await _callAdan(text);

      debugPrint('✅ ADAN respondió: $reply');

      // Remover el indicador y agregar respuesta real
      setState(() {
        _history.removeLast();
        _history.add('ADAN: $reply');
      });

      _conversationHistory.add({'role': 'assistant', 'content': reply});
      await _speak(reply);
    } catch (e, stack) {
      debugPrint('❌ Error en _replyWithAI: $e');
      debugPrint('Stack trace: $stack');

      final msg = "Lo siento, hubo un problema al consultar la IA: ${e.toString()}";
      setState(() {
        if (_history.isNotEmpty && _history.last.contains('[Pensando...]')) {
          _history.removeLast();
        }
        _history.add('ADAN: $msg');
      });
      await _speak("Lo siento, hubo un problema al consultar la IA.");
    }
  }

  Future<String> _callAdan(String text) async {
    debugPrint('📞 _callAdan iniciado');

    if (_userId == null) {
      debugPrint('❌ userId es null');
      return "Por favor, inicia sesión para que pueda ayudarte mejor.";
    }

    try {
      debugPrint('🔥 Llamando a Cloud Function adanChat...');
      final callable = functions.httpsCallable('adanChat');

      final payload = {
        'text': text,
        'userId': _userId,
        'history': _conversationHistory,
        'conversationId': _currentConversationId
      };

      debugPrint('📦 Payload: ${payload.toString().substring(0, 100)}...');

      final res = await callable.call(payload);

      debugPrint('📥 Respuesta recibida: ${res.data}');

      final data = Map<String, dynamic>.from(res.data as Map);
      final reply = (data['reply'] as String?) ?? '…';

      // Guardar conversationId para siguientes mensajes
      if (data['conversationId'] != null) {
        _currentConversationId = data['conversationId'];
        debugPrint('💾 ConversationID guardado: $_currentConversationId');
      }

      // Capturar token usage
      if (data['tokenUsage'] != null) {
        final tokenUsage = Map<String, dynamic>.from(data['tokenUsage'] as Map);
        setState(() {
          _lastPromptTokens = tokenUsage['promptTokens'] ?? 0;
          _lastCompletionTokens = tokenUsage['completionTokens'] ?? 0;
          _lastTotalTokens = tokenUsage['totalTokens'] ?? 0;
          _sessionTotalTokens += _lastTotalTokens;
        });
        debugPrint('🎯 Tokens usados: $_lastTotalTokens (Prompt: $_lastPromptTokens, Completion: $_lastCompletionTokens)');
        debugPrint('📊 Total sesión: $_sessionTotalTokens tokens');
      }

      // Detectar si se creó un proyecto
      if (data['projectCreated'] != null) {
        final project = Map<String, dynamic>.from(data['projectCreated'] as Map);
        debugPrint('🎉 Proyecto creado: ${project['nombre']} (${project['id']})');

        // Mostrar notificación al usuario
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Proyecto "${project['nombre']}" creado exitosamente'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.white,
                onPressed: () {
                  debugPrint('Navegar a proyecto: ${project['id']}');
                  // TODO: Navegar a la página del proyecto
                },
              ),
            ),
          );
        }
      }

      debugPrint('💬 Reply extraído: $reply');

      return reply;
    } catch (e, stack) {
      debugPrint('❌ Error en _callAdan: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  // =============== UI ===============
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Asistente Virtual - ADAN',
          style: TextStyle(fontSize: isSmallScreen ? 16 : 20),
        ),
        actions: [
          // Indicador de usuario
          if (_userId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.person, color: Colors.green, size: isSmallScreen ? 20 : 24),
            ),
          if (_userId == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.person_off, color: Colors.red, size: isSmallScreen ? 20 : 24),
            ),
          IconButton(
            icon: Icon(Icons.add_comment, size: isSmallScreen ? 20 : 24),
            onPressed: () {
              // Nueva conversación
              setState(() {
                _currentConversationId = null;
                _history.clear();
                _conversationHistory.clear();
                _spokenText = '';
                _lastProcessedPrompt = null;
              });
              debugPrint('🆕 Nueva conversación iniciada');
            },
            tooltip: 'Nueva conversación',
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: isSmallScreen ? 20 : 24),
            onPressed: () async {
              // Reintentar obtener usuario
              final user = FirebaseAuth.instance.currentUser;
              setState(() {
                _userId = user?.uid;
              });
              debugPrint('🔄 Usuario actualizado: $_userId');
              await _initTTS();
              if (mounted) setState(() {});
            },
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  children: [
                    // Conversacion
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Conversacion', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isSmallScreen ? 14 : 16)),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: isSmallScreen ? 20 : 24),
                          onPressed: () => setState(() => _history.clear()),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: isSmallScreen ? screenHeight * 0.6 : screenHeight * 0.65,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _history.isEmpty
                          ? const Center(child: Text('Sin mensajes aun.'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              itemCount: _history.length,
                              itemBuilder: (_, i) {
                                final msg = _history[i];
                                final isAssistant = msg.startsWith('ADAN:');
                                var display = msg;
                                final sepIndex = msg.indexOf(': ');
                                if (sepIndex != -1 && sepIndex <= 6) {
                                  display = msg.substring(sepIndex + 2);
                                }
                                final bubbleColor = isAssistant ? Colors.white : Colors.indigo.shade50;
                                final borderColor = isAssistant ? Colors.grey.shade300 : Colors.indigo.shade200;

                                return Align(
                                  alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: screenWidth * (isSmallScreen ? 0.9 : 0.7),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: bubbleColor,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Text(
                                        display,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 13 : 15,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    SizedBox(height: isSmallScreen ? 12 : 16),
            // ===== CARD PRINCIPAL: Estado de ADAN =====
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade700, Colors.indigo.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  children: [
                    // Estado de escucha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 6 : 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_off,
                            color: Colors.white,
                            size: isSmallScreen ? 22 : 28,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isListening ? 'Escuchando...' : 'En espera',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 16 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _isListening ? 'Habla claramente' : 'Toca el micrófono',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (_spokenText.isNotEmpty) ...[
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _spokenText,
                          style: TextStyle(
                            color: Colors.indigo.shade900,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ),
                    ],

                    if (_currentFullMessage.isNotEmpty) ...[
                      SizedBox(height: isSmallScreen ? 10 : 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: BoxConstraints(
                          minHeight: isSmallScreen ? 120 : 140,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.record_voice_over, color: Colors.indigo.shade700, size: isSmallScreen ? 16 : 18),
                                SizedBox(width: isSmallScreen ? 6 : 8),
                                Flexible(
                                  child: Text(
                                    'ADAN está hablando:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 11 : 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            Text(
                              _currentFullMessage,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: isSmallScreen ? 13 : 15,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Controles de audio
                      SizedBox(height: isSmallScreen ? 10 : 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: _isPlaying ? _pauseAudio : () => _speak(_currentFullMessage),
                            icon: Icon(
                              _isPlaying ? Icons.pause_circle : Icons.play_circle,
                              size: isSmallScreen ? 24 : 28,
                            ),
                            visualDensity: VisualDensity.compact,
                            constraints: BoxConstraints(
                              minWidth: isSmallScreen ? 36 : 40,
                              minHeight: isSmallScreen ? 36 : 40,
                            ),
                            color: Colors.white,
                            tooltip: _isPlaying ? 'Pausar' : 'Reproducir',
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          IconButton(
                            onPressed: _stopAudio,
                            icon: Icon(Icons.stop_circle, size: isSmallScreen ? 24 : 28),
                            visualDensity: VisualDensity.compact,
                            constraints: BoxConstraints(
                              minWidth: isSmallScreen ? 36 : 40,
                              minHeight: isSmallScreen ? 36 : 40,
                            ),
                            color: Colors.white,
                            tooltip: 'Detener',
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _currentFullMessage.isNotEmpty ? () => _speak(_currentFullMessage) : null,
                          icon: Icon(Icons.replay, size: isSmallScreen ? 14 : 16),
                          label: Text(
                            isSmallScreen ? 'Repetir' : 'Reproducir última respuesta',
                            style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                          ),
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: isSmallScreen ? 12 : 16),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      debugPrint('🧪 Prueba manual iniciada');
                      _replyWithAI('Hola ADAN, ¿cómo van mis proyectos?');
                    },
                    icon: Icon(Icons.science, size: isSmallScreen ? 16 : 18),
                    label: Text('Prueba', style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _spokenText.isNotEmpty ? () {
                      debugPrint('📤 Enviando texto capturado: "$_spokenText"');
                      _history.add('Tú: $_spokenText');
                      _conversationHistory.add({'role': 'user', 'content': _spokenText});
                      _replyWithAI(_spokenText);
                      setState(() => _spokenText = '');
                    } : null,
                    icon: Icon(Icons.send, size: isSmallScreen ? 16 : 18),
                    label: Text('Enviar', style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: isSmallScreen ? 12 : 16),

            // Opciones
            ExpansionTile(
              title: Text('Opciones', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isSmallScreen ? 14 : 16)),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8, bottom: 4),
              children: [
              // Switch para elegir entre TTS Nativo y ElevenLabs
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      _useElevenLabs ? Icons.cloud : Icons.phone_android,
                      color: Colors.indigo.shade700,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Motor de Voz',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _useElevenLabs
                                ? 'ElevenLabs (cloud, premium)'
                                : 'TTS Nativo (local, gratis)',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _useElevenLabs,
                      onChanged: (value) async {
                        setState(() {
                          _useElevenLabs = value;
                        });
                        await _savePrefs();
                        debugPrint('✅ Motor de voz cambiado a: ${value ? "ElevenLabs" : "TTS Nativo"}');
  
                        // Probar nueva configuración
                        final msg = value
                            ? 'Ahora uso ElevenLabs, voz premium en la nube.'
                            : 'Ahora uso el motor nativo de tu dispositivo.';
                        _speak(msg);
                      },
                      activeColor: Colors.indigo,
                    ),
                  ],
                ),
              ),
  
              SizedBox(height: isSmallScreen ? 8 : 12),
  
              // Selector de voz ElevenLabs (solo si está activado)
              if (_useElevenLabs)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Voz ElevenLabs:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 12 : 14)),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _elevenLabsVoices.any((v) => v['id'] == _elevenLabsVoiceId)
                        ? _elevenLabsVoiceId
                        : _elevenLabsVoices.first['id'],
                    items: _elevenLabsVoices.map((v) {
                      return DropdownMenuItem<String>(
                        value: v['id'],
                        child: Text(
                          isSmallScreen ? '${v['name']}' : '${v['name']} - ${v['desc']}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (voiceId) async {
                      if (voiceId != null) {
                        setState(() {
                          _elevenLabsVoiceId = voiceId;
                        });
                        await _savePrefs();
                        debugPrint('✅ Voz ElevenLabs cambiada a: $voiceId');
  
                        // Probar la nueva voz
                        final voiceName = _elevenLabsVoices.firstWhere((v) => v['id'] == voiceId)['name'];
                        _speak('Hola, soy $voiceName. Esta es mi voz.');
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
  
              // Selector de voz nativa (fallback)
              if (_voiceList.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Voz Nativa (Fallback):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 11 : 12)),
                    SizedBox(height: isSmallScreen ? 4 : 8),
                    DropdownButton<Map<String, String>>(
                      isExpanded: true,
                      value: _selectedVoice,
                      items: _voiceList.map((v) {
                        final show = isSmallScreen ? '${v['name']}' : '${v['name']}  (${v['locale']})';
                        return DropdownMenuItem(
                          value: v,
                          child: Text(show, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
                        );
                      }).toList(),
                      onChanged: (v) async {
                        _selectedVoice = v;
                        await _applyVoiceAndParams();
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
  
              SizedBox(height: isSmallScreen ? 8 : 12),
  
              // sliders
              if (!isSmallScreen)
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
  
              // Sliders apilados para móvil
              if (isSmallScreen) ...[
                Row(
                  children: [
                    Text('Velocidad', style: TextStyle(fontSize: 12)),
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
                    Text(_rate.toStringAsFixed(1), style: TextStyle(fontSize: 11)),
                  ],
                ),
                Row(
                  children: [
                    Text('Tono', style: TextStyle(fontSize: 12)),
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
                    Text(_pitch.toStringAsFixed(1), style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
  
              SizedBox(height: isSmallScreen ? 12 : 16),
  
              // ===== Token Usage Display =====
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_outlined, size: isSmallScreen ? 16 : 18, color: Colors.blue.shade700),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Flexible(
                          child: Text(
                            isSmallScreen ? 'Tokens (GPT-4o-mini)' : 'Uso de Tokens (GPT-4o-mini)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade900,
                              fontSize: isSmallScreen ? 12 : 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    if (_lastTotalTokens > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Último mensaje:', style: TextStyle(fontSize: isSmallScreen ? 11 : 12, fontWeight: FontWeight.w600)),
                          Text(
                            '$_lastTotalTokens tokens',
                            style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 3 : 4),
                      if (!isSmallScreen)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('  • Prompt: $_lastPromptTokens', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('Completion: $_lastCompletionTokens', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      if (isSmallScreen)
                        Text('  Prompt: $_lastPromptTokens | Comp: $_lastCompletionTokens', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      const Divider(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total sesión:', style: TextStyle(fontSize: isSmallScreen ? 11 : 12, fontWeight: FontWeight.w700)),
                        Text(
                          '$_sessionTotalTokens tokens',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 3 : 4),
                    Text(
                      'Costo aprox: \$${(_sessionTotalTokens * 0.00015 / 1000).toStringAsFixed(4)} USD',
                      style: TextStyle(fontSize: isSmallScreen ? 9 : 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
  
              ],
            ),

                  ],
                ),
              ),
            ),

            // ===== CAMPO DE TEXTO PARA ESCRIBIR =====
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              child: Row(
                children: [
                  // Botón de micrófono
                  IconButton(
                    onPressed: _isListening ? _stopListening : _startListening,
                    icon: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      color: _isListening ? Colors.red : Colors.indigo,
                    ),
                    tooltip: _isListening ? 'Detener dictado' : 'Dictar mensaje',
                  ),

                  // Campo de texto
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _textFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Escribe tu mensaje a ADAN...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Colors.indigo, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 20,
                          vertical: isSmallScreen ? 10 : 12,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onChanged: (text) {
                        setState(() {
                          _isTyping = text.isNotEmpty;
                        });
                      },
                      onSubmitted: (text) {
                        if (text.trim().isNotEmpty) {
                          _sendTextMessage(text.trim());
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Botón de enviar
                  Container(
                    decoration: BoxDecoration(
                      color: _isTyping ? Colors.indigo : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isTyping
                          ? () {
                              final text = _textController.text.trim();
                              if (text.isNotEmpty) {
                                _sendTextMessage(text);
                              }
                            }
                          : null,
                      icon: Icon(
                        Icons.send,
                        color: _isTyping ? Colors.white : Colors.grey.shade500,
                      ),
                      tooltip: 'Enviar mensaje',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Envía un mensaje de texto escrito por el usuario
  void _sendTextMessage(String text) {
    debugPrint('📤 Enviando mensaje escrito: "$text"');

    // Agregar al historial
    _history.add('Tú: $text');
    _conversationHistory.add({'role': 'user', 'content': text});

    // Limpiar campo de texto
    _textController.clear();
    setState(() {
      _isTyping = false;
    });

    // Enviar a la IA
    _replyWithAI(text);

    // Quitar foco del teclado
    _textFocusNode.unfocus();
  }
}


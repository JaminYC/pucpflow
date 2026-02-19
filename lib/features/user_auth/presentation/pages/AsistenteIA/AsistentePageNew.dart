import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
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
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pucpflow/services/wake_word_service.dart';
import 'package:pucpflow/utils/file_bytes_loader.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/pmi_ia_service_web.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/pmi_service.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ProyectoDetalleKanbanPage.dart';

/// Voice Console - Interfaz Profesional para ADAN
/// Estados visuales claros y panel de control premium

final FlutterTts _tts = FlutterTts();
final FirebaseFunctions functions =
    FirebaseFunctions.instanceFor(app: Firebase.app(), region: 'us-central1');

// Enum para estados del asistente
enum AssistantState {
  inactive,      // ⚪ Inactivo
  listening,     // 🟡 Escuchando / esperando comando
  recording,     // 🔴 Grabando voz
  processing,    // 🔵 Procesando / pensando
  speaking,      // 🟣 Hablando / reproduciendo voz
}

class _LocalAttachment {
  final String name;
  final String? extension;
  final Uint8List bytes;

  const _LocalAttachment({
    required this.name,
    required this.bytes,
    this.extension,
  });

  int get size => bytes.length;
}

class AsistentePageNew extends StatefulWidget {
  const AsistentePageNew({super.key});

  @override
  State<AsistentePageNew> createState() => _AsistentePageNewState();
}

class _AsistentePageNewState extends State<AsistentePageNew> with SingleTickerProviderStateMixin {
  // ===== ESTADO DEL ASISTENTE =====
  AssistantState _currentState = AssistantState.inactive;

  // ===== STT =====
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  String _locale = 'es_ES';
  String _spokenText = '';
  String _transcribedText = ''; // Texto en tiempo real mientras habla
  Timer? _monitor;

  // ===== Wake Word =====
  final WakeWordService _wakeWordService = WakeWordService();
  StreamSubscription<void>? _wakeWordSubscription;
  bool _isWakeWordEnabled = false;
  bool get _wakeWordSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // ===== UI / Conversación =====
  final List<Map<String, dynamic>> _messages = []; // {role: 'user/assistant', content: '', timestamp: DateTime}
  final List<Map<String, String>> _conversationHistory = [];
  String? _lastProcessedPrompt;
  String? _userId;
  String? _currentConversationId;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _processingAudioPlayer = AudioPlayer(); // Para sonido de procesamiento
  bool _isAudioPaused = false; // Para control de pausa/play
  String _lastAudioResponse = ''; // Para repetir última respuesta

  // ===== Animación =====
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ===== Token Tracking =====
  int _lastPromptTokens = 0;
  int _lastCompletionTokens = 0;
  int _lastTotalTokens = 0;
  int _sessionTotalTokens = 0;

  // ===== TTS =====
  List<Map<String, String>> _voiceList = [];
  Map<String, String>? _selectedVoice;
  double _rate = 1.0;
  double _pitch = 1.02;

  // ===== ElevenLabs =====
  String _elevenLabsVoiceId = 'pNInz6obpgDQGcFmaJgB';
  final List<Map<String, String>> _elevenLabsVoices = [
    {'id': 'pNInz6obpgDQGcFmaJgB', 'name': 'Adam', 'desc': 'Masculino profesional'},
    {'id': 'ErXwobaYiN019PkySvjV', 'name': 'Antoni', 'desc': 'Masculino joven'},
    {'id': 'EXAVITQu4vr4xnSDxMaL', 'name': 'Bella', 'desc': 'Femenina amigable'},
    {'id': 'AZnzlk1XvdvUeBnXmlld', 'name': 'Domi', 'desc': 'Femenina fuerte'},
    {'id': 'MF3mGyEYCl7XYWbV9V6O', 'name': 'Elli', 'desc': 'Femenina calmada'},
  ];

  // ===== Panel lateral =====
  bool _showHistory = false;
  bool _showSettings = false;
  bool _showDevMode = false;

  // ===== Respuesta actual =====
  String _currentResponse = '';

  // ===== Historial de conversaciones =====
  List<Map<String, dynamic>> _savedConversations = [];
  bool _loadingHistory = false;

  // ===== Input de texto =====
  final TextEditingController _textInputController = TextEditingController();
  final List<_LocalAttachment> _attachedFiles = [];
  static const int _maxAttachmentCount = 4;
  static const int _maxAttachmentBytes = 2 * 1024 * 1024;
  static const int _maxTotalAttachmentBytes = 6 * 1024 * 1024;

  // ===== Servicio PMI =====
  final PMIIAServiceWeb _pmiIAService = PMIIAServiceWeb();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initEverything();
    _initWakeWord();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          if (state == PlayerState.playing) {
            _currentState = AssistantState.speaking;
          }
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) async {
      setState(() => _currentState = AssistantState.inactive);
    });
  }

  @override
  void dispose() {
    _monitor?.cancel();
    _wakeWordSubscription?.cancel();
    _speech.stop();
    _tts.stop();
    _audioPlayer.dispose();
    _processingAudioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ===== INIT =====
  Future<void> _initEverything() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() => _userId = user?.uid);

    _speechEnabled = await _speech.initialize(
      onStatus: (status) => debugPrint('🎙️ STT Status: $status'),
      onError: (err) => debugPrint('❌ STT Error: $err'),
    );

    if (!_speechEnabled) {
      debugPrint('❌ No se pudo inicializar el reconocimiento de voz');
    }

    await _initTTS();
    await _loadConversationHistory(); // Cargar historial al inicio
    if (mounted) setState(() {});
  }

  Future<void> _initWakeWord() async {
    if (!_wakeWordSupported) return;

    await _wakeWordService.initialize();
    _isWakeWordEnabled = _wakeWordService.isBackgroundEnabled;
    if (_isWakeWordEnabled) {
      await _wakeWordService.startBackgroundService();
    }

    _wakeWordSubscription = _wakeWordService.wakeWordStream.listen((_) {
      if (!_isWakeWordEnabled) return;
      debugPrint('Wake word detected, starting voice capture');
      if (!mounted) return;
      if (_currentState == AssistantState.listening ||
          _currentState == AssistantState.recording ||
          _currentState == AssistantState.processing ||
          _currentState == AssistantState.speaking) {
        return;
      }
      _startListening();
    });

    if (mounted) setState(() {});
  }

  Future<void> _loadConversationHistory() async {
    if (_userId == null) return;

    setState(() => _loadingHistory = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('adan_conversations')
          .orderBy('lastMessageAt', descending: true)
          .limit(20)
          .get();

      setState(() {
        _savedConversations = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Sin título',
            'lastMessageAt': (data['lastMessageAt'] as Timestamp?)?.toDate(),
            'messageCount': data['messageCount'] ?? 0,
          };
        }).toList();
        _loadingHistory = false;
      });

      debugPrint('✅ Historial cargado: ${_savedConversations.length} conversaciones');
    } catch (e) {
      debugPrint('❌ Error cargando historial: $e');
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _loadConversation(String conversationId) async {
    if (_userId == null) return;

    try {
      // Cargar mensajes de la conversación
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('adan_conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      setState(() {
        _currentConversationId = conversationId;
        _messages.clear();
        _conversationHistory.clear();

        for (var doc in messagesSnapshot.docs) {
          final data = doc.data();
          final role = data['role'] ?? 'user';
          final content = data['content'] ?? '';
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

          _messages.add({
            'role': role,
            'content': content,
            'timestamp': timestamp,
          });

          _conversationHistory.add({
            'role': role,
            'content': content,
          });
        }
      });

      debugPrint('✅ Conversación cargada: $conversationId (${_messages.length} mensajes)');
    } catch (e) {
      debugPrint('❌ Error cargando conversación: $e');
    }
  }

  Future<void> _startNewConversation() async {
    setState(() {
      _currentConversationId = null;
      _messages.clear();
      _conversationHistory.clear();
      _currentResponse = '';
      _spokenText = '';
      _transcribedText = '';
    });
    debugPrint('🆕 Nueva conversación iniciada');
  }

  Future<void> _deleteConversation(String conversationId, String title) async {
    if (_userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1229),
        title: const Text(
          '¿Eliminar conversación?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "$title"?\nEsta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.2),
            ),
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Eliminar la conversación de Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('adan_conversations')
          .doc(conversationId)
          .delete();

      // Si era la conversación activa, limpiar
      if (_currentConversationId == conversationId) {
        await _startNewConversation();
      }

      // Recargar historial
      await _loadConversationHistory();

      debugPrint('✅ Conversación eliminada: $conversationId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversación eliminada'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error eliminando conversación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar la conversación'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _renameConversation(String conversationId, String currentTitle) async {
    if (_userId == null) return;

    final controller = TextEditingController(text: currentTitle);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1229),
        title: const Text(
          'Renombrar conversación',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nuevo título',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6366F1)),
            ),
          ),
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
            ),
            child: const Text('Guardar', style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );

    if (newTitle == null || newTitle.isEmpty || newTitle == currentTitle) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('adan_conversations')
          .doc(conversationId)
          .update({'title': newTitle});

      await _loadConversationHistory();

      debugPrint('✅ Conversación renombrada: $newTitle');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversación renombrada'),
            backgroundColor: Color(0xFF6366F1),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error renombrando conversación: $e');
    }
  }

  Future<void> _initTTS() async {
    final prefs = await SharedPreferences.getInstance();
    final storedRate = prefs.getDouble('tts.rate');
    _rate = storedRate ?? 0.7; // Velocidad más lenta y pausada (antes 0.85)
    if (storedRate == null || storedRate < 0.5 || storedRate > 1.5) {
      _rate = 0.7;
      await prefs.setDouble('tts.rate', _rate);
    }
    _pitch = prefs.getDouble('tts.pitch') ?? 1.0; // Tono natural sin modificación (antes 1.05)
    _elevenLabsVoiceId = prefs.getString('elevenlabs.voice.id') ?? 'pNInz6obpgDQGcFmaJgB';

    // Configuración mejorada de TTS local
    await _tts.setLanguage('es-ES'); // Español de España (más claro)
    await _tts.setSpeechRate(_rate); // Velocidad más natural
    await _tts.setPitch(_pitch); // Tono ligeramente más alto (más agradable)
    await _tts.setVolume(1.0); // Volumen máximo

    // Intentar seleccionar la mejor voz en español disponible
    final voices = await _tts.getVoices as List<dynamic>?;
    if (voices != null && voices.isNotEmpty) {
      _voiceList = voices.map((v) => {
        'name': v['name'].toString(),
        'locale': v['locale'].toString(),
        'id': v['name'].toString(),
      }).toList();

      // Buscar voces en español de alta calidad (orden de preferencia)
      final preferredVoiceNames = [
        'es-ES-Standard-A', // Google TTS español (mujer)
        'es-ES-Standard-B', // Google TTS español (hombre)
        'es-MX-Standard-A', // Google TTS mexicano
        'Karen', // iOS español
        'Monica', // Windows español
        'Paulina', // macOS español
        'Jorge', // macOS español hombre
      ];

      final savedName = prefs.getString('tts.voice.name');

      if (savedName != null) {
        // Usar voz guardada
        _selectedVoice = _voiceList.firstWhere(
          (v) => v['name'] == savedName,
          orElse: () => _voiceList.first,
        );
      } else {
        // Buscar mejor voz disponible
        for (final prefName in preferredVoiceNames) {
          final found = _voiceList.where((v) =>
            v['name']!.contains(prefName) ||
            (v['locale']!.startsWith('es-') && v['name']!.contains('Standard'))
          ).toList();

          if (found.isNotEmpty) {
            _selectedVoice = found.first;
            break;
          }
        }

        // Si no encuentra ninguna preferida, usar la primera en español
        if (_selectedVoice == null) {
          _selectedVoice = _voiceList.firstWhere(
            (v) => v['locale']!.startsWith('es-'),
            orElse: () => _voiceList.first,
          );
        }
      }

      if (_selectedVoice != null) {
        await _tts.setVoice({'name': _selectedVoice!['name']!, 'locale': _selectedVoice!['locale']!});
        debugPrint('✅ Voz TTS seleccionada: ${_selectedVoice!['name']} (${_selectedVoice!['locale']})');
      }
    }
  }

  Future<void> _pauseWakeWordDetectionIfNeeded() async {
    if (!_wakeWordSupported || !_isWakeWordEnabled) return;
    await _wakeWordService.stopDetection();
  }

  Future<void> _resumeWakeWordDetectionIfNeeded() async {
    if (!_wakeWordSupported || !_isWakeWordEnabled) return;
    await _wakeWordService.startListening();
  }

  void _setWakeWordProcessing(bool isProcessing) {
    if (!_wakeWordSupported || !_isWakeWordEnabled) return;
    _wakeWordService.setProcessing(isProcessing);
  }

  void _setWakeWordSpeaking(bool isSpeaking) {
    if (!_wakeWordSupported || !_isWakeWordEnabled) return;
    _wakeWordService.setADANSpeaking(isSpeaking);
  }

  // ===== CONTROL DE VOZ =====
  void _startListening() async {
    if (!_speechEnabled) return;
    await _pauseWakeWordDetectionIfNeeded();

    setState(() {
      _currentState = AssistantState.listening;
      _spokenText = '';
      _transcribedText = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _transcribedText = result.recognizedWords;
          if (result.finalResult) {
            _spokenText = result.recognizedWords;
            _currentState = AssistantState.recording;
          }
        });
      },
      localeId: _locale,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.dictation,
    );

    // Monitor para auto-procesar
    _monitor?.cancel();
    _monitor = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_speech.isListening && _spokenText.isNotEmpty) {
        _monitor?.cancel();
        _processVoiceInput();
      }
    });
  }

  void _stopListening() async {
    await _speech.stop();
    _monitor?.cancel();

    if (_spokenText.isNotEmpty) {
      _processVoiceInput();
    } else {
      setState(() => _currentState = AssistantState.inactive);
      await _resumeWakeWordDetectionIfNeeded();
    }
  }

  // ===== PROCESAMIENTO =====

  // Generar sonido suave de procesamiento (como Gemini)
  Future<void> _playProcessingSound() async {
    try {
      final processingTone = _generateSmoothProcessingTone();
      await _processingAudioPlayer.play(BytesSource(processingTone));
    } catch (e) {
      debugPrint('⚠️ No se pudo reproducir sonido de procesamiento: $e');
    }
  }

  // Generar tono suave que sube y baja gradualmente (efecto "swoosh")
  Uint8List _generateSmoothProcessingTone() {
    final sampleRate = 44100;
    final duration = 0.4; // 400ms - corto y agradable
    final numSamples = (sampleRate * duration).toInt();
    final bytes = <int>[];

    // Encabezado WAV
    final byteRate = sampleRate * 2;
    final dataSize = numSamples * 2;
    final fileSize = 36 + dataSize;

    bytes.addAll('RIFF'.codeUnits);
    bytes.addAll(_int32ToBytes(fileSize));
    bytes.addAll('WAVE'.codeUnits);
    bytes.addAll('fmt '.codeUnits);
    bytes.addAll(_int32ToBytes(16));
    bytes.addAll(_int16ToBytes(1));
    bytes.addAll(_int16ToBytes(1));
    bytes.addAll(_int32ToBytes(sampleRate));
    bytes.addAll(_int32ToBytes(byteRate));
    bytes.addAll(_int16ToBytes(2));
    bytes.addAll(_int16ToBytes(16));
    bytes.addAll('data'.codeUnits);
    bytes.addAll(_int32ToBytes(dataSize));

    // Generar tono que sube y baja suavemente (600Hz -> 900Hz -> 600Hz)
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final progress = i / numSamples;

      // Frecuencia que sube y luego baja (curva suave)
      final freqModulation = sin(progress * pi);
      final frequency = 600 + (300 * freqModulation);

      // Envolvente suave (fade in/out)
      final envelope = sin(progress * pi);

      // Volumen bajo y agradable (15% del máximo)
      final amplitude = 32767 * 0.15 * envelope;

      final sample = (sin(2 * pi * frequency * t) * amplitude).toInt();
      bytes.addAll(_int16ToBytes(sample));
    }

    return Uint8List.fromList(bytes);
  }

  List<int> _int16ToBytes(int value) {
    return [value & 0xFF, (value >> 8) & 0xFF];
  }

  List<int> _int32ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  Future<void> _processVoiceInput() async {
    if (_spokenText.isEmpty || _spokenText == _lastProcessedPrompt) {
      setState(() => _currentState = AssistantState.inactive);
      await _resumeWakeWordDetectionIfNeeded();
      return;
    }

    final attachmentsPayload = await _buildAttachmentPayload();
    _lastProcessedPrompt = _spokenText;

    await _pauseWakeWordDetectionIfNeeded();
    _setWakeWordProcessing(true);

    setState(() {
      _attachedFiles.clear();
      _currentState = AssistantState.processing;
      _messages.add({
        'role': 'user',
        'content': _spokenText,
        'timestamp': DateTime.now(),
      });
    });

    // Reproducir sonido suave de procesamiento
    _playProcessingSound();

    _conversationHistory.add({'role': 'user', 'content': _spokenText});

    try {
      final callable = functions.httpsCallable('adanChat');
      final payload = <String, dynamic>{
        'text': _spokenText,
        'userId': _userId,
        'history': _conversationHistory,
        'conversationId': _currentConversationId,
      };
      if (attachmentsPayload.isNotEmpty) {
        payload['attachments'] = attachmentsPayload;
      }
      final result = await callable.call(payload);

      final data = result.data;
      final reply = data['reply'] ?? 'No obtuve respuesta.';

      if (data['tokenUsage'] != null) {
        final tokens = data['tokenUsage'];
        _lastPromptTokens = tokens['promptTokens'] ?? 0;
        _lastCompletionTokens = tokens['completionTokens'] ?? 0;
        _lastTotalTokens = tokens['totalTokens'] ?? 0;
        _sessionTotalTokens += _lastTotalTokens;
      }

      if (data['conversationId'] != null) {
        _currentConversationId = data['conversationId'];
      }

      _conversationHistory.add({'role': 'assistant', 'content': reply});

      setState(() {
        _currentResponse = reply;
        _messages.add({
          'role': 'assistant',
          'content': reply,
          'timestamp': DateTime.now(),
        });
      });

      await _speakResponse(reply);

    } catch (e) {
      debugPrint('❌ Error al procesar: $e');
      setState(() {
        _currentState = AssistantState.inactive;
        _messages.add({
          'role': 'error',
          'content': 'Error: $e',
          'timestamp': DateTime.now(),
        });
      });
    } finally {
      _setWakeWordProcessing(false);
      await _resumeWakeWordDetectionIfNeeded();
    }
  }

  // Controles de audio
  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    setState(() => _isAudioPaused = true);
  }

  Future<void> _resumeAudio() async {
    await _audioPlayer.resume();
    setState(() => _isAudioPaused = false);
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _currentState = AssistantState.inactive;
      _isAudioPaused = false;
    });
  }

  Future<void> _repeatLastResponse() async {
    if (_lastAudioResponse.isNotEmpty) {
      await _speakResponse(_lastAudioResponse);
    }
  }

  /// Eliminar formato Markdown del texto para TTS
  /// Convierte Markdown a texto plano que suena natural
  String _stripMarkdown(String text) {
    String cleaned = text;

    // Eliminar headers (# ## ###)
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

    // Eliminar bold/italic (**text** o __text__ o *text* o _text_)
    cleaned = cleaned.replaceAllMapped(RegExp(r'\*\*([^\*]+)\*\*'), (match) => match.group(1) ?? '');
    cleaned = cleaned.replaceAllMapped(RegExp(r'__([^_]+)__'), (match) => match.group(1) ?? '');
    cleaned = cleaned.replaceAllMapped(RegExp(r'\*([^\*]+)\*'), (match) => match.group(1) ?? '');
    cleaned = cleaned.replaceAllMapped(RegExp(r'_([^_]+)_'), (match) => match.group(1) ?? '');

    // Eliminar code blocks (```code```)
    cleaned = cleaned.replaceAll(RegExp(r'```[^`]*```'), ' código ');

    // Eliminar inline code (`code`)
    cleaned = cleaned.replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match.group(1) ?? '');

    // Eliminar links [text](url) -> solo text
    cleaned = cleaned.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (match) => match.group(1) ?? '');

    // Eliminar bullets/listas (-, *, +)
    cleaned = cleaned.replaceAll(RegExp(r'^[\-\*\+]\s+', multiLine: true), '');

    // Eliminar blockquotes (>)
    cleaned = cleaned.replaceAll(RegExp(r'^>\s+', multiLine: true), '');

    // Limpiar múltiples espacios/saltos de línea
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ');

    return cleaned.trim();
  }

  Future<void> _speakResponse(String text) async {
    setState(() => _currentState = AssistantState.speaking);
    _lastAudioResponse = text; // Guardar para repetir
    await _pauseWakeWordDetectionIfNeeded();
    _setWakeWordSpeaking(true);

    // 🔇 ELEVENLABS DESACTIVADO (sin créditos)
    // Usando TTS local optimizado directamente
    debugPrint('🎵 Reproduciendo con TTS local optimizado');

    try {
      // Limpiar Markdown antes de hablar
      final cleanText = _stripMarkdown(text);
      debugPrint('🔊 TTS texto limpio: ${cleanText.substring(0, cleanText.length > 100 ? 100 : cleanText.length)}...');
      await _tts.speak(cleanText);
      setState(() => _currentState = AssistantState.inactive);
    } catch (e) {
      debugPrint('❌ Error en TTS local: $e');
      setState(() => _currentState = AssistantState.inactive);
    }

    _setWakeWordSpeaking(false);
    await _resumeWakeWordDetectionIfNeeded();

    /*
    // ========================================
    // CÓDIGO ELEVENLABS COMENTADO (reactivar cuando haya créditos)
    // ========================================
    try {
      // Intentar ElevenLabs primero
      final callable = functions.httpsCallable('adanSpeak');
      final result = await callable.call({
        'text': text,
        'voiceId': _elevenLabsVoiceId,
      });

      // Verificar si hay error de cuota
      if (result.data != null && result.data['error'] != null) {
        final errorMessage = result.data['message'] ?? '';

        if (errorMessage == 'quota_exceeded') {
          debugPrint('⚠️ Cuota de ElevenLabs excedida');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Cuota de ElevenLabs excedida. Usando voz local temporalmente.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
          // Usar TTS local
          final cleanText = _stripMarkdown(text);
          await _tts.speak(cleanText);
          setState(() => _currentState = AssistantState.inactive);
          return;
        }
      }

      if (result.data != null && result.data['audioBase64'] != null) {
        final audioBase64 = result.data['audioBase64'];

        // Convertir base64 a bytes
        final bytes = base64Decode(audioBase64);

        // Detener y resetear completamente el reproductor
        await _audioPlayer.stop();
        await _audioPlayer.release();

        // Pequeña pausa para asegurar que el reproductor está limpio
        await Future.delayed(const Duration(milliseconds: 50));

        // Reproducir usando BytesSource (funciona en web y móvil)
        await _audioPlayer.play(BytesSource(bytes));

        debugPrint('🎵 Reproduciendo audio de ElevenLabs (${bytes.length} bytes)');

        return;
      }
    } catch (e) {
      debugPrint('⚠️ ElevenLabs falló, usando TTS local: $e');
    }

    // Fallback a TTS local
    final cleanText = _stripMarkdown(text);
    await _tts.speak(cleanText);
    setState(() => _currentState = AssistantState.inactive);
    */
  }

  // ===== UI BUILD =====
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Row(
          children: [
            // Panel lateral izquierdo (historial)
            if (!isMobile && _showHistory) _buildHistoryPanel(),

            // Contenido principal
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(isMobile),
                  Expanded(
                    child: Stack(
                      children: [
                        _buildMainConsole(isMobile),
                        if (_showSettings) _buildSettingsOverlay(isMobile),
                        if (isMobile && _showHistory) _buildHistoryOverlay(isMobile),
                      ],
                    ),
                  ),
                  if (_showDevMode) _buildDevModeBar(isMobile),
                ],
              ),
            ),

            // Panel lateral derecho (configuración)
            if (!isMobile && _showSettings) _buildSettingsPanel(),
          ],
        ),
      ),
    );
  }

  // ===== TOP BAR =====
  Widget _buildTopBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1229),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo/Título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              if (!isMobile) ...[
                const Text(
                  'ADAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Color(0xFF10B981), width: 1),
                  ),
                  child: const Text(
                    'VOICE AI',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const Spacer(),

          // Estado del usuario
          if (_userId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF10B981), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (!isMobile)
                    const Text(
                      'Conectado',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Botones de acción
          // Botón Generar Proyecto
          if (_messages.isNotEmpty) ...[
            _buildActionButton(
              icon: Icons.auto_awesome,
              label: isMobile ? '' : 'Generar Proyecto',
              onPressed: _generarProyectoDesdeConversacion,
              tooltip: 'Generar proyecto desde conversación',
            ),
            const SizedBox(width: 8),
          ],
          _buildIconButton(
            Icons.history,
            _showHistory,
            () => setState(() => _showHistory = !_showHistory),
            'Historial',
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            Icons.settings,
            _showSettings,
            () => setState(() => _showSettings = !_showSettings),
            'Configuración',
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            Icons.code,
            _showDevMode,
            () => setState(() => _showDevMode = !_showDevMode),
            'Modo Dev',
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, bool isActive, VoidCallback onPressed, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? Color(0xFF6366F1).withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive ? Border.all(color: Color(0xFF6366F1), width: 1) : null,
            ),
            child: Icon(
              icon,
              color: isActive ? Color(0xFF6366F1) : Colors.white.withOpacity(0.6),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== CONSOLE PRINCIPAL =====
  Widget _buildMainConsole(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      child: Column(
        children: [
          // Conversacion (scroll grande)
          Expanded(
            child: _buildConversationDisplay(isMobile),
          ),
          SizedBox(height: isMobile ? 8 : 12),

          // Controles de Audio (Pause/Play, Stop, Repetir)
          if (_currentState == AssistantState.speaking || _lastAudioResponse.isNotEmpty)
            _buildAudioControls(isMobile),

          SizedBox(height: isMobile ? 8 : 12),

          // Barra de texto tipo ChatGPT
          _buildTextInput(isMobile),
        ],
      ),
    );
  }

  // ===== INDICADOR DE ESTADO =====
  Widget _buildStateIndicator(bool isMobile) {
    String stateText;
    String stateSubtext;
    Color stateColor;
    IconData stateIcon;

    switch (_currentState) {
      case AssistantState.inactive:
        stateText = 'Inactivo';
        stateSubtext = 'Toca el micrófono para comenzar';
        stateColor = const Color(0xFF6B7280);
        stateIcon = Icons.mic_off;
        break;
      case AssistantState.listening:
        stateText = 'Escuchando';
        stateSubtext = 'Esperando tu comando...';
        stateColor = const Color(0xFFFBBF24);
        stateIcon = Icons.hearing;
        break;
      case AssistantState.recording:
        stateText = 'Grabando';
        stateSubtext = 'Capturando tu voz';
        stateColor = const Color(0xFFEF4444);
        stateIcon = Icons.mic;
        break;
      case AssistantState.processing:
        stateText = 'Procesando';
        stateSubtext = 'Analizando tu solicitud...';
        stateColor = const Color(0xFF3B82F6);
        stateIcon = Icons.psychology;
        break;
      case AssistantState.speaking:
        stateText = 'Hablando';
        stateSubtext = 'Reproduciendo respuesta';
        stateColor = const Color(0xFF8B5CF6);
        stateIcon = Icons.volume_up;
        break;
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1229),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stateColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Icono animado
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final shouldPulse = _currentState != AssistantState.inactive;
              return Transform.scale(
                scale: shouldPulse ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: stateColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: stateColor, width: 2),
                  ),
                  child: Icon(
                    stateIcon,
                    color: stateColor,
                    size: isMobile ? 18 : 22,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 16),

          // Texto del estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stateText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 15 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stateSubtext,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: isMobile ? 10 : 11,
                  ),
                ),
              ],
            ),
          ),

          // Ondas de audio (decorativo)
          if (_currentState == AssistantState.recording || _currentState == AssistantState.speaking)
            _buildAudioWaves(stateColor),
        ],
      ),
    );
  }

  // ===== ONDAS DE AUDIO =====
  Widget _buildAudioWaves(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: 20 + (10 * _pulseAnimation.value) * (index % 2 == 0 ? 1 : -1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }

  // ===== BOTÓN DE MICRÓFONO =====
  // ===== CONTROLES DE AUDIO =====
  Widget _buildAudioControls(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón Pause/Play
        if (_currentState == AssistantState.speaking)
          _buildControlButton(
            icon: _isAudioPaused ? Icons.play_arrow : Icons.pause,
            label: _isAudioPaused ? 'Reanudar' : 'Pausar',
            color: const Color(0xFF8B5CF6),
            onTap: _isAudioPaused ? _resumeAudio : _pauseAudio,
            isMobile: isMobile,
          ),

        if (_currentState == AssistantState.speaking)
          SizedBox(width: isMobile ? 12 : 16),

        // Botón Stop
        if (_currentState == AssistantState.speaking)
          _buildControlButton(
            icon: Icons.stop,
            label: 'Detener',
            color: const Color(0xFFEF4444),
            onTap: _stopAudio,
            isMobile: isMobile,
          ),

        if (_currentState == AssistantState.speaking)
          SizedBox(width: isMobile ? 12 : 16),

        // Botón Repetir (siempre visible si hay última respuesta)
        if (_lastAudioResponse.isNotEmpty)
          _buildControlButton(
            icon: Icons.replay,
            label: 'Repetir',
            color: const Color(0xFF3B82F6),
            onTap: _repeatLastResponse,
            isMobile: isMobile,
          ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: isMobile ? 18 : 20),
            SizedBox(width: isMobile ? 4 : 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton(bool isMobile) {
    final isActive = _currentState == AssistantState.listening ||
                     _currentState == AssistantState.recording;

    return GestureDetector(
      onTap: isActive ? _stopListening : _startListening,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isActive ? _pulseAnimation.value * 0.9 + 0.1 : 1.0,
            child: Container(
              width: isMobile ? 68 : 84,
              height: isMobile ? 68 : 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isActive
                      ? [Color(0xFFEF4444), Color(0xFFF97316)]
                      : [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isActive ? Color(0xFFEF4444) : Color(0xFF6366F1))
                        .withOpacity(0.5),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isActive ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: isMobile ? 24 : 32,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final newAttachments = <_LocalAttachment>[];
      final warnings = <String>[];
      int totalBytes = _attachedFiles.fold(0, (sum, file) => sum + file.size);

      for (final file in result.files) {
        if (_attachedFiles.length + newAttachments.length >= _maxAttachmentCount) {
          warnings.add('Solo se pueden adjuntar $_maxAttachmentCount archivos.');
          break;
        }

        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await loadFileBytes(file.path!);
        }

        if (bytes == null || bytes.isEmpty) {
          warnings.add('No se pudo leer ${file.name}.');
          continue;
        }

        if (bytes.length > _maxAttachmentBytes) {
          warnings.add('${file.name} supera el limite de 2MB.');
          continue;
        }

        if (totalBytes + bytes.length > _maxTotalAttachmentBytes) {
          warnings.add('El total de adjuntos supera 6MB.');
          continue;
        }

        newAttachments.add(
          _LocalAttachment(
            name: file.name,
            extension: file.extension,
            bytes: bytes,
          ),
        );
        totalBytes += bytes.length;
      }

      if (newAttachments.isNotEmpty) {
        setState(() {
          _attachedFiles.addAll(newAttachments);
        });
      }

      if (warnings.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(warnings.join(' ')),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al adjuntar archivos: $e');
    }
  }

  void _removeAttachment(int index) {
    if (index < 0 || index >= _attachedFiles.length) return;
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  String _guessMimeType(String name, String? extension) {
    final ext = (extension ?? name.split('.').last).toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'md':
      case 'markdown':
        return 'text/markdown';
      case 'json':
        return 'application/json';
      case 'csv':
        return 'text/csv';
      case 'xml':
        return 'text/xml';
      case 'yml':
      case 'yaml':
        return 'text/yaml';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  Future<List<Map<String, dynamic>>> _buildAttachmentPayload() async {
    if (_attachedFiles.isEmpty) return [];
    final payload = <Map<String, dynamic>>[];
    final files = _attachedFiles.take(_maxAttachmentCount).toList();

    for (final file in files) {
      final bytes = file.bytes;
      if (bytes.isEmpty) {
        continue;
      }
      payload.add({
        'name': file.name,
        'extension': file.extension,
        'mimeType': _guessMimeType(file.name, file.extension),
        'size': bytes.length,
        'dataBase64': base64Encode(bytes),
      });
    }
    return payload;
  }

  // ===== INPUT DE TEXTO =====
  Widget _buildTextInput(bool isMobile) {
    final isListening = _currentState == AssistantState.listening ||
        _currentState == AssistantState.recording;

    return Container(
      constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 760),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_attachedFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_attachedFiles.length, (index) {
                  final file = _attachedFiles[index];
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              file.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _removeAttachment(index),
                            borderRadius: BorderRadius.circular(10),
                            child: Icon(
                              Icons.close,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          Row(
            children: [
              // Boton agregar archivos
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickFiles,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _textInputController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Escribe tu pregunta aqui...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (text) => _sendTextMessage(text),
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          final scale = isListening ? _pulseAnimation.value * 0.08 + 0.96 : 1.0;
                          return Transform.scale(
                            scale: scale,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isListening ? _stopListening : _startListening,
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isListening
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isListening
                                          ? const Color(0xFFEF4444)
                                          : Colors.white.withValues(alpha: 0.15),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    isListening ? Icons.mic : Icons.mic_none,
                                    color: isListening ? const Color(0xFFEF4444) : Colors.white.withValues(alpha: 0.7),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _sendTextMessage(_textInputController.text),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Método para enviar mensaje de texto
  Future<void> _sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    final attachmentsPayload = await _buildAttachmentPayload();
    // Limpiar el campo de texto
    _textInputController.clear();

    // Agregar mensaje del usuario
    setState(() {
      _attachedFiles.clear();
      _messages.add({
        'role': 'user',
        'content': text,
        'timestamp': DateTime.now(),
      });
      _currentState = AssistantState.processing;
    });

    // Reproducir sonido suave de procesamiento
    _playProcessingSound();

    _conversationHistory.add({'role': 'user', 'content': text});

    try {
      final callable = functions.httpsCallable('adanChat');
      final payload = <String, dynamic>{
        'text': text,
        'userId': _userId,
        'history': _conversationHistory,
        'conversationId': _currentConversationId,
      };
      if (attachmentsPayload.isNotEmpty) {
        payload['attachments'] = attachmentsPayload;
      }
      final result = await callable.call(payload);

      final data = result.data;
      final reply = data['reply'] ?? 'No obtuve respuesta.';

      if (data['tokenUsage'] != null) {
        final tokens = data['tokenUsage'];
        _lastPromptTokens = tokens['promptTokens'] ?? 0;
        _lastCompletionTokens = tokens['completionTokens'] ?? 0;
        _lastTotalTokens = tokens['totalTokens'] ?? 0;
        _sessionTotalTokens += _lastTotalTokens;
      }

      if (data['conversationId'] != null) {
        _currentConversationId = data['conversationId'];
      }

      _conversationHistory.add({'role': 'assistant', 'content': reply});

      setState(() {
        _currentResponse = reply;
        _messages.add({
          'role': 'assistant',
          'content': reply,
          'timestamp': DateTime.now(),
        });
      });

      // Hablar la respuesta
      await _speakResponse(reply);

    } catch (e) {
      debugPrint('❌ Error al procesar mensaje de texto: $e');
      setState(() {
        _currentState = AssistantState.inactive;
        _messages.add({
          'role': 'error',
          'content': 'Error: $e',
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  // ===== DISPLAY DE CONVERSACIÓN =====
  Widget _buildConversationDisplay(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1229),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lista de mensajes
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Escribe un mensaje para comenzar',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'o toca el microfono',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: isMobile ? 12 : 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['role'] == 'user';
                      final isError = message['role'] == 'error';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isError
                                      ? Color(0xFFEF4444).withOpacity(0.2)
                                      : Color(0xFF8B5CF6).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isError ? Icons.error : Icons.psychology,
                                  color: isError ? Color(0xFFEF4444) : Color(0xFF8B5CF6),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? Color(0xFF6366F1).withOpacity(0.1)
                                      : isError
                                          ? Color(0xFFEF4444).withOpacity(0.1)
                                          : Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isUser
                                        ? Color(0xFF6366F1).withOpacity(0.3)
                                        : isError
                                            ? Color(0xFFEF4444).withOpacity(0.3)
                                            : Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isUser ? 'Tú' : isError ? 'Error' : 'ADAN',
                                      style: TextStyle(
                                        color: isUser
                                            ? Color(0xFF6366F1)
                                            : isError
                                                ? Color(0xFFEF4444)
                                                : Color(0xFF8B5CF6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Usar Markdown para respuestas del asistente, Linkify para usuario
                                    isUser || isError
                                        ? Linkify(
                                            text: message['content'],
                                            onOpen: (link) async {
                                              final uri = Uri.parse(link.url);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                              }
                                            },
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                            linkStyle: TextStyle(
                                              color: Color(0xFF6366F1),
                                              fontSize: 14,
                                              decoration: TextDecoration.underline,
                                              decorationColor: Color(0xFF6366F1),
                                            ),
                                          )
                                        : MarkdownBody(
                                            data: message['content'],
                                            styleSheet: MarkdownStyleSheet(
                                              p: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 14,
                                                height: 1.5,
                                              ),
                                              h1: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              h2: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              h3: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              strong: const TextStyle(
                                                color: Color(0xFF8B5CF6),
                                                fontWeight: FontWeight.bold,
                                              ),
                                              em: TextStyle(
                                                color: Colors.white.withOpacity(0.7),
                                                fontStyle: FontStyle.italic,
                                              ),
                                              code: TextStyle(
                                                color: const Color(0xFF10B981),
                                                backgroundColor: Colors.white.withOpacity(0.1),
                                                fontFamily: 'monospace',
                                              ),
                                              listBullet: const TextStyle(
                                                color: Color(0xFF8B5CF6),
                                                fontSize: 14,
                                              ),
                                              a: const TextStyle(
                                                color: Color(0xFF6366F1),
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            onTapLink: (text, url, title) async {
                                              if (url != null) {
                                                final uri = Uri.parse(url);
                                                if (await canLaunchUrl(uri)) {
                                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                }
                                              }
                                            },
                                          ),
                                  ],
                                ),
                              ),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF6366F1).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Color(0xFF6366F1),
                                  size: 20,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Texto en tiempo real (transcripción)
          if (_transcribedText.isNotEmpty && _currentState == AssistantState.listening) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF1E293B), height: 1),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFBBF24).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFFFBBF24).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.graphic_eq,
                    color: Color(0xFFFBBF24),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      _transcribedText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===== OVERLAY DE HISTORIAL (MÓVIL) =====
  Widget _buildHistoryOverlay(bool isMobile) {
    return GestureDetector(
      onTap: () => setState(() => _showHistory = false), // Cerrar al tocar fuera
      child: Container(
        color: Colors.black54, // Fondo semi-transparente
        child: GestureDetector(
          onTap: () {}, // Evitar que se cierre al tocar el panel
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1229),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con botón cerrar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: Color(0xFF6366F1), size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Historial',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6366F1), size: 20),
                          onPressed: () {
                            _startNewConversation();
                            setState(() => _showHistory = false);
                          },
                          tooltip: 'Nueva conversación',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () => setState(() => _showHistory = false),
                          tooltip: 'Cerrar',
                        ),
                      ],
                    ),
                  ),
                  // Lista de conversaciones
                  Expanded(
                    child: _loadingHistory
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF6366F1),
                              strokeWidth: 2,
                            ),
                          )
                        : _savedConversations.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'No hay conversaciones guardadas.\nComienza a hablar con ADAN.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadConversationHistory,
                                color: const Color(0xFF6366F1),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _savedConversations.length,
                                  itemBuilder: (context, index) {
                                    final conv = _savedConversations[index];
                                    final isActive = conv['id'] == _currentConversationId;
                                    return _buildHistoryItem(
                                      conv['title'] ?? 'Sin título',
                                      conv['lastMessageAt'] ?? DateTime.now(),
                                      isActive,
                                      conv['messageCount'] ?? 0,
                                      () {
                                        _loadConversation(conv['id']);
                                        setState(() => _showHistory = false); // Cerrar después de seleccionar
                                      },
                                    );
                                  },
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== PANEL DE HISTORIAL (DESKTOP) =====
  Widget _buildHistoryPanel() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1229),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF6366F1), size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Historial',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Botón nueva conversación
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6366F1), size: 20),
                  onPressed: _startNewConversation,
                  tooltip: 'Nueva conversación',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          Expanded(
            child: _loadingHistory
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6366F1),
                      strokeWidth: 2,
                    ),
                  )
                : _savedConversations.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No hay conversaciones guardadas.\nComienza a hablar con ADAN.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadConversationHistory,
                        color: const Color(0xFF6366F1),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _savedConversations.length,
                          itemBuilder: (context, index) {
                            final conv = _savedConversations[index];
                            final isActive = conv['id'] == _currentConversationId;
                            return _buildHistoryItem(
                              conv['title'] ?? 'Sin título',
                              conv['lastMessageAt'] ?? DateTime.now(),
                              isActive,
                              conv['messageCount'] ?? 0,
                              () => _loadConversation(conv['id']),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, DateTime date, bool isActive, int messageCount, VoidCallback onTap) {
    // Necesitamos el conversationId para las acciones, lo extraemos del closure
    String? conversationId;
    for (var conv in _savedConversations) {
      if (conv['title'] == title && conv['messageCount'] == messageCount) {
        conversationId = conv['id'];
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: Color(0xFF6366F1).withOpacity(0.3), width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          onLongPress: conversationId != null
              ? () => _showConversationOptions(conversationId!, title)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Activa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatDateTime(date),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• $messageCount msg',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menú de opciones
                if (conversationId != null)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white.withOpacity(0.4),
                      size: 18,
                    ),
                    color: const Color(0xFF1E293B),
                    onSelected: (value) {
                      if (value == 'rename') {
                        _renameConversation(conversationId!, title);
                      } else if (value == 'delete') {
                        _deleteConversation(conversationId!, title);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 18, color: Color(0xFF6366F1)),
                            const SizedBox(width: 12),
                            const Text('Renombrar', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            const Text('Eliminar', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConversationOptions(String conversationId, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1229),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF6366F1)),
              title: const Text('Renombrar', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _renameConversation(conversationId, title);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text('Eliminar', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _deleteConversation(conversationId, title);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 24) {
      return 'Hace ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays}d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // ===== PANEL DE CONFIGURACIÓN =====
  Widget _buildSettingsPanel() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1229),
        border: Border(
          left: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Color(0xFF6366F1), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Configuración',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Voz
            _buildSettingSection(
              'Configuración de Voz',
              Icons.record_voice_over,
              [
                _buildVoiceSelector(),
                const SizedBox(height: 16),
                _buildSlider('Velocidad', _rate, 0.5, 1.5, (val) async {
                  setState(() => _rate = val);
                  await _tts.setSpeechRate(val);
                  // Guardar preferencia
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setDouble('tts.rate', val);
                }),
                const SizedBox(height: 8),
                _buildSlider('Tono', _pitch, 0.5, 2.0, (val) async {
                  setState(() => _pitch = val);
                  await _tts.setPitch(val);
                  // Guardar preferencia
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setDouble('tts.pitch', val);
                }),
              ],
            ),

            const SizedBox(height: 24),

            // Wake Word
            _buildSettingSection(
              'Wake Word',
              Icons.hearing,
              [
                _buildWakeWordToggle(),
              ],
            ),

            const SizedBox(height: 24),

            // Modelo
            _buildSettingSection(
              'Modelo de IA',
              Icons.psychology,
              [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Color(0xFF10B981), width: 1),
                            ),
                            child: const Text(
                              'GPT-4o-mini',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Activo',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Modelo optimizado para conversaciones rápidas y eficientes',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF8B5CF6), size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildWakeWordToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _isWakeWordEnabled ? Icons.hearing : Icons.hearing_disabled,
            color: _wakeWordSupported ? const Color(0xFF10B981) : Colors.white24,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wake Word',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _wakeWordSupported
                      ? 'Di "Hey ADAN" para activar'
                      : 'Disponible solo en Android',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isWakeWordEnabled,
            onChanged: _wakeWordSupported
                ? (value) async {
                    if (value) {
                      await _wakeWordService.initialize();
                      await _wakeWordService.startBackgroundService();
                    } else {
                      await _wakeWordService.stopBackgroundService();
                    }
                    if (mounted) {
                      setState(() => _isWakeWordEnabled = value);
                    }
                  }
                : null,
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _elevenLabsVoiceId,
        isExpanded: true,
        dropdownColor: Color(0xFF1E293B),
        underline: const SizedBox(),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        items: _elevenLabsVoices.map((voice) {
          return DropdownMenuItem<String>(
            value: voice['id'],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  voice['name']!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  voice['desc']!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) async {
          if (value != null) {
            setState(() => _elevenLabsVoiceId = value);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('elevenlabs.voice.id', value);
          }
        },
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Color(0xFF6366F1),
            inactiveTrackColor: Color(0xFF1E293B),
            thumbColor: Color(0xFF6366F1),
            overlayColor: Color(0xFF6366F1).withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ===== OVERLAY DE CONFIGURACIÓN MÓVIL =====
  Widget _buildSettingsOverlay(bool isMobile) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1229),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.settings, color: Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Configuración',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _showSettings = false),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSettingSection(
                        'Configuración de Voz',
                        Icons.record_voice_over,
                        [
                          _buildVoiceSelector(),
                          const SizedBox(height: 16),
                          _buildSlider('Velocidad', _rate, 0.5, 1.5, (val) async {
                            setState(() => _rate = val);
                            await _tts.setSpeechRate(val);
                            // Guardar preferencia
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setDouble('tts.rate', val);
                          }),
                          const SizedBox(height: 8),
                          _buildSlider('Tono', _pitch, 0.5, 2.0, (val) async {
                            setState(() => _pitch = val);
                            await _tts.setPitch(val);
                            // Guardar preferencia
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setDouble('tts.pitch', val);
                          }),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildSettingSection(
                        'Wake Word',
                        Icons.hearing,
                        [
                          _buildWakeWordToggle(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== BARRA DE MODO DESARROLLADOR =====
  Widget _buildDevModeBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1229),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.code, color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 8),
              const Text(
                'Modo Desarrollador',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildDevStat('Tokens usados', '$_lastTotalTokens', Color(0xFF6366F1)),
              _buildDevStat('Sesión total', '$_sessionTotalTokens', Color(0xFF8B5CF6)),
              _buildDevStat(
                'Costo',
                '\$${(_sessionTotalTokens * 0.00015 / 1000).toStringAsFixed(4)}',
                Color(0xFF10B981),
              ),
              if (_currentConversationId != null)
                _buildDevStat('Conv ID', _currentConversationId!.substring(0, 8), Color(0xFFFBBF24)),
              _buildDevStat('Estado', _currentState.toString().split('.').last, Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ===== GENERACIÓN DE PROYECTO DESDE CONVERSACIÓN =====
  Future<void> _generarProyectoDesdeConversacion() async {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No hay suficiente contexto para generar un proyecto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Paso 1: Preguntar metodología
    final metodologia = await _mostrarDialogoMetodologia();
    if (metodologia == null) return; // Usuario canceló

    if (!mounted) return;

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: Color(0xFF0D1229),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF6366F1)),
                SizedBox(height: 16),
                Text(
                  '🤖 Generando proyecto desde conversación...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Esto puede tomar 2-3 minutos',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Paso 2: Preparar contexto de conversación
      final contextoConversacion = _prepararContextoConversacion();

      // Paso 3: Convertir archivos adjuntos a base64 (si hay)
      List<String> documentosBase64 = [];
      if (_attachedFiles.isNotEmpty) {
        for (var file in _attachedFiles) {
          documentosBase64.add(base64Encode(file.bytes));
        }
      }

      // Paso 4: Generar nombre del proyecto basado en conversación
      final nombreProyecto = await _generarNombreProyecto(contextoConversacion);

      // Paso 5: Llamar al servicio de IA para generar proyecto
      final proyectoIA = await _pmiIAService.generarProyectoPMIConIA(
        documentosBase64: documentosBase64,
        nombreProyecto: nombreProyecto,
        descripcionBreve: contextoConversacion,
      );

      if (proyectoIA == null) {
        throw Exception('Error generando estructura PMI');
      }

      // Paso 6: Crear proyecto en Firestore
      final pmiService = _pmiIAService.pmiService;
      final proyectoId = await pmiService.crearProyectoPMI(
        nombre: nombreProyecto,
        descripcion: proyectoIA['descripcion'] ?? contextoConversacion,
        fechaInicio: DateTime.now(),
        fechaFin: null,
        objetivo: proyectoIA['objetivo'],
        alcance: proyectoIA['alcance'],
        presupuesto: proyectoIA['presupuestoEstimado']?.toDouble(),
        categoria: metodologia,
        vision: '',
      );

      if (proyectoId == null) {
        throw Exception('Error creando proyecto en Firestore');
      }

      // Paso 7: Guardar tareas generadas por IA
      final user = FirebaseAuth.instance.currentUser;
      await _guardarTareasEnProyecto(proyectoId, proyectoIA, user?.uid);

      if (!mounted) return;
      Navigator.pop(context); // Cerrar diálogo de carga

      // Mostrar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Proyecto generado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar al proyecto
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProyectoDetalleKanbanPage(
            proyectoId: proyectoId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar diálogo de carga

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error generando proyecto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Mostrar diálogo para seleccionar metodología
  Future<String?> _mostrarDialogoMetodologia() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1229),
        title: const Text(
          '🎯 Seleccionar Metodología',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Qué metodología deseas usar para este proyecto?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _buildMetodologiaOption(
              context,
              'Proyecto Flexible',
              'Adaptable a cambios, ideal para proyectos dinámicos',
              Icons.widgets_outlined,
            ),
            const SizedBox(height: 8),
            _buildMetodologiaOption(
              context,
              'PMI',
              'Metodología tradicional con fases definidas',
              Icons.architecture,
            ),
            const SizedBox(height: 8),
            _buildMetodologiaOption(
              context,
              'Agile',
              'Desarrollo iterativo y entrega continua',
              Icons.speed,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodologiaOption(
    BuildContext context,
    String nombre,
    String descripcion,
    IconData icono,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, nombre),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icono, color: const Color(0xFF6366F1), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descripcion,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Preparar contexto de conversación para enviar a IA
  String _prepararContextoConversacion() {
    final buffer = StringBuffer();
    buffer.writeln('Contexto de la conversación:\n');

    for (var msg in _messages) {
      final role = msg['role'] == 'user' ? 'Usuario' : 'Asistente';
      final content = msg['content'] ?? '';
      buffer.writeln('$role: $content\n');
    }

    return buffer.toString();
  }

  /// Generar nombre de proyecto basado en conversación
  Future<String> _generarNombreProyecto(String contexto) async {
    // Tomar los primeros mensajes del usuario para inferir el nombre
    final mensajesUsuario = _messages
        .where((m) => m['role'] == 'user')
        .take(3)
        .map((m) => m['content'] as String?)
        .where((c) => c != null && c.isNotEmpty)
        .toList();

    if (mensajesUsuario.isEmpty) {
      return 'Proyecto ${DateTime.now().toString().substring(0, 10)}';
    }

    // Usar las primeras palabras del primer mensaje
    final primerMensaje = mensajesUsuario.first!;
    final palabras = primerMensaje.split(' ').take(5).join(' ');
    return palabras.length > 50 ? '${palabras.substring(0, 47)}...' : palabras;
  }

  /// Guardar tareas del proyecto generado por IA
  Future<void> _guardarTareasEnProyecto(
    String proyectoId,
    Map<String, dynamic> proyectoIA,
    String? userId,
  ) async {
    final fases = proyectoIA['fases'] as List?;
    if (fases == null || fases.isEmpty) return;

    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    for (var fase in fases) {
      final tareas = fase['tareas'] as List?;
      if (tareas == null) continue;

      for (var tarea in tareas) {
        final tareaRef = db
            .collection('proyectos')
            .doc(proyectoId)
            .collection('tareas')
            .doc();

        batch.set(tareaRef, {
          'titulo': tarea['titulo'] ?? '',
          'descripcion': tarea['descripcion'] ?? '',
          'duracion': tarea['duracion'] ?? 60,
          'dificultad': tarea['dificultad'] ?? 'Media',
          'tipoTarea': 'Libre',
          'requisitos': tarea['requisitos'] ?? '',
          'responsables': userId != null ? [userId] : [],
          'completado': false,
          'prioridad': tarea['prioridad'] ?? 2,
          'colorId': 0,
          'fasePMI': fase['nombre'] ?? '',
          'entregable': tarea['entregable'] ?? '',
          'paqueteTrabajo': tarea['paqueteTrabajo'] ?? '',
          'area': '',
          'habilidadesRequeridas': tarea['habilidadesRequeridas'] ?? [],
          'tareasPrevias': [],
          'fechaCreacion': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }
}



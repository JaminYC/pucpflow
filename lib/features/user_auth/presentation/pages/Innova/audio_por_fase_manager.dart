import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AudioPorFaseSpeechManager {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechDisponible = false;
  bool _isListening = false;
  String _transcripcionParcial = "";
  final List<String> _fragmentos = [];

  Function(String textoCompleto)? onFinal;
  Function(String textoParcial)? onUpdate;


  AudioPorFaseSpeechManager({this.onFinal, this.onUpdate});

  bool get isDisponible => _speechDisponible;
  bool get isListening => _isListening;
  String get textoActual => [..._fragmentos, _transcripcionParcial].join(". \n\n");

  Future<void> inicializar() async {
    if (_speechDisponible) return; // evita reinicialización

    try {
      _speechDisponible = await _speech.initialize(
        onStatus: _manejarEstado,
        onError: (e) => print("❌ Error STT: $e"),
      );
    } catch (e) {
      print("❌ Excepción al inicializar Speech: $e");
      _speechDisponible = false;
    }
  }


Future<bool> iniciar() async {
  if (!_speechDisponible) return false;

  if (_speech.isListening) {
    await _speech.stop(); // Evita el error
    _guardarParcial();
  }

  final resultado = await _speech.listen(
    localeId: 'es_PE',
    listenOptions: stt.SpeechListenOptions(
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.dictation,
      autoPunctuation: true,
    ),
    onResult: (result) {
      _transcripcionParcial = result.recognizedWords;
      if (onUpdate != null) onUpdate!(textoActual);
      if (result.finalResult) _guardarParcial();
    },
  );

  _isListening = resultado == true;
  return _isListening;
}


  Future<void> detener() async {
    if (_isListening) {
      await _speech.stop();
      _guardarParcial();
      _isListening = false;

      if (onFinal != null) onFinal!(textoActual);
    }
  }
  void actualizarCallbacks({
    Function(String textoParcial)? onUpdate,
    Function(String textoCompleto)? onFinal,
  }) {
    this.onUpdate = onUpdate;
    this.onFinal = onFinal;
  }

  void _manejarEstado(String status) {
    if (status == "done" || status == "notListening") {
      if (_isListening) {
        _guardarParcial();
        _isListening = false;
        if (onFinal != null) onFinal!(textoActual);
      }
    }
  }

  void _guardarParcial() {
    if (_transcripcionParcial.trim().isNotEmpty) {
      _fragmentos.add(_transcripcionParcial.trim());
      _transcripcionParcial = "";
    }
  }

  void limpiar() {
    _transcripcionParcial = "";
    _fragmentos.clear();
  }
}

// 📂 audio_por_fase_manager_speech.dart
// Manejador de audio y transcripción por fase usando speech_to_text

import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AudioPorFaseSpeechManager {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechDisponible = false;
  bool _isListening = false;
  String _transcripcionParcial = "";
  final List<String> _fragmentos = [];

  final Function(String textoCompleto)? onFinal;
  final Function(String textoParcial)? onUpdate;

  AudioPorFaseSpeechManager({this.onFinal, this.onUpdate});

  bool get isDisponible => _speechDisponible;
  bool get isListening => _isListening;
  String get textoActual => [..._fragmentos, _transcripcionParcial].join(". \n\n");

  Future<void> inicializar() async {
    _speechDisponible = await _speech.initialize(
      onStatus: _manejarEstado,
      onError: (e) => print("❌ Error STT: \$e"),
    );
  }

  void _manejarEstado(String status) {
    if (status == "done" || status == "notListening") {
      _guardarParcial();
      _reiniciarEscucha();
    }
  }

  void _reiniciarEscucha() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_speechDisponible) iniciar();
  }

  void iniciar() async {
    if (!_speechDisponible) return;

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

    if (resultado) _isListening = true;
  }

  void detener() async {
    await _speech.stop();
    _isListening = false;
    _guardarParcial();
    if (onFinal != null) onFinal!(textoActual);
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

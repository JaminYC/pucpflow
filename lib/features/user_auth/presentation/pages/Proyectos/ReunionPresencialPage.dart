import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ResumenYGeneracionTareasPage.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:video_player/video_player.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_model.dart';


import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReunionPresencialPage extends StatefulWidget {
  final Proyecto proyecto;
  const ReunionPresencialPage({super.key, required this.proyecto});

  @override
  State<ReunionPresencialPage> createState() => _ReunionPresencialPageState();
}

class _ReunionPresencialPageState extends State<ReunionPresencialPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  late VideoPlayerController _videoController;

  bool _isListening = false;
  bool _speechDisponible = false;
  String _transcripcionParcial = "";
  List<String> _fragmentos = [];
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _inicializarVideo();
    _inicializarSpeech();
  }

  void _inicializarVideo() {
    _videoController = VideoPlayerController.asset("assets/videos_micro.mp4")
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0);
        _videoController.play();
        setState(() {});
      });
  }

  Future<void> _inicializarSpeech() async {
  _speechDisponible = await _speech.initialize(
        onStatus: _manejarEstado,
        onError: (error) {
          debugPrint("❌ Error: $error");
          _reiniciarEscucha();
        },
        debugLogging: false,
      ) ?? false;


    if (_speechDisponible) {
      _iniciarEscucha();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo activar el micrófono.")),
      );
    }
  }

  void _manejarEstado(String status) {
    debugPrint("🎤 Estado: $status");
    if (status == "done" || status == "notListening") {
      _guardarParcial();
      _reiniciarEscucha();
    }
  }

  void _reiniciarEscucha() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _iniciarEscucha();
  }

  void _iniciarEscucha() async {
    bool started = await _speech.listen(
      localeId: 'es_PE',
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
        autoPunctuation: true,
      ),
      onResult: (result) {
        setState(() {
          _transcripcionParcial = result.recognizedWords;
          if (result.finalResult) _guardarParcial();
        });
      },
    );

    if (started) {
      _iniciarTimer();
      setState(() => _isListening = true);
    } else {
      debugPrint("⚠️ No se pudo iniciar la escucha.");
    }
  }

  void _guardarParcial() {
    if (_transcripcionParcial.trim().isNotEmpty) {
      _fragmentos.add(_transcripcionParcial.trim());
      debugPrint("✅ Fragmento guardado: $_transcripcionParcial");
      _transcripcionParcial = "";
    }
  }

  void _detenerEscucha() async {
    await _speech.stop();
    _detenerTimer();
    _guardarParcial();
    setState(() => _isListening = false);
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  void _detenerTimer() {
    _timer?.cancel();
  }

  void _finalizarReunion() {
    _detenerEscucha();
    final textoCompleto = [..._fragmentos, _transcripcionParcial].join(". ");

    if (textoCompleto.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗No hay contenido para procesar.")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Generando resumen y tareas..."),
          ],
        ),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResumenYGeneracionTareasPage(
          texto: textoCompleto,
          proyecto: widget.proyecto,
        ),
      ),
    );
  }

  String _formatoTiempo(int segundos) {
    final minutos = (segundos ~/ 60).toString().padLeft(2, '0');
    final seg = (segundos % 60).toString().padLeft(2, '0');
    return "$minutos:$seg";
  }

  @override
  void dispose() {
    _detenerTimer();
    _speech.stop();
    _videoController.dispose();
    super.dispose();
  }
  



  @override
  Widget build(BuildContext context) {
    final textoFinal = [..._fragmentos, _transcripcionParcial].join(".\n\n");

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _videoController.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : Container(color: Colors.black),
          ),
                // Overlay oscuro para contraste
          Container(color: Colors.black.withOpacity(0.5)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBar(
                    title: const Text("Reunión Presencial"),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "🎙 Reunión Presencial",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (_isListening)
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.greenAccent),
                              const SizedBox(width: 4),
                              Text(_formatoTiempo(_seconds), style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                      ],
                    ),

                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(textoFinal, style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 0, 0, 0))),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _speechDisponible
                            ? (_isListening ? _detenerEscucha : _iniciarEscucha)
                            : null,
                        icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                        label: Text(_isListening ? "Detener" : "Hablar"),
                      ),
                      ElevatedButton.icon(
                        onPressed: _finalizarReunion,
                        icon: const Icon(Icons.check),
                        label: const Text("Finalizar"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: textoFinal));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("📋 Copiado al portapapeles")),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text("Copiar"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          String textoPegado = "";

                          await showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: const Text("📄 Pegar Transcripción Manual"),
                                content: TextField(
                                  maxLines: 10,
                                  onChanged: (value) => textoPegado = value,
                                  decoration: const InputDecoration(
                                    hintText: "Pega aquí el texto completo de la reunión...",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancelar"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (textoPegado.trim().length > 20) {
                                        Navigator.pop(context);
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ResumenYGeneracionTareasPage(
                                              texto: textoPegado.trim(),
                                              proyecto: widget.proyecto,
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("⚠️ El texto es demasiado corto para procesar.")),
                                        );
                                      }
                                    },
                                    child: const Text("Procesar"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.paste),
                        label: const Text("Pegar texto"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                      ),
                    ],
                  ),
                  if (!_speechDisponible)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text("⚠️ Reconocimiento de voz no disponible", style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

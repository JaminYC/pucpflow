import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/AsistenteIA/agendareventos.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt show SpeechRecognitionResult;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'comando_page.dart';  // Importa la página de comandos
import 'package:pucpflow/features/user_auth/presentation/pages/AsistenteIA/comando_service.dart';

class AsistentePage extends StatefulWidget {
  @override
  _AsistentePageState createState() => _AsistentePageState();
}

class _AsistentePageState extends State<AsistentePage> {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _spokenText = "";
  String _language = "es_ES"; // Idioma predeterminado: Español
  List<String> _history = []; // Historial de resultados finales
  Timer? _monitorTimer; // Timer para monitorear el estado de escucha
  final ComandoService _comandoService = ComandoService();

  final List<String> _comandosValidos = [
  "agendar evento",
  "organizar eventos de la semana",
  "tareas pendientes",
];

  @override
  void initState() {
    super.initState();
    _requestMicrophonePermission();
    _initializeSpeech();
  }

  // Solicita permiso para el micrófono.
  void _requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      print("⚠️ Permiso de micrófono denegado.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Debe habilitar el micrófono en configuración.")),
        );
      }
    }
  }

  // Inicializa el reconocimiento de voz.
  void _initializeSpeech() async {
    _speechEnabled = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    if (mounted) setState(() {});
  }

  // Inicia la escucha y configura el Timer de monitoreo.
  void _startListening() async {
    if (!_speechEnabled) {
      print("⚠️ Reconocimiento de voz no disponible.");
      return;
    }
    if (_isListening) return; // Evitar iniciar si ya está escuchando

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        partialResults: true,
        localeId: _language,
        // Se reduce la duración para responder más rápido a pausas.
        pauseFor: Duration(seconds: 5),
      );
    } catch (e) {
      print("Error al iniciar la escucha: $e");
    }

    if (mounted) {
      setState(() {
        _isListening = true;
      });
    }

    _startMonitorTimer();
  }

  // Detiene la escucha y cancela el Timer.
  void _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
    _cancelMonitorTimer();
  }

void _onSpeechResult(stt.SpeechRecognitionResult result) {
  if (result.recognizedWords.isNotEmpty && mounted) {
    setState(() {
      _spokenText = result.recognizedWords.toLowerCase().trim();

      // 🔹 Verifica si la frase detectada contiene un comando válido
      bool esComandoValido = _comandosValidos.any((cmd) => _spokenText.contains(cmd));
      
      if (result.finalResult) {
        if(esComandoValido){
        // 🔹 Enviar a la pantalla de comandos
          _procesarComando(_spokenText); // ✅ Ejecuta directamente el comando
        }
        _history.add(_spokenText); // ✅ Solo guarda en el historial si es válido
      }
    });
  }
}
void _procesarComando(String comando) {
  var datosEvento = _comandoService.procesarComando(comando);

  if (datosEvento["accion"] == "organizar") {
    // ✅ Organiza automáticamente los eventos de la semana
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🔄 Organizando eventos de la semana...")),
    );
    return;
  }

  if (datosEvento["completo"]) {
    // ✅ Si tiene toda la información, agenda automáticamente
    _comandoService.crearEventoEnGoogleCalendar(datosEvento["nombre"], datosEvento["fechaHora"]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Evento '${datosEvento["nombre"]}' agendado correctamente.")),
    );
  } else {
    // ❌ Si falta información crítica, abrir `CrearEventoPage`
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearEventoPage(
          nombre: datosEvento["nombre"],
          fecha: datosEvento["fechaHora"]?.toLocal().toString() ?? "",
          hora: "",
        ),
      ),
    );
  }
}





  // Maneja los cambios de estado del reconocimiento.
  void _onSpeechStatus(String status) {
    print("🎤 Estado del micrófono: $status");
    if (status == "done" && _isListening) {
      _restartListening();
    }
  }

  // Maneja errores en el reconocimiento.
  void _onSpeechError(dynamic error) {
    print("❌ Error: $error");
    if (_isListening && mounted) {
      _restartListening();
    }
  }

  // Reinicia la escucha.
  void _restartListening() {
    _cancelMonitorTimer();
    _stopListening();
    // Reinicio rápido (200 ms) para que la transición sea inmediata.
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        _startListening();
      }
    });
  }

  // Inicia un Timer periódico que verifica el estado de la escucha.
  void _startMonitorTimer() {
    _cancelMonitorTimer();
    // Se verifica cada 2 segundos para detectar cortes rápidamente.
    _monitorTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (!mounted) return;
      if (!_speech.isListening && _isListening) {
        print("🔄 Timer detecta que no está escuchando, reiniciando...");
        _restartListening();
      }
    });
  }

  // Cancela el Timer de monitoreo.
  void _cancelMonitorTimer() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  // Permite cambiar el idioma y reiniciar la escucha.
  void _changeLanguage(String languageCode) {
    if (languageCode == _language) return;
    _language = languageCode;
    _spokenText = "";
    _stopListening();
    _startListening();
  }

  // Limpia el historial (opcional).
  void _clearHistory() {
    if (mounted) {
      setState(() {
        _history.clear();
      });
    }
  }

  @override
  void dispose() {
    _cancelMonitorTimer();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Asistente Virtual")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Indicador de estado y control de grabación.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isListening ? Icons.mic : Icons.mic_off,
                  color: _isListening ? Colors.red : Colors.grey,
                  size: 50,
                ),
                SizedBox(width: 10),
                Text(
                  _isListening ? "Escuchando..." : "No está escuchando",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Área de texto para mostrar el resultado parcial.
            Container(
              padding: EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _spokenText.isEmpty
                    ? "Presiona el botón y habla..."
                    : _spokenText,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            // Botón de inicio/detención de grabación.
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? "Detener Grabación" : "Iniciar Grabación"),
            ),
            SizedBox(height: 20),
            // Selector de idioma.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () => _changeLanguage("es_ES"),
                  child: Text("Español"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _changeLanguage("en_US"),
                  child: Text("Inglés"),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Historial de resultados.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Historial:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: _clearHistory,
                  tooltip: "Limpiar historial",
                )
              ],
            ),
            // Lista de historial con un contenedor de altura fija.
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _history.isEmpty
                    ? Center(child: Text("No hay historial aún."))
                    : ListView.builder(
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Icon(Icons.history),
                            title: Text(_history[index]),
                          );
                        },
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

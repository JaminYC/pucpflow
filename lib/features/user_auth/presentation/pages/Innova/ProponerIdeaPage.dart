// Dart SDK
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

// Flutter framework
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Permissions & media
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

// Audio
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/flutter_sound.dart' as fs;
import 'package:audioplayers/audioplayers.dart';

// PDF & printing
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// File system helpers
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import 'package:pucpflow/features/user_auth/presentation/pages/Innova/audio_por_fase_manager.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/audio_player_widget.dart';
// Your app imports
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/CrearProyectoDesdeIdeaPage.dart'
    show CrearProyectoDesdeIdeaPage;
import 'idea.dart';

// Web-only (ignore lint for flutter_web)
// import 'dart:html' as html; // ignore: avoid_web_libraries_in_flutter


import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';



import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:speech_to_text/speech_to_text.dart';

class ProponerIdeaPage extends StatefulWidget {
  const ProponerIdeaPage({super.key});

  @override
  State<ProponerIdeaPage> createState() => _ProponerIdeaPageState();
}

class _ProponerIdeaPageState extends State<ProponerIdeaPage> {
  // Clave del formulario
  final _formKey = GlobalKey<FormState>();
  late AudioPorFaseSpeechManager _speechManager;


  TextEditingController? _currentController;

  final Map<int, bool> _grabandoPorFase = {
      1: false,
      2: false,
    };
  // -----------------------------
  // 1) Controles de texto por fase

  // -----------------------------
  // Fase 1: Exploración
  final _contextoController     = TextEditingController();
  final _procesoController      = TextEditingController();
  final _problemaController     = TextEditingController();
  final _causasController       = TextEditingController();
  final _herramientasController = TextEditingController();

  // Fase 2: Propuesta de Solución
  final _solucionController     = TextEditingController();
  final _ataqueController       = TextEditingController();
  final _materialesController   = TextEditingController();

  // Iteración IA
  final List<TextEditingController> _respuestaControllers = [];

  // -----------------------------
  // 2) Estado multimedia por fase (reemplazado por managers)
  // -----------------------------

  String _transcripcionFase1 = "";
  String _transcripcionFase2 = "";
  String? _imagenURL1;
  String? _imagenURL2;

  final AudioPlayer _audioPlayer = AudioPlayer();
  // -----------------------------
  // 3) Variables globales
  // -----------------------------
  bool     _procesando         = false;
  String?  _mensajeController  = TextEditingController().text;

  // IA
  dynamic  _respuestaIA;
  dynamic  _respuestaIteracion;
  bool     _mostrandoFormularioRespuestas = false;
  bool     _respuestasGuardadas           = false;
  dynamic  _respuestaValidacionFinal;
  DocumentReference? _ideaRef;

  @override
  void initState() {
    super.initState();
    _speechManager = AudioPorFaseSpeechManager(
      onUpdate: (textoParcial) {
        setState(() {
          _currentController?.text = textoParcial;
        });
      },
      onFinal: (textoFinal) {
        setState(() {
          _currentController?.text = textoFinal;
        });
      },
    );

    _speechManager.inicializar();
  }


  @override
  void dispose() {
    // Dispose todos los controllers
    _contextoController.dispose();
    _procesoController.dispose();
    _problemaController.dispose();
    _causasController.dispose();
    _herramientasController.dispose();
    _solucionController.dispose();
    _ataqueController.dispose();
    _materialesController.dispose();
    for (var c in _respuestaControllers) c.dispose();

    super.dispose();
  }



  Future<String?> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return null;
    final bytes = await img.readAsBytes();
    final name  = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref   = FirebaseStorage.instance.ref().child('ideas/$name');
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }
Widget _buildCard(
  String titulo, {
  required List<Widget> campos,
  Widget? multimedia,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF1F1F1),
                ),
              ),
              const SizedBox(height: 12),
              ...campos,
              if (multimedia != null) ...[
                const SizedBox(height: 12),
                multimedia,
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _enviarIdea() async {
  // Validar manualmente solo el campo "problema"
  if (_problemaController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ El campo 'Problema' es obligatorio.")),
    );
    return;
  }
  setState(() => _procesando = true);
  await Future.delayed(const Duration(milliseconds: 100));
  await Future(() {}); // Deja libre el hilo de render

  final idea = Idea(
    contexto: _contextoController.text,
    proceso: _procesoController.text,
    problema: _problemaController.text,
    causas: _causasController.text,
    herramientas: _herramientasController.text,
    solucion: _solucionController.text,
    ataque: _ataqueController.text,
    materiales: _materialesController.text,
  );

  try {
    final user = FirebaseAuth.instance.currentUser;
    final esCuentaFirebase = user != null;
    final autor = esCuentaFirebase ? user!.email ?? "sin_email" : "cuenta_empresarial";

    // Protecciones contra null
    final transcripcionF1 = _transcripcionFase1 ?? '';
    final transcripcionF2 = _transcripcionFase2 ?? '';
    final imagen1 = _imagenURL1 ?? '';
    final imagen2 = _imagenURL2 ?? '';

    // Debug
    print("🚀 Enviando idea desde: $autor");
    print("📤 Datos a enviar: ${{
      ...idea.toJson(),
      'transcripcionFase1': transcripcionF1,
      'transcripcionFase2': transcripcionF2,
      'imagenURL1': imagen1,
      'imagenURL2': imagen2,
      'usuario': autor,
    }}");

    // Guardar en Firestore
    _ideaRef = await FirebaseFirestore.instance.collection('ideas').add({
      ...idea.toJson(),
      'estado': 'pendiente',
      'timestamp': FieldValue.serverTimestamp(),
      'autor': autor,
      'transcripcionFase1': transcripcionF1,
      'transcripcionFase2': transcripcionF2,
      'imagenURL1': imagen1,
      'imagenURL2': imagen2,
    });

    // Llamar función de análisis IA
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('analizarIdea');
    final result = await callable.call({
      ...idea.toJson(),
      'transcripcionFase1': transcripcionF1,
      'transcripcionFase2': transcripcionF2,
      'imagenURL1': imagen1,
      'imagenURL2': imagen2,
      'usuario': autor,
    });

    setState(() => _respuestaIA = result.data);

    await _ideaRef!.update({
      'estado': 'analizada',
      'resultadoIA': result.data,
    });

    print("✅ Análisis IA exitoso");

  } catch (e, st) {
    print("❌ Error al procesar idea: $e");
    print("🧱 StackTrace: $st");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Error: $e')),
    );
  } finally {
    setState(() => _procesando = false);
  }
}



  Future<void> ejecutarConCarga(Future<void> Function() funcion) async {
    setState(() => _procesando = true);
    await Future.delayed(const Duration(milliseconds: 100));
    await Future(() {}); // Deja respirar al renderizador de Flutter

    try {
      await funcion();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => _procesando = false);
    }
  }

  Future<void> _iterarIdea() async {
      if (_respuestaIA == null) return;

      setState(() => _procesando = true);
      await Future.delayed(Duration(milliseconds: 100));
      await Future(() {}); // ⬅ deja libre el hilo de dibujo


      try {
        final callable = FirebaseFunctions.instance.httpsCallable('iterarIdea');
        final result = await callable.call({
          'resumenProblema': _respuestaIA!["resumenProblema"] ?? '',
          'resumenSolucion': _respuestaIA!["resumenSolucion"] ?? '',
          'evaluacion': _respuestaIA!["evaluacion"] ?? '',
        });
        setState(() => _respuestaIteracion = result.data);

        if (_ideaRef != null) {
          await _ideaRef!.update({'faseIteracion': result.data});
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al iterar con IA: $e')),
        );
      } finally {
        setState(() => _procesando = false);
      }
    }

  Future<void> _guardarRespuestasIteracion() async {
  if (_ideaRef == null || _respuestaIteracion == null) return;

  setState(() => _procesando = true); // ⬅️ Activar GIF
  await Future.delayed(Duration(milliseconds: 100));
  await Future(() {}); // ⬅ deja libre el hilo de dibujo
  try {
    final respuestas = <String, String>{};
    final preguntas = List<String>.from(_respuestaIteracion!["preguntasIterativas"] ?? []);

    for (int i = 0; i < preguntas.length; i++) {
      respuestas[preguntas[i]] = _respuestaControllers[i].text;
    }

    await _ideaRef!.update({
      'respuestasIteracion': respuestas,
    });

    setState(() {
      _respuestasGuardadas = true;
      _mostrandoFormularioRespuestas = false;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Error al guardar respuestas: $e")),
    );
  } finally {
    setState(() => _procesando = false); // ⬅️ Desactivar GIF
  }
}

  Future<void> _validarRespuestasIA() async {
    if (_ideaRef == null || _respuestaIteracion == null || _respuestaIA == null) return;

    setState(() => _procesando = true);
    await Future.delayed(Duration(milliseconds: 100));
    await Future(() {}); // ⬅ deja libre el hilo de dibujo

    try {
      final doc = await _ideaRef!.get();
      final respuestasGuardadas = Map<String, dynamic>.from(doc["respuestasIteracion"] ?? {});

      final callable = FirebaseFunctions.instance.httpsCallable('validarRespuestasIteracion');
      final result = await callable.call({
        "resumenProblema": _respuestaIA!["resumenProblema"] ?? '',
        "resumenSolucion": _respuestaIA!["resumenSolucion"] ?? '',
        "respuestasIteracion": respuestasGuardadas,
      });

      setState(() => _respuestaValidacionFinal = result.data);

      await _ideaRef!.update({
        "validacionFinalIA": result.data,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al validar respuestas IA: $e")),
      );
    } finally {
      setState(() => _procesando = false);
    }
  }

  Widget _mostrarValidacionFinal() {
    if (_respuestaValidacionFinal == null) return const SizedBox();

    return Card(
      color: Colors.green[50],
      margin: const EdgeInsets.only(top: 30),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📋 Evaluación Final IA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text("📈 Madurez actualizada: ${_respuestaValidacionFinal!["madurezActualizada"] ?? "-"}%"),
            Text("✅ ¿Aprobada para prototipar?: ${_respuestaValidacionFinal!["aprobadaParaPrototipo"] == true ? "Sí" : "No"}"),
            const SizedBox(height: 10),
            Text("📝 Comentario final: ${_respuestaValidacionFinal!["comentarioFinal"] ?? "-"}"),
          ],
        ),
      ),
    );
  }

  pw.Widget _seccion(String titulo, pw.TextStyle titleStyle, pw.TextStyle bodyStyle, List<String> contenido) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(titulo, style: titleStyle),
        pw.Divider(),
        ...contenido.map((linea) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(linea, style: bodyStyle, textAlign: pw.TextAlign.justify),
            )),
        pw.SizedBox(height: 16),
      ],
    );
  }

Future<void> generarInformeCompletoPDF() async {
  final pdf = pw.Document();
  final user = FirebaseAuth.instance.currentUser;
  final fecha = DateTime.now();
  final logoBytes = await rootBundle.load('assets/vortystorm.jpg'); // o tu logo real
  final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

  final preguntas = List<String>.from(_respuestaIteracion?["preguntasIterativas"] ?? []);
  final respuestas = _respuestaControllers.map((c) => c.text).toList();

  final tituloPrincipal = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold);
  final subtitulo = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
  final textoNormal = pw.TextStyle(fontSize: 12);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (context) => pw.Text(
        "Página ${context.pageNumber} de ${context.pagesCount}",
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        textAlign: pw.TextAlign.center,
      ),
      build: (context) => [
        // ENCABEZADO CON LOGO Y USUARIO
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Informe de Idea Innovadora", style: tituloPrincipal),
                pw.SizedBox(height: 10),
                pw.Text("Usuario: ${user?.email ?? 'Anónimo'}", style: textoNormal),
                pw.Text("Fecha: ${fecha.toLocal()}", style: textoNormal),
              ],
            ),
            pw.Container(width: 60, height: 60, child: pw.Image(logoImage, fit: pw.BoxFit.contain)),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 16),

        // SECCIONES
        _seccion("1. Fase de Contexto", subtitulo, textoNormal, [
          "Contexto: ${_contextoController.text}",
          "Proceso: ${_procesoController.text}",
          "Problema: ${_problemaController.text}",
          "Causas: ${_causasController.text}",
          "Herramientas: ${_herramientasController.text}",
        ]),

        _seccion("2. Propuesta de Solución", subtitulo, textoNormal, [
          "Solución: ${_solucionController.text}",
          "Ataque a las causas: ${_ataqueController.text}",
          "Materiales necesarios: ${_materialesController.text}",
        ]),

        if (_respuestaIA != null)
          _seccion("3. Análisis IA", subtitulo, textoNormal, [
            "Resumen del problema: ${_respuestaIA!["resumenProblema"] ?? '-'}",
            "Resumen de la solución: ${_respuestaIA!["resumenSolucion"] ?? '-'}",
            "Evaluación IA: ${_respuestaIA!["evaluacion"] ?? '-'}",
          ]),

        if (preguntas.isNotEmpty)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("4. Iteración IA", style: subtitulo),
              pw.Divider(),
              ...List.generate(preguntas.length, (i) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text("P: ${preguntas[i]}\nR: ${respuestas[i]}",
                      style: textoNormal, textAlign: pw.TextAlign.justify),
                );
              }),
              pw.SizedBox(height: 16),
            ],
          ),

        if (_respuestaValidacionFinal != null)
          _seccion("5. Validación Final", subtitulo, textoNormal, [
            "Madurez: ${_respuestaValidacionFinal!["madurezActualizada"]}%",
            "¿Apta para prototipado?: ${_respuestaValidacionFinal!["aprobadaParaPrototipo"] == true ? 'Sí' : 'No'}",
            "Comentario IA: ${_respuestaValidacionFinal!["comentarioFinal"] ?? '-'}",
          ]),

        _seccion("6. Conclusión", subtitulo, textoNormal, [
          "La idea ha sido procesada, iterada y validada con apoyo de IA.",
          "Se encuentra lista para ser desarrollada como prototipo con un enfoque estructurado e inteligente.",
        ]),
      ],
    ),
  );

  final bytes = await pdf.save();
  final fileName = 'informe_completo_idea.pdf';

  if (kIsWeb) {
    final base64Data = base64Encode(bytes);
    final url = "data:application/pdf;base64,$base64Data";
    // final anchor = html.AnchorElement(href: url)
    //   ..setAttribute("download", fileName)
    //   ..click();
  } else {
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$fileName");
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }
}


/*Future<void> _probarGenerarPDFSinFases() async {
  setState(() => _procesando = true);
  await Future.delayed(Duration(milliseconds: 100));
  await Future(() {}); // ⬅ deja libre el hilo de dibujo

  try {
    final pdf = pw.Document();
    final user = FirebaseAuth.instance.currentUser;
    final fecha = DateTime.now();
    final logoBytes = await rootBundle.load('assets/vortystorm.jpg');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Informe de Idea Innovadora (Demo)",
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text("Usuario: ${user?.email ?? 'demo@flow.com'}"),
                  pw.Text("Fecha: ${fecha.toLocal()}"),
                ],
              ),
              pw.Container(width: 60, height: 60, child: pw.Image(logoImage)),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, text: "1. Fase de Contexto (Demo)"),
          pw.Paragraph(text: "Contexto: Transporte rural logístico."),
          pw.Paragraph(text: "Problema: Falta de trazabilidad en zonas sin señal."),
          pw.Paragraph(text: "Causas: Fragmentación de actores, comunicación manual."),
          pw.Paragraph(text: "Herramientas: Mototaxis, papel, WhatsApp intermitente."),

          pw.Header(level: 1, text: "2. Solución Propuesta"),
          pw.Paragraph(text: "Solución: Plataforma híbrida para seguimiento logístico en áreas rurales."),
          pw.Paragraph(text: "Materiales: App offline-first + sincronización satelital."),

          pw.Header(level: 1, text: "3. Iteración IA"),
          pw.Paragraph(text: "P: ¿Cómo manejas desconexión prolongada?\nR: Se cachea localmente y se sincroniza por turnos."),
          pw.Paragraph(text: "P: ¿Cómo asegurar privacidad?\nR: Datos encriptados en reposo y en tránsito."),

          pw.Header(level: 1, text: "4. Validación"),
          pw.Paragraph(text: "Madurez: 88%"),
          pw.Paragraph(text: "¿Apta para prototipado?: Sí"),
          pw.Paragraph(text: "Comentario IA: Gran potencial para zonas rurales peruanas."),

          pw.Header(level: 1, text: "5. Conclusión"),
          pw.Paragraph(text: "La idea Flow Viataku es viable técnica y socialmente. Recomendada para piloto inicial."),
        ],
      ),
    );

    final bytes = await pdf.save();
    final fileName = 'demo_flow_viataku.pdf';

    if (kIsWeb) {
      final base64Data = base64Encode(bytes);
      final url = "data:application/pdf;base64,$base64Data";
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
    } else {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Error de test: $e")),
    );
  } finally {
    setState(() => _procesando = false);
  }
}
*/
/*ElevatedButton.icon(
  onPressed: _probarGenerarPDFSinFases,
  icon: const Icon(Icons.bug_report),
  label: const Text("🧪 Test PDF sin fases"),
  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
),*/
// Versión optimizada del build() para ProponerIdeaPage con gestión por fases y feedback visual

void _iniciarDictadoFase(int fase) async {
  final grabando = _grabandoPorFase[fase] ?? false;

  if (grabando) {
    await _speechManager.detener();
    setState(() {
      _grabandoPorFase[fase] = false;
    });
  } else {
    if (!_speechManager.isDisponible) {
      await _speechManager.inicializar();
      if (!_speechManager.isDisponible) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo acceder al micrófono")),
        );
        return;
      }
    }

    _speechManager.onUpdate = (textoParcial) {
      setState(() {
        if (fase == 1) {
          _transcripcionFase1 = textoParcial;
        } else if (fase == 2) {
          _transcripcionFase2 = textoParcial;
        }
      });
    };

    _speechManager.onFinal = (textoFinal) {
      setState(() {
        if (fase == 1) {
          _transcripcionFase1 = textoFinal;
        } else if (fase == 2) {
          _transcripcionFase2 = textoFinal;
        }
        _grabandoPorFase[fase] = false;
      });
    };

    final exito = await _speechManager.iniciar();
    if (exito) {
      _grabandoPorFase[fase] = true;
      setState(() {}); // Fuerza el redibujado para que se vea “Grabando...”
    }
  }
}



@override
Widget build(BuildContext context) {
  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      centerTitle: true,
      title: const Text("Proponer Idea Innovadora", style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/FondoCoheteNegro2.jpg', fit: BoxFit.cover),
        ),
        Container(color: Colors.black.withOpacity(0.5)),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFaseCompleta(
                titulo: "🧠 Fase 1: Exploración",
                campos: [
                  _buildField(_contextoController, "¿Dónde ocurre el problema"),
                  _buildField(_procesoController, "¿Describe el problema?"),
                  _buildField(_problemaController, " ¿Describe las causas?"),
                ],
                onGrabar: () => _iniciarDictadoFase(1),
                onImagen: () async {
                  final url = await _pickImageFromGallery();
                  if (url != null) setState(() => _imagenURL1 = url);
                },
                onEliminarImagen: _imagenURL1 != null
                    ? () => setState(() => _imagenURL1 = null)
                    : null, // solo si hay imagen
                transcripcion: _transcripcionFase1,
                imagenUrl: _imagenURL1,
                fase: 1,
              ),

              const SizedBox(height: 20),

              _buildFaseCompleta(
                titulo: "💡 Fase 2: Propuesta de Solución",
                campos: [
                  _buildField(_solucionController, "Describe tu solución."),
                  _buildField(_ataqueController, "¿Cómo atacas las causas?"),
                  _buildField(_materialesController, "¿Qué materiales o recursos es necesario?"),
                ],
                onGrabar: () => _iniciarDictadoFase(2),
                onImagen: () async {
                  final url = await _pickImageFromGallery();
                  if (url != null) setState(() => _imagenURL2 = url);
                },
                onEliminarImagen: _imagenURL2 != null
                    ? () => setState(() => _imagenURL2 = null)
                    : null,
                transcripcion: _transcripcionFase2,
                imagenUrl: _imagenURL2,
                fase: 2,
              ),
              const SizedBox(height: 30),
              botonConAyuda(
                boton: FilledButton.icon(
                  onPressed: () => ejecutarConCarga(() async => await _enviarIdea()),
                  icon: const Icon(Icons.send),
                  label: const Text("Enviar Idea para Análisis IA"),
                ),
                mensajeAyuda: "Este botón envía tu idea para que la IA la analice.",
              ),
              const SizedBox(height: 30),
              if (_respuestaIA != null) _mostrarRespuestaIA(),
              if (_respuestaIA != null && _respuestaIteracion == null)
                botonConAyuda(
                  boton: ElevatedButton(
                    onPressed: () => ejecutarConCarga(_iterarIdea),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text("Iterar Idea con IA 🤖", style: TextStyle(color: Colors.white)),
                  ),
                  mensajeAyuda: "La IA generará preguntas para mejorar tu idea.",
                ),
              if (_respuestaIteracion != null) _mostrarIteracionIA(),
              if (_respuestaIteracion != null && !_mostrandoFormularioRespuestas && !_respuestasGuardadas)
                botonConAyuda(
                  boton: ElevatedButton(
                    onPressed: () {
                      final preguntas = List<String>.from(_respuestaIteracion!["preguntasIterativas"] ?? []);
                      _respuestaControllers.clear();
                      for (var _ in preguntas) {
                        _respuestaControllers.add(TextEditingController());
                      }
                      setState(() => _mostrandoFormularioRespuestas = true);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    child: const Text("Responder Iteración IA ✍️", style: TextStyle(color: Colors.white)),
                  ),
                  mensajeAyuda: "Responde a las preguntas generadas por la IA.",
                ),
              if (_mostrandoFormularioRespuestas) _formularioRespuestasIA(),
              if (_respuestasGuardadas)
                botonConAyuda(
                  boton: ElevatedButton(
                    onPressed: () => ejecutarConCarga(_validarRespuestasIA),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Validar respuestas con IA ✅", style: TextStyle(color: Colors.white)),
                  ),
                  mensajeAyuda: "Valida tus respuestas con la IA.",
                ),
              if (_respuestaValidacionFinal != null) _mostrarValidacionFinal(),
              if (_respuestaValidacionFinal != null && _respuestaValidacionFinal!["aprobadaParaPrototipo"] == true)
                botonConAyuda(
                  boton: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CrearProyectoDesdeIdeaPage(
                            ideaId: _ideaRef!.id,
                            resumenProblema: _respuestaIA?["resumenProblema"] ?? "",
                            resumenSolucion: _respuestaIA?["resumenSolucion"] ?? "",
                            comentarioFinal: _respuestaValidacionFinal?["comentarioFinal"] ?? "",
                            tituloz: _respuestaIA?["titulo"] ?? "",
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    child: const Text("🚀 Crear Proyecto", style: TextStyle(color: Colors.white)),
                  ),
                  mensajeAyuda: "Crea un proyecto a partir de esta idea.",
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
Widget _buildFaseCompleta({
  required String titulo,
  required List<Widget> campos,
  required VoidCallback onGrabar,
  required VoidCallback onImagen,
  required VoidCallback? onEliminarImagen, // 🔥 nuevo
  required String transcripcion,
  required String? imagenUrl,
  required int fase,
}) {
  return _buildCard(
    titulo,
    campos: [
      ...campos,
      const SizedBox(height: 12),

      // 🎤 Botones de voz e imagen
      Row(
        children: [
          ElevatedButton.icon(
            onPressed: onGrabar,
            icon: Icon(_grabandoPorFase[fase] == true ? Icons.stop_circle : Icons.mic),
            label: Text(_grabandoPorFase[fase] == true ? "Detener Voz" : "Dictar por Voz"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _grabandoPorFase[fase] == true ? Colors.red : Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onImagen,
            icon: const Icon(Icons.image),
            label: const Text("Agregar Imagen"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),

      // 🔴 Indicador de grabación
      if (_grabandoPorFase[fase] == true) ...[
        const SizedBox(height: 8),
        Row(
          children: const [
            Icon(Icons.circle, color: Colors.redAccent, size: 12),
            SizedBox(width: 6),
            Text("Grabando...", style: TextStyle(color: Colors.redAccent)),
          ],
        ),
      ],

      // 🗣 Texto dictado
      if (transcripcion.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24),
          ),
          child: Text("🗣 $transcripcion", style: const TextStyle(color: Colors.white70)),
        ),
      ],

      // 🖼 Imagen + botón eliminar
      if (imagenUrl != null) ...[
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(imagenUrl, height: 120),
            ),
            if (onEliminarImagen != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                onPressed: onEliminarImagen,
                tooltip: 'Eliminar imagen',
              ),
          ],
        ),
      ],
    ],
  );
}


Widget _buildField(TextEditingController controller, String label) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: TextFormField(
      controller: controller,
      maxLines: null,
      validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurpleAccent),
        ),
      ),
    ),
  );
}

Widget _mostrarIteracionIA() {
    final preguntas = List<String>.from(_respuestaIteracion?["preguntasIterativas"] ?? []);
    final riesgos = List<String>.from(_respuestaIteracion?["riesgosDetectados"] ?? []);
    final acciones = List<String>.from(_respuestaIteracion?["accionesRecomendadas"] ?? []);

    return Container(
      margin: const EdgeInsets.only(top: 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "🔄 Fase de Iteración IA",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "📊 Madurez estimada: ${_respuestaIteracion!["madurez"] ?? "-"}%",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                const Text(
                  "❓ Preguntas clave para refinar la idea:",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                ...preguntas.map((q) => Text("• $q", style: const TextStyle(color: Colors.white))),
                const SizedBox(height: 16),
                const Text(
                  "⚠️ Riesgos detectados:",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent),
                ),
                ...riesgos.map((r) => Text("- $r", style: const TextStyle(color: Colors.amber))),
                const SizedBox(height: 16),
                const Text(
                  "✅ Acciones recomendadas:",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),
                ),
                ...acciones.map((a) => Text("+ $a", style: const TextStyle(color: Colors.greenAccent))),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _formularioRespuestasIA() {
  final preguntas = List<String>.from(_respuestaIteracion?["preguntasIterativas"] ?? []);

  return Container(
    margin: const EdgeInsets.only(top: 30),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "✍️ Responde a las preguntas de la iteración IA",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < preguntas.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: TextFormField(
                    controller: _respuestaControllers[i],
                    maxLines: null,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: preguntas[i],
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => ejecutarConCarga(_guardarRespuestasIteracion),  
                icon: const Icon(Icons.save),
                label: const Text("Guardar respuestas IA ✅"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade400,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget botonConAyuda({
  required Widget boton,
  required String mensajeAyuda,
  }) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      boton,
      const SizedBox(width: 8),
      IconButton(
        icon: const Icon(Icons.help_outline, color: Colors.white70),
        onPressed: () {
          showDialog(
            context: _formKey.currentContext!, // Usa el mismo _formKey que ya tienes
            builder: (context) => AlertDialog(
              title: const Text("¿Para qué sirve este botón?"),
              content: Text(mensajeAyuda),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Entendido"),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

Widget _mostrarRespuestaIA() {
  return Container(
    margin: const EdgeInsets.only(top: 20),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🧠 Resumen del Problema",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              Text(_respuestaIA!["resumenProblema"] ?? "-", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 14),

              const Text(
                "💡 Resumen de la Solución",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              Text(_respuestaIA!["resumenSolucion"] ?? "-", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 14),

              const Text(
                "✅ Evaluación",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.lightGreenAccent),
              ),
              Text(_respuestaIA!["evaluacion"] ?? "-", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 14),

              const Text(
                "🛠 Sugerencias",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orangeAccent),
              ),
              Text(_respuestaIA!["sugerencias"] ?? "-", style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    ),
  );
}

}

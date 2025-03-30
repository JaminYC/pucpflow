// 📄 ProponerIdeaPage.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/CrearProyectoDesdeIdeaPage.dart' show CrearProyectoDesdeIdeaPage;
import 'idea.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
/// Solo en Web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;


class ProponerIdeaPage extends StatefulWidget {
  const ProponerIdeaPage({super.key});

  @override
  State<ProponerIdeaPage> createState() => _ProponerIdeaPageState();
}

class _ProponerIdeaPageState extends State<ProponerIdeaPage> {
  final _formKey = GlobalKey<FormState>();

  final _contextoController = TextEditingController();
  final _procesoController = TextEditingController();
  final _problemaController = TextEditingController();
  final _causasController = TextEditingController();
  final _herramientasController = TextEditingController();
  final _solucionController = TextEditingController();
  final _ataqueController = TextEditingController();
  final _materialesController = TextEditingController();

  bool _procesando = false;
  Map<String, dynamic>? _respuestaIA;
  Map<String, dynamic>? _respuestaIteracion;
  Map<String, dynamic>? _respuestaValidacionFinal;
  DocumentReference? _ideaRef;

  final List<TextEditingController> _respuestaControllers = [];
  bool _mostrandoFormularioRespuestas = false;
  bool _respuestasGuardadas = false;

  @override
  void dispose() {
    _contextoController.dispose();
    _procesoController.dispose();
    _problemaController.dispose();
    _causasController.dispose();
    _herramientasController.dispose();
    _solucionController.dispose();
    _ataqueController.dispose();
    _materialesController.dispose();
    for (var c in _respuestaControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enviarIdea() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _procesando = true);

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
      _ideaRef = await FirebaseFirestore.instance.collection('ideas').add({
        ...idea.toJson(),
        'estado': 'pendiente',
        'timestamp': FieldValue.serverTimestamp(),
      });

      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('analizarIdea');
      final result = await callable.call(idea.toJson());

      setState(() => _respuestaIA = result.data);

      await _ideaRef!.update({
        'estado': 'analizada',
        'resultadoIA': result.data,
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al procesar con IA: $e')),
      );
    } finally {
      setState(() => _procesando = false);
    }
  }

  Future<void> _iterarIdea() async {
    if (_respuestaIA == null) return;

    setState(() => _procesando = true);
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('iterarIdea');
      final result = await callable.call({
        'resumenProblema': _respuestaIA!["resumenProblema"] ?? '',
        'resumenSolucion': _respuestaIA!["resumenSolucion"] ?? '',
        'evaluacion': _respuestaIA!["evaluacion"] ?? '',
      });
      setState(() => _respuestaIteracion = result.data);

      if (_ideaRef != null) {
        await _ideaRef!.update({
          'faseIteracion': result.data,
        });
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
  }

  Future<void> _validarRespuestasIA() async {
    if (_ideaRef == null || _respuestaIteracion == null || _respuestaIA == null) return;

    setState(() => _procesando = true);
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
Future<void> _exportarPDF() async {
  final pdf = pw.Document();
  final user = FirebaseAuth.instance.currentUser;
  final fecha = DateTime.now();

  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("📄 Informe de Idea Innovadora", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          if (user != null) pw.Text("👤 Usuario: ${user.email ?? user.uid}"),
          pw.Text("🗓 Fecha: ${fecha.toLocal()}"),
          pw.SizedBox(height: 10),
          pw.Text("🧠 Problema: ${_respuestaIA?["resumenProblema"] ?? ""}"),
          pw.Text("💡 Solución: ${_respuestaIA?["resumenSolucion"] ?? ""}"),
          pw.SizedBox(height: 10),
          pw.Text("✅ Evaluación IA: ${_respuestaIA?["evaluacion"] ?? ""}"),
          pw.SizedBox(height: 10),
          if (_respuestaValidacionFinal != null)
            pw.Text("📋 Comentario Final IA: ${_respuestaValidacionFinal!["comentarioFinal"] ?? ""}"),
          pw.SizedBox(height: 10),
          if (_respuestaIteracion != null && _respuestaControllers.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("✍️ Respuestas a la Iteración IA:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ...List.generate(_respuestaControllers.length, (i) {
                  final pregunta = _respuestaIteracion?["preguntasIterativas"]?[i] ?? "";
                  final respuesta = _respuestaControllers[i].text;
                  return pw.Bullet(text: "$pregunta → $respuesta");
                }),
              ],
            ),
        ],
      ),
    ),
  );

  final bytes = await pdf.save();
  final fileName = 'idea_innovadora_${_ideaRef?.id ?? "sin_id"}.pdf';

  if (kIsWeb) {
    // 🟢 WEB: descarga automática
    final base64Data = base64Encode(bytes);
    final url = "data:application/pdf;base64,$base64Data";
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
  } else {
    // 📱 Móvil o escritorio: compartir
    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Proponer Idea Innovadora"),
        backgroundColor: Colors.blue[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("🧠 Fase 1: Exploración de la Idea", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              _buildField(_contextoController, "¿A qué parte del proceso corresponde la idea?"),
              _buildField(_procesoController, "¿En qué etapa específica del proceso se presenta la dificultad identificada?"),
              _buildField(_problemaController, "¿Cómo describirías el problema con el mayor detalle posible? (Incluye evidencias y ejemplos concretos si es posible)."),
              _buildField(_causasController, "¿Cuáles consideras que son las principales causas de este problema?"),
              _buildField(_herramientasController, "¿Qué materiales, herramientas, maquinaria o componentes mecánicos están involucrados en el problema?"),
              const Divider(height: 40),
              const Text("💡 Fase 2: Propuesta de Solución", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              _buildField(_solucionController, "¿Cuál es la solución que propones para abordar este problema? Descríbela con claridad."),
              _buildField(_ataqueController, "¿De qué manera tu solución propuesta ataca directamente las causas principales del problema y mejora la operación actual?"),
              _buildField(_materialesController, "¿Qué nuevos materiales, herramientas, maquinarias, partes mecánicas, software serán necesarios para implementar tú solución?"),
              const SizedBox(height: 20),
              _procesando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _enviarIdea,
                      child: const Text("Enviar Idea para Análisis IA"),
                    ),
              const SizedBox(height: 30),
              if (_respuestaIA != null) _mostrarRespuestaIA(),
              if (_respuestaIA != null && _respuestaIteracion == null)
                ElevatedButton(
                  onPressed: _iterarIdea,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text("Iterar Idea con IA 🤖",style: TextStyle(color: Color.fromARGB(255, 253, 253, 253),),),
                ),
              if (_respuestaIteracion != null) _mostrarIteracionIA(),
              if (_respuestaIteracion != null && !_mostrandoFormularioRespuestas && !_respuestasGuardadas)
                ElevatedButton(
                  onPressed: () {
                    final preguntas = List<String>.from(_respuestaIteracion!["preguntasIterativas"] ?? []);
                    _respuestaControllers.clear();
                    for (var _ in preguntas) {
                      _respuestaControllers.add(TextEditingController());
                    }
                    setState(() => _mostrandoFormularioRespuestas = true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: const Text("Responder Iteración IA ✍️",style: TextStyle(color: Color.fromARGB(255, 253, 253, 253),),),
                ),
              if (_mostrandoFormularioRespuestas) _formularioRespuestasIA(),
              if (_respuestasGuardadas)
                ElevatedButton(
                  onPressed: _validarRespuestasIA,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Validar respuestas con IA ✅",style: TextStyle(color: Color.fromARGB(255, 253, 253, 253),),),

                ),
              if (_respuestaValidacionFinal != null) _mostrarValidacionFinal(),
              if (_respuestaValidacionFinal != null && _respuestaValidacionFinal!["aprobadaParaPrototipo"] == true)
              ElevatedButton(
                  onPressed: () {
                    if (_ideaRef != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CrearProyectoDesdeIdeaPage(
                            ideaId: _ideaRef!.id,
                            resumenProblema: _respuestaIA?["resumenProblema"] ?? "",
                            resumenSolucion: _respuestaIA?["resumenSolucion"] ?? "",
                            comentarioFinal: _respuestaValidacionFinal?["comentarioFinal"] ?? "",
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("⚠️ La idea aún no está registrada")),
                      );
                    }
                  },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text("🚀 Crear Proyecto desde esta Idea",style: TextStyle(color: Color.fromARGB(255, 253, 253, 253),),),
              ),

            // También puedes agregar un botón extra para generar PDF:
            if (_respuestaValidacionFinal != null)
              ElevatedButton(
                onPressed: _exportarPDF,

                style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                child: const Text("📄 Exportar Informe PDF",style: TextStyle(color: Color.fromARGB(255, 253, 253, 253),),),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        maxLines: null,
        validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _mostrarIteracionIA() {
    final preguntas = List<String>.from(_respuestaIteracion?["preguntasIterativas"] ?? []);
    final riesgos = List<String>.from(_respuestaIteracion?["riesgosDetectados"] ?? []);
    final acciones = List<String>.from(_respuestaIteracion?["accionesRecomendadas"] ?? []);

    return Card(
      color: Colors.indigo[50],
      margin: const EdgeInsets.only(top: 30),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🔄 Fase de Iteración IA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text("📊 Madurez estimada: ${_respuestaIteracion!["madurez"] ?? "-"}%"),
            const SizedBox(height: 10),
            const Text("❓ Preguntas clave para refinar la idea:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...preguntas.map((q) => Text("• $q")),
            const SizedBox(height: 10),
            const Text("⚠️ Riesgos detectados:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...riesgos.map((r) => Text("- $r")),
            const SizedBox(height: 10),
            const Text("✅ Acciones recomendadas:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...acciones.map((a) => Text("+ $a")),
          ],
        ),
      ),
    );
  }

  Widget _formularioRespuestasIA() {
    final preguntas = List<String>.from(_respuestaIteracion?["preguntasIterativas"] ?? []);

    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("✍️ Responde a las preguntas de la iteración IA", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          for (int i = 0; i < preguntas.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextFormField(
                controller: _respuestaControllers[i],
                maxLines: null,
                decoration: InputDecoration(
                  labelText: preguntas[i],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _guardarRespuestasIteracion,
            child: const Text("Guardar respuestas IA ✅"),
          ),
        ],
      ),
    );
  }

  Widget _mostrarRespuestaIA() {
    return Card(
      color: Colors.grey[100],
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🧠 Resumen del Problema", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_respuestaIA!["resumenProblema"] ?? "-"),
            const SizedBox(height: 10),
            const Text("💡 Resumen de la Solución", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_respuestaIA!["resumenSolucion"] ?? "-"),
            const SizedBox(height: 10),
            const Text("✅ Evaluación", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_respuestaIA!["evaluacion"] ?? "-"),
            const SizedBox(height: 10),
            const Text("🛠 Sugerencias", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_respuestaIA!["sugerencias"] ?? "-"),
          ],
        ),
      ),
    );
  }
}

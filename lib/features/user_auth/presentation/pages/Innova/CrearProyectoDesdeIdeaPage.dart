// 📄 CrearProyectoDesdeIdeaPage.dart
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pucpflow/features/user_auth/tarea_service.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:io';


class CrearProyectoDesdeIdeaPage extends StatefulWidget {
  final String ideaId;
  final String resumenSolucion;
  final String resumenProblema;
  final String comentarioFinal;

  const CrearProyectoDesdeIdeaPage({
    super.key,
    required this.ideaId,
    required this.resumenSolucion,
    required this.resumenProblema,
    required this.comentarioFinal,
  });

  @override
  State<CrearProyectoDesdeIdeaPage> createState() => _CrearProyectoDesdeIdeaPageState();
}

class _CrearProyectoDesdeIdeaPageState extends State<CrearProyectoDesdeIdeaPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  bool esPublico = true;
  bool creando = false;
  List<Map<String, dynamic>> tareasSinResponsables = [];


  Future<void> _crearProyectoConTareas() async {
    setState(() => creando = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("Usuario no autenticado");

      final functions = FirebaseFunctions.instance;
      final generar = functions.httpsCallable('generarTareasDesdeIdea');
      final result = await generar.call({
        'resumenProblema': widget.resumenProblema,
        'resumenSolucion': widget.resumenSolucion,
        'comentarioFinal': widget.comentarioFinal,
      });

      final tareas = result.data['tareas'];

      tareasSinResponsables = tareas.map<Map<String, dynamic>>((t) {
        return {
          ...t,
          'responsables': [],
          'completado': false,
          'tipoTarea': 'Libre',
          'colorId': 1,
          'fecha': null,
          'prioridad': 2,
          'requisitos': {},
        };
      }).toList();

      final docRef = FirebaseFirestore.instance.collection('proyectos').doc();
      await docRef.set({
        'id': docRef.id,
        'nombre': nombreController.text,
        'descripcion': descripcionController.text,
        'fechaInicio': DateTime.now().toIso8601String(),
        'ideaId': widget.ideaId,
        'publico': esPublico,
        'visibilidad': esPublico ? 'Publico' : 'Privado',
        'propietario': uid,
        'participantes': [uid],
        'imagenUrl': 'https://firebasestorage.googleapis.com/v0/b/pucp-flow.firebasestorage.app/o/proyecto_imagenes%2Fimagen_por_defecto.jpg?alt=media&token=67db12bf-0ce4-4697-98f3-3c6126467595',
                'tareas': tareasSinResponsables.map((t) => {
          ...t,
          'tipoTarea': 'Libre',
          'colorId': 1,
          'completado': false,
        }).toList(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Proyecto creado con tareas libres")),
      );

      await showDialog(
      context: context,
      builder: (context) => AlertDialog(
              title: const Text("🎉 Proyecto Creado Exitosamente!"),
              content: const Text("El proyecto ha sido creado. Las tareas están disponibles para ser asignadas."),
              actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _exportarPDF();
            },
            child: const Text("📄 Exportar PDF"),
          ),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/proyectos'),
            child: const Text("Ir a Mis Proyectos"),
          ),

              ],
            ));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    } finally {
      setState(() => creando = false);
    }
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
          pw.Text("📄 Informe de Idea y Proyecto", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          if (user != null) pw.Text("👤 Usuario: ${user.email ?? user.uid}"),
          pw.Text("🗓 Fecha: ${fecha.toLocal()}"),
          pw.SizedBox(height: 10),
          pw.Text("🧠 Problema: ${widget.resumenProblema}"),
          pw.Text("💡 Solución: ${widget.resumenSolucion}"),
          pw.SizedBox(height: 10),
          pw.Text("📝 Comentario Final IA: ${widget.comentarioFinal}"),
          pw.SizedBox(height: 10),
          pw.Text("📌 Nombre del Proyecto: ${nombreController.text}"),
          pw.Text("📄 Descripción: ${descripcionController.text}"),
          pw.Text("🔓 Visibilidad: ${esPublico ? 'Público' : 'Privado'}"),
          pw.SizedBox(height: 20),
          pw.Text("📋 Tareas Generadas:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ...tareasSinResponsables.map((t) =>
              pw.Bullet(text: "${t['titulo']} (${t['dificultad']} – ${t['duracionHoras']}h)")),
        ],
      ),
    ),
  );

  final bytes = await pdf.save();
  final fileName = 'proyecto_idea_${DateTime.now().millisecondsSinceEpoch}.pdf';

  if (kIsWeb) {
    // 🔽 WEB: Descargar automáticamente
    final base64Data = base64Encode(bytes);
    final url = "data:application/pdf;base64,$base64Data";
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
  } else {
    // 📱 Móvil/escritorio: Mostrar opciones
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Qué deseas hacer con el PDF?'),
        content: const Text('Puedes imprimirlo, compartirlo o abrirlo desde tus descargas.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Printing.layoutPdf(onLayout: (format) async => bytes);
            },
            child: const Text('🖨 Imprimir'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Printing.sharePdf(
                bytes: bytes,
                filename: fileName,
              );
            },
            child: const Text('📤 Compartir'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final dir = await getTemporaryDirectory();
              final file = File('${dir.path}/$fileName');
              await file.writeAsBytes(bytes);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("📁 PDF guardado localmente")),
              );
            },
            child: const Text('📁 Guardar como archivo'),
          ),
        ],
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    descripcionController.text = widget.resumenSolucion;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🚀 Crear Proyecto desde Idea"),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: _exportarPDF,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🧠 Idea Base", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Problema: ${widget.resumenProblema}"),
            const SizedBox(height: 10),
            Text("Solución: ${widget.resumenSolucion}"),
            const Divider(height: 30),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: "Nombre del Proyecto"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descripcionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Descripción"),
            ),
            SwitchListTile(
              title: const Text("¿Proyecto Público?"),
              value: esPublico,
              onChanged: (value) => setState(() => esPublico = value),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: creando ? null : _crearProyectoConTareas,
              icon: const Icon(Icons.check_circle),
              label: Text(creando ? "Creando..." : "Crear Proyecto y Generar Tareas"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            )
          ],
        ),
      ),
    );
  }
}

// 📄 CrearProyectoDesdeIdeaPage.dart
import 'dart:io' show File;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pucpflow/features/user_auth/tarea_service.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
//ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;
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
    final prefs = await SharedPreferences.getInstance();

    final user = FirebaseAuth.instance.currentUser;
    final nombre = prefs.getString('empresaNombre') ?? user?.email ?? 'CERRO VERDE';

    if (nombre.isEmpty) {
      throw Exception("No se pudo identificar al usuario");
    }

    final functions = FirebaseFunctions.instance;
    final generar = functions.httpsCallable('generarTareasDesdeIdea');
    final result = await generar.call({
      'resumenProblema': widget.resumenProblema,
      'resumenSolucion': widget.resumenSolucion,
      'comentarioFinal': widget.comentarioFinal,
    });

    final tareas = result.data['tareas'];

    tareasSinResponsables = List<Map<String, dynamic>>.from(tareas.map((t) {
      final tareaMap = Map<String, dynamic>.from(t as Map); // Cast explícito
      return {
        ...tareaMap,
        'responsables': [],
        'completado': false,
        'tipoTarea': 'Libre',
        'colorId': 1,
        'fecha': null,
        'prioridad': 2,
        'requisitos': {},
      };
    }));
    
    final docRef = FirebaseFirestore.instance.collection('proyectos').doc();
    await docRef.set({
      'id': docRef.id,
      'nombre': nombreController.text,
      'descripcion': descripcionController.text,
      'fechaInicio': DateTime.now().toIso8601String(),
      'ideaId': widget.ideaId,
      'publico': esPublico,
      'visibilidad': esPublico ? 'Publico' : 'Privado',
      'propietario': nombre,
      'participantes': [nombre],
      'imagenUrl':
          'https://firebasestorage.googleapis.com/v0/b/pucp-flow.firebasestorage.app/o/proyecto_imagenes%2Fimagen_por_defecto.jpg?alt=media&token=67db12bf-0ce4-4697-98f3-3c6126467595',
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
      ),
    );
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
  final fecha = DateTime.now();

  // Cargar logo
  final logoBytes = await rootBundle.load('assets/vortystorm.jpg');
  final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

  // Estilos
  final tituloPrincipal = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold);
  final subtitulo = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
  final textoNormal = pw.TextStyle(fontSize: 12);

  // Obtener nombre del usuario o empresa
  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;
  final nombre = prefs.getString("empresaNombre") ?? user?.email ?? "CERRO VERDE";

  // Página principal
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
        // Encabezado
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Informe de Proyecto Generado", style: tituloPrincipal),
                pw.SizedBox(height: 10),
                pw.Text("Usuario: $nombre", style: textoNormal),
                pw.Text("Fecha: ${fecha.toLocal()}", style: textoNormal),
              ],
            ),
            pw.Container(width: 60, height: 60, child: pw.Image(logoImage)),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 16),

        // Información base
        _seccionPDF("1. Información Base", subtitulo, textoNormal, [
          "Problema: ${widget.resumenProblema}",
          "Solución: ${widget.resumenSolucion}",
          "Comentario Final IA: ${widget.comentarioFinal}",
        ]),

        // Proyecto
        _seccionPDF("2. Proyecto Generado", subtitulo, textoNormal, [
          "Nombre del Proyecto: ${nombreController.text}",
          "Descripción: ${descripcionController.text}",
          "Visibilidad: ${esPublico ? 'Público' : 'Privado'}",
        ]),

        // Tareas
        pw.Text("3. Tareas Generadas", style: subtitulo),
        pw.Divider(),
        pw.SizedBox(height: 8),

        ...tareasSinResponsables.map((t) {
          final dificultad = (t['dificultad'] ?? 'Media') as String;
          final duracion = (t['duracionHoras'] ?? 1).toDouble();

          int factor;
          switch (dificultad.toLowerCase()) {
            case 'alta': factor = 3; break;
            case 'media': factor = 2; break;
            case 'baja': factor = 1; break;
            default: factor = 2;
          }

          final esfuerzo = duracion * factor;
          final costo = esfuerzo * 10;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              "- ${t['titulo']} | Dificultad: $dificultad | Duración: ${duracion}h | Esfuerzo: $esfuerzo | Costo estimado: S/.${costo.toStringAsFixed(2)}",
              style: textoNormal,
              textAlign: pw.TextAlign.justify,
            ),
          );
        }),

        pw.SizedBox(height: 20),
        pw.Text("4. Conclusión", style: subtitulo),
        pw.Divider(),
        pw.Text(
          "Este proyecto fue generado automáticamente a partir de una idea evaluada con IA. Las tareas propuestas están listas para ser asignadas, priorizadas o ajustadas por el equipo.",
          style: textoNormal,
          textAlign: pw.TextAlign.justify,
        ),
      ],
    ),
  );

  // Guardar y mostrar PDF
  final bytes = await pdf.save();
  final fileName = 'proyecto_generado_${DateTime.now().millisecondsSinceEpoch}.pdf';

  if (kIsWeb) {
    final base64Data = base64Encode(bytes);
    final url = "data:application/pdf;base64,$base64Data";
    // final anchor = html.AnchorElement(href: url)
    //   ..setAttribute("download", fileName)
    //   ..click();
  } else {
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
              await Printing.sharePdf(bytes: bytes, filename: fileName);
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


pw.Widget _seccionPDF(String titulo, pw.TextStyle titleStyle, pw.TextStyle bodyStyle, List<String> contenido) {
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





@override
Widget build(BuildContext context) {
  descripcionController.text = widget.resumenSolucion;

  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      title: const Text("🚧 Crear Proyecto desde Idea", style: TextStyle(color: Colors.white)),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: Stack(
      children: [
        // Fondo
        Positioned.fill(
          child: Image.asset(
            'assets/FondoCoheteNegro2.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Container(color: Colors.black.withOpacity(0.5)),

        // Contenido principal
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard("🧠 Idea Base", [
                Text("• Problema: ${widget.resumenProblema}",
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text("• Solución: ${widget.resumenSolucion}",
                    style: const TextStyle(color: Colors.white70)),
              ]),
              const SizedBox(height: 20),

              _buildCard("🛠 Detalles del Proyecto", [
                _buildField(nombreController, "Nombre del Proyecto"),
                _buildField(descripcionController, "Descripción del Proyecto"),
                SwitchListTile(
                  title: const Text("¿Proyecto Público?",
                      style: TextStyle(color: Colors.white)),
                  value: esPublico,
                  onChanged: (v) => setState(() => esPublico = v),
                  secondary: Icon(esPublico ? Icons.public : Icons.lock, color: Colors.white),
                  contentPadding: EdgeInsets.zero,
                ),
              ]),

              const SizedBox(height: 30),

              Center(
                child: ElevatedButton.icon(
                  onPressed: creando ? null : _crearProyectoConTareas,
                  icon: const Icon(Icons.task_alt),
                  label: Text(creando ? "Creando Proyecto..." : "✅ Crear Proyecto y Generar Tareas"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),

        // GIF animado mientras carga
        if (creando)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: ClipOval(
                  child: Image.asset(
                    'assets/animation.gif',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _buildCard(String titulo, List<Widget> campos) {
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
                  color: Color(0xFFF1F1F1), // Blanco suave
                ),
              ),
              const SizedBox(height: 12),
              ...campos
            ],
          ),
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
      style: const TextStyle(color: Colors.white), // 🟢 Texto ingresado en blanco
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70), // 🟣 Preguntas en blanco tenue
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


}

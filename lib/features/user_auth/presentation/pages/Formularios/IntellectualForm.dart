import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IntellectualForm extends StatefulWidget {
  final String userId;

  const IntellectualForm({Key? key, required this.userId}) : super(key: key);

  @override
  State<IntellectualForm> createState() => _IntellectualFormState();
}

class _IntellectualFormState extends State<IntellectualForm> {
  final _formKey = GlobalKey<FormState>();
  String _studyMethod = "Visual";
  double _technologySkill = 5.0;
  String _favoriteApps = "";
  int _studyHours = 2;
  String _learningGoal = "Mejorar habilidades técnicas";
  String _preferredContentFormat = "Videos";

  Future<void> _saveIntellectualData() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'metodoEstudio': _studyMethod,
        'habilidadTecnologica': _technologySkill,
        'appsFavoritas': _favoriteApps.split(',').map((e) => e.trim()).toList(),
        'horasEstudio': _studyHours,
        'objetivoAprendizaje': _learningGoal,
        'formatoContenidoPreferido': _preferredContentFormat,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Datos intelectuales guardados correctamente")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al guardar datos: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🧠 Bienestar Intelectual"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveIntellectualData,
        label: const Text("Guardar"),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("📚 Método de estudio preferido:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _studyMethod,
                items: const [
                  DropdownMenuItem(value: "Visual", child: Text("👀 Visual")),
                  DropdownMenuItem(value: "Auditivo", child: Text("🎧 Auditivo")),
                  DropdownMenuItem(value: "Kinestésico", child: Text("👐 Kinestésico")),
                ],
                onChanged: (value) => setState(() => _studyMethod = value!),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              const Text("💻 Nivel de habilidad tecnológica (1-10):", style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _technologySkill,
                min: 1,
                max: 10,
                divisions: 9,
                label: _technologySkill.round().toString(),
                onChanged: (value) => setState(() => _technologySkill = value),
                activeColor: Colors.black,
                inactiveColor: Colors.black26,
              ),
              const SizedBox(height: 20),

              const Text("🌟 Apps favoritas (separadas por coma):", style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: "Ej: Notion, Google Drive, Canva",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _favoriteApps = value,
              ),
              const SizedBox(height: 20),

              const Text("⏱️ Horas de estudio diarias:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _studyHours,
                items: List.generate(10, (index) => DropdownMenuItem(value: index + 1, child: Text("${index + 1} horas"))),
                onChanged: (value) => setState(() => _studyHours = value!),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              const Text("🎯 Objetivo principal de aprendizaje:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _learningGoal,
                items: const [
                  DropdownMenuItem(value: "Mejorar habilidades técnicas", child: Text("Mejorar habilidades técnicas")),
                  DropdownMenuItem(value: "Preparación para exámenes", child: Text("Preparación para exámenes")),
                  DropdownMenuItem(value: "Aprender algo nuevo", child: Text("Aprender algo nuevo")),
                  DropdownMenuItem(value: "Mejorar productividad", child: Text("Mejorar productividad")),
                ],
                onChanged: (value) => setState(() => _learningGoal = value!),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              const Text("📖 Formato de contenido preferido:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _preferredContentFormat,
                items: const [
                  DropdownMenuItem(value: "Videos", child: Text("🎥 Videos")),
                  DropdownMenuItem(value: "Artículos", child: Text("📄 Artículos")),
                  DropdownMenuItem(value: "Libros", child: Text("📚 Libros")),
                  DropdownMenuItem(value: "Podcasts", child: Text("🎧 Podcasts")),
                ],
                onChanged: (value) => setState(() => _preferredContentFormat = value!),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

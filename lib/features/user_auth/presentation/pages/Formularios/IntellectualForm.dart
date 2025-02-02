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

  // Campos del formulario
  String _studyMethod = "Visual";
  double _technologySkill = 5.0;
  String _favoriteApps = "";
  int _studyHours = 2; // Nuevas preguntas
  String _learningGoal = "Mejorar habilidades técnicas";
  String _preferredContentFormat = "Videos";

  Future<void> _saveIntellectualData() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'intellectual': {
          'study_method': _studyMethod,
          'technology_skill': _technologySkill,
          'favorite_apps': _favoriteApps,
          'study_hours': _studyHours,
          'learning_goal': _learningGoal,
          'preferred_content_format': _preferredContentFormat,
        },
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
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveIntellectualData,
        label: const Text("Guardar"),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.indigo,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Método de estudio preferido
              const Text(
                "📚 Método de estudio preferido:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _studyMethod,
                items: const [
                  DropdownMenuItem(value: "Visual", child: Text("👀 Visual")),
                  DropdownMenuItem(value: "Auditivo", child: Text("🎧 Auditivo")),
                  DropdownMenuItem(value: "Kinestésico", child: Text("👐 Kinestésico")),
                ],
                onChanged: (value) {
                  setState(() {
                    _studyMethod = value!;
                  });
                },
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Nivel de habilidad tecnológica
              const Text(
                "💻 Nivel de habilidad tecnológica (1-10):",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _technologySkill,
                min: 1,
                max: 10,
                divisions: 9,
                label: _technologySkill.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _technologySkill = value;
                  });
                },
                activeColor: Colors.indigo,
                inactiveColor: Colors.indigo.withOpacity(0.4),
              ),
              const SizedBox(height: 20),

              // Apps favoritas
              const Text(
                "🌟 Apps favoritas:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Apps favoritas",
                  hintText: "Ejemplo: Notion, Google Drive, Canva",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _favoriteApps = value;
                },
              ),
              const SizedBox(height: 20),

              // Horas de estudio diarias
              const Text(
                "⏱️ Horas de estudio diarias:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<int>(
                value: _studyHours,
                items: List.generate(10, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text("${index + 1} horas"),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    _studyHours = value!;
                  });
                },
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Objetivo de aprendizaje
              const Text(
                "🎯 Objetivo principal de aprendizaje:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _learningGoal,
                items: const [
                  DropdownMenuItem(value: "Mejorar habilidades técnicas", child: Text("Mejorar habilidades técnicas")),
                  DropdownMenuItem(value: "Preparación para exámenes", child: Text("Preparación para exámenes")),
                  DropdownMenuItem(value: "Aprender algo nuevo", child: Text("Aprender algo nuevo")),
                  DropdownMenuItem(value: "Mejorar productividad", child: Text("Mejorar productividad")),
                ],
                onChanged: (value) {
                  setState(() {
                    _learningGoal = value!;
                  });
                },
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Formato de contenido preferido
              const Text(
                "📖 Formato de contenido preferido:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _preferredContentFormat,
                items: const [
                  DropdownMenuItem(value: "Videos", child: Text("🎥 Videos")),
                  DropdownMenuItem(value: "Artículos", child: Text("📄 Artículos")),
                  DropdownMenuItem(value: "Libros", child: Text("📚 Libros")),
                  DropdownMenuItem(value: "Podcasts", child: Text("🎧 Podcasts")),
                ],
                onChanged: (value) {
                  setState(() {
                    _preferredContentFormat = value!;
                  });
                },
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // Botón para guardar
              ElevatedButton.icon(
                onPressed: _saveIntellectualData,
                icon: const Icon(Icons.save),
                label: const Text("Guardar y continuar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

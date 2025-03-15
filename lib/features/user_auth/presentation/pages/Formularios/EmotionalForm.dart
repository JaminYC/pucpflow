import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmotionalForm extends StatefulWidget {
  final String userId;

  const EmotionalForm({Key? key, required this.userId}) : super(key: key);

  @override
  State<EmotionalForm> createState() => _EmotionalFormState();
}

class _EmotionalFormState extends State<EmotionalForm> {
  final _formKey = GlobalKey<FormState>();
  double _stressLevel = 5.0;
  String _mood = "Neutral";

  Future<void> _saveEmotionalData() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'nivelEstres': _stressLevel,
        'estadoAnimo': _mood,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("💖 Datos emocionales guardados correctamente")),
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
        title: const Text("💖 Bienestar Emocional"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveEmotionalData,
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
              const Text(
                "🧘‍♀️ Nivel de estrés (1-10):",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _stressLevel,
                min: 1,
                max: 10,
                divisions: 9,
                label: _stressLevel.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _stressLevel = value;
                  });
                },
                activeColor: Colors.black,
                inactiveColor: Colors.black26,
              ),
              const SizedBox(height: 20),

              const Text(
                "😊 ¿Cómo te sientes hoy?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _mood,
                items: const [
                  DropdownMenuItem(value: "Feliz", child: Text("🌞 Feliz")),
                  DropdownMenuItem(value: "Neutral", child: Text("😐 Neutral")),
                  DropdownMenuItem(value: "Triste", child: Text("☁️ Triste")),
                ],
                onChanged: (value) {
                  setState(() {
                    _mood = value!;
                  });
                },
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  hintText: "Selecciona tu estado de ánimo",
                ),
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  "💡 Recuerda: no importa cómo te sientas hoy, cada día es una nueva oportunidad para crecer y ser feliz.",
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

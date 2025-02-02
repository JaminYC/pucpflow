import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmotionalForm extends StatefulWidget {
  final String userId;

  const EmotionalForm({Key? key, required this.userId}) : super(key: key);

  @override
  State<EmotionalForm> createState() => _EmotionalFormState();
}

class _EmotionalFormState extends State<EmotionalForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  double _stressLevel = 5.0;
  String _mood = "Neutral";

  // Controlador para animaciones
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();

    // Inicializar controlador de animaciones
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // Iniciar la animación
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveEmotionalData() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'emotional': {
          'stress_level': _stressLevel,
          'mood': _mood,
        },
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
        backgroundColor: Colors.pinkAccent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveEmotionalData,
        label: const Text("Guardar"),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.pinkAccent,
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado motivador
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.pinkAccent, Colors.deepOrangeAccent],
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Text(
                    "💬 Tu bienestar emocional es importante. Responde con honestidad para recibir recomendaciones que mejoren tu calidad de vida.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Nivel de estrés
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
                  activeColor: Colors.pinkAccent,
                  inactiveColor: Colors.pinkAccent.withOpacity(0.4),
                ),
                const SizedBox(height: 20),

                // Estado de ánimo
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
                const SizedBox(height: 20),

                // Mensaje motivador
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(seconds: 1),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Text(
                      "💡 Recuerda: no importa cómo te sientas hoy, cada día es una nueva oportunidad para crecer y ser feliz.",
                      style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Botón para guardar
                ElevatedButton.icon(
                  onPressed: _saveEmotionalData,
                  icon: const Icon(Icons.save),
                  label: const Text("Guardar y continuar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

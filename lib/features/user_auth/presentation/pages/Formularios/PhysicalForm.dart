import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhysicalForm extends StatefulWidget {
  final String userId;

  const PhysicalForm({Key? key, required this.userId}) : super(key: key);

  @override
  State<PhysicalForm> createState() => _PhysicalFormState();
}

class _PhysicalFormState extends State<PhysicalForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Campos del formulario
  String _exercisePeriod = "Mañana";
  TimeOfDay _exerciseTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _bedTime = const TimeOfDay(hour: 23, minute: 0);
  double _activityLevel = 5.0;
  String _hydrationHabit = "1-2 litros";
  List<String> _fitnessPreferences = [];

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
    _controller.forward(); // Iniciar la animación
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Guardar datos en Firebase
  Future<void> _savePhysicalData() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'physical': {
          'exercise_period': _exercisePeriod,
          'exercise_time': '${_exerciseTime.hour}:${_exerciseTime.minute}',
          'bed_time': '${_bedTime.hour}:${_bedTime.minute}',
          'activity_level': _activityLevel,
          'hydration_habit': _hydrationHabit,
          'fitness_preferences': _fitnessPreferences,
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Datos físicos guardados correctamente")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al guardar datos: $e")),
      );
    }
  }

  Future<void> _selectTime(BuildContext context, TimeOfDay initialTime, Function(TimeOfDay) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null && picked != initialTime) {
      onTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("💪 Bienestar Físico"),
        backgroundColor: Colors.blueAccent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _savePhysicalData,
        label: const Text("Guardar"),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.blueAccent,
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
                // Encabezado atractivo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlue],
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Text(
                    "🏋️‍♂️ Completa este formulario para personalizar tu rutina y alcanzar tus metas físicas.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Período de ejercicio
                Row(
                  children: [
                    const Text("⏰ Período de ejercicio: "),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _exercisePeriod,
                        items: const [
                          DropdownMenuItem(value: "Mañana", child: Text("🌅 Mañana")),
                          DropdownMenuItem(value: "Tarde", child: Text("🌞 Tarde")),
                          DropdownMenuItem(value: "Noche", child: Text("🌙 Noche")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _exercisePeriod = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Hora de ejercicio
                ElevatedButton.icon(
                  onPressed: () {
                    _selectTime(context, _exerciseTime, (selectedTime) {
                      setState(() {
                        _exerciseTime = selectedTime;
                      });
                    });
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text("Hora de ejercicio: ${_exerciseTime.format(context)}"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 20),

                // Hora de dormir
                ElevatedButton.icon(
                  onPressed: () {
                    _selectTime(context, _bedTime, (selectedTime) {
                      setState(() {
                        _bedTime = selectedTime;
                      });
                    });
                  },
                  icon: const Icon(Icons.nights_stay),
                  label: Text("Hora de dormir: ${_bedTime.format(context)}"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 20),

                // Nivel de actividad física
                const Text("🏃‍♀️ Nivel de actividad física (1-10):"),
                Slider(
                  value: _activityLevel,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _activityLevel.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      _activityLevel = value;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Hábito de hidratación
                Row(
                  children: [
                    const Text("💧 Hidratación diaria: "),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _hydrationHabit,
                        items: const [
                          DropdownMenuItem(value: "Menos de 1 litro", child: Text("🥤 Menos de 1 litro")),
                          DropdownMenuItem(value: "1-2 litros", child: Text("💧 1-2 litros")),
                          DropdownMenuItem(value: "Más de 2 litros", child: Text("🌊 Más de 2 litros")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _hydrationHabit = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Preferencias de fitness
                const Text("🎯 Preferencias de fitness:"),
                Wrap(
                  spacing: 8.0,
                  children: [
                    _buildChip("Yoga 🧘‍♂️"),
                    _buildChip("Cardio 🏃"),
                    _buildChip("Pesas 🏋️"),
                    _buildChip("Pilates 🤸"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _fitnessPreferences.contains(label),
      onSelected: (selected) {
        setState(() {
          selected
              ? _fitnessPreferences.add(label)
              : _fitnessPreferences.remove(label);
        });
      },
      backgroundColor: Colors.blueAccent.withOpacity(0.2),
      selectedColor: Colors.blueAccent,
      labelStyle: const TextStyle(color: Colors.black),
    );
  }
}

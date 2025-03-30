import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhysicalForm extends StatefulWidget {
  final String userId;

  const PhysicalForm({Key? key, required this.userId}) : super(key: key);

  @override
  State<PhysicalForm> createState() => _PhysicalFormState();
}

class _PhysicalFormState extends State<PhysicalForm> {
  final _formKey = GlobalKey<FormState>();
  String _exercisePeriod = "Mañana";
  TimeOfDay _exerciseTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _bedTime = const TimeOfDay(hour: 23, minute: 0);
  double _activityLevel = 5.0;
  String _hydrationHabit = "1-2 litros";
  List<String> _fitnessPreferences = [];

  Future<void> _savePhysicalData() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'periodoEjercicio': _exercisePeriod,
        'horaEjercicio': '${_exerciseTime.hour}:${_exerciseTime.minute}',
        'horaDormir': '${_bedTime.hour}:${_bedTime.minute}',
        'nivelActividad': _activityLevel,
        'habitoHidratacion': _hydrationHabit,
        'preferenciasFitness': _fitnessPreferences,
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
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _savePhysicalData,
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
              const Text("⏰ Período de ejercicio:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _exercisePeriod,
                items: const [
                  DropdownMenuItem(value: "Mañana", child: Text("🌅 Mañana")),
                  DropdownMenuItem(value: "Tarde", child: Text("🌞 Tarde")),
                  DropdownMenuItem(value: "Noche", child: Text("🌙 Noche")),
                ],
                onChanged: (value) => setState(() => _exercisePeriod = value!),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () => _selectTime(context, _exerciseTime, (t) => setState(() => _exerciseTime = t)),
                icon: const Icon(Icons.access_time),
                label: Text("Hora de ejercicio: ${_exerciseTime.format(context)}"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () => _selectTime(context, _bedTime, (t) => setState(() => _bedTime = t)),
                icon: const Icon(Icons.nights_stay),
                label: Text("Hora de dormir: ${_bedTime.format(context)}"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 20),

              const Text("🏃‍♀️ Nivel de actividad física (1-10):", style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _activityLevel,
                min: 1,
                max: 10,
                divisions: 9,
                label: _activityLevel.round().toString(),
                onChanged: (value) => setState(() => _activityLevel = value),
                activeColor: Colors.black,
                inactiveColor: Colors.black26,
              ),
              const SizedBox(height: 20),

              const Text("💧 Hidratación diaria:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _hydrationHabit,
                items: const [
                  DropdownMenuItem(value: "Menos de 1 litro", child: Text("🥤 Menos de 1 litro")),
                  DropdownMenuItem(value: "1-2 litros", child: Text("💧 1-2 litros")),
                  DropdownMenuItem(value: "Más de 2 litros", child: Text("🌊 Más de 2 litros")),
                ],
                onChanged: (value) => setState(() => _hydrationHabit = value!),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              const Text("🎯 Preferencias de fitness:", style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: Colors.black.withOpacity(0.05),
      selectedColor: Colors.black,
      labelStyle: const TextStyle(color: Colors.black),
    );
  }
}

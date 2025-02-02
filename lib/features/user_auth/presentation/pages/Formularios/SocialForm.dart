import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SocialForm extends StatefulWidget {
  final String userId;

  const SocialForm({Key? key, required this.userId}) : super(key: key);

  @override
  State<SocialForm> createState() => _SocialFormState();
}

class _SocialFormState extends State<SocialForm> {
  final _formKey = GlobalKey<FormState>();

  // Campos del formulario
  String _socialInteractionFrequency = "Baja";
  String _mainHobby = "";
  TimeOfDay _departureTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _returnTime = const TimeOfDay(hour: 18, minute: 0);
  String _favoriteSocialActivity = "Salir con amigos"; // Nueva pregunta
  String _socialMediaUsage = "1-2 horas"; // Nueva pregunta
  String _preferredEventType = "Conciertos"; // Nueva pregunta

  Future<void> _saveSocialData() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'social': {
          'interaction_frequency': _socialInteractionFrequency,
          'main_hobby': _mainHobby,
          'departure_time': '${_departureTime.hour}:${_departureTime.minute}',
          'return_time': '${_returnTime.hour}:${_returnTime.minute}',
          'favorite_social_activity': _favoriteSocialActivity,
          'social_media_usage': _socialMediaUsage,
          'preferred_event_type': _preferredEventType,
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Datos sociales guardados correctamente")),
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
        title: const Text("🌟 Bienestar Social"),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSocialData,
        label: const Text("Guardar"),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.green,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Frecuencia de interacciones sociales
              const Text(
                "🤝 Frecuencia de interacciones sociales:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _socialInteractionFrequency,
                items: const [
                  DropdownMenuItem(value: "Alta", child: Text("Alta")),
                  DropdownMenuItem(value: "Moderada", child: Text("Moderada")),
                  DropdownMenuItem(value: "Baja", child: Text("Baja")),
                ],
                onChanged: (value) {
                  setState(() {
                    _socialInteractionFrequency = value!;
                  });
                },
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Hobby principal
              const Text(
                "🎨 Hobby principal:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Hobby principal",
                  hintText: "Ejemplo: Leer, bailar, jugar videojuegos",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _mainHobby = value;
                },
              ),
              const SizedBox(height: 20),

              // Actividad social favorita
              const Text(
                "🎉 Actividad social favorita:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _favoriteSocialActivity,
                items: const [
                  DropdownMenuItem(value: "Salir con amigos", child: Text("Salir con amigos")),
                  DropdownMenuItem(value: "Jugar deportes", child: Text("Jugar deportes")),
                  DropdownMenuItem(value: "Ir a fiestas", child: Text("Ir a fiestas")),
                  DropdownMenuItem(value: "Actividades culturales", child: Text("Actividades culturales")),
                ],
                onChanged: (value) {
                  setState(() {
                    _favoriteSocialActivity = value!;
                  });
                },
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Uso de redes sociales
              const Text(
                "📱 Uso diario de redes sociales:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _socialMediaUsage,
                items: const [
                  DropdownMenuItem(value: "Menos de 1 hora", child: Text("Menos de 1 hora")),
                  DropdownMenuItem(value: "1-2 horas", child: Text("1-2 horas")),
                  DropdownMenuItem(value: "Más de 2 horas", child: Text("Más de 2 horas")),
                ],
                onChanged: (value) {
                  setState(() {
                    _socialMediaUsage = value!;
                  });
                },
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Tipo de eventos preferidos
              const Text(
                "🎭 Tipo de eventos preferidos:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _preferredEventType,
                items: const [
                  DropdownMenuItem(value: "Conciertos", child: Text("Conciertos")),
                  DropdownMenuItem(value: "Festivales", child: Text("Festivales")),
                  DropdownMenuItem(value: "Reuniones pequeñas", child: Text("Reuniones pequeñas")),
                  DropdownMenuItem(value: "Deportes", child: Text("Deportes")),
                ],
                onChanged: (value) {
                  setState(() {
                    _preferredEventType = value!;
                  });
                },
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Hora de salida
              ElevatedButton.icon(
                onPressed: () {
                  _selectTime(context, _departureTime, (selectedTime) {
                    setState(() {
                      _departureTime = selectedTime;
                    });
                  });
                },
                icon: const Icon(Icons.directions_walk),
                label: Text("Hora de salida: ${_departureTime.format(context)}"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 20),

              // Hora de regreso
              ElevatedButton.icon(
                onPressed: () {
                  _selectTime(context, _returnTime, (selectedTime) {
                    setState(() {
                      _returnTime = selectedTime;
                    });
                  });
                },
                icon: const Icon(Icons.home),
                label: Text("Hora de regreso: ${_returnTime.format(context)}"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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

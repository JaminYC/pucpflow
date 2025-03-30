import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'Login/google_calendar_service.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({Key? key}) : super(key: key);

  @override
  _ExercisePageState createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final GoogleCalendarService _googleCalendarService = GoogleCalendarService();
  double _exerciseProgress = 0.5; // Progreso inicial (50%)

  void _addExerciseToCalendar(String title, String description, int durationMinutes) async {
    final calendarApi = await _googleCalendarService.signInAndGetCalendarApi();
    if (calendarApi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo conectar a Google Calendar")),
      );
      return;
    }

    final now = DateTime.now();
    final event = calendar.Event(
      summary: title,
      description: description,
      colorId: "2", // Verde
      start: calendar.EventDateTime(
        dateTime: now.add(const Duration(minutes: 10)), // Inicia en 10 minutos
        timeZone: "America/Lima",
      ),
      end: calendar.EventDateTime(
        dateTime: now.add(Duration(minutes: 10 + durationMinutes)), // Duración personalizada
        timeZone: "America/Lima",
      ),
    );

    try {
      await calendarApi.events.insert(event, "primary");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Evento añadido al calendario")),
      );
      setState(() {
        _exerciseProgress += 0.25; // Incrementa el progreso al añadir una actividad
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al añadir evento: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rutina de Ejercicio"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Progreso de Ejercicio",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _exerciseProgress,
              color: Colors.blue,
              backgroundColor: Colors.blue.withOpacity(0.2),
            ),
            const SizedBox(height: 20),
            const Text(
              "Actividades Recomendadas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildExerciseTile(
              "Correr 5 km",
              "Una carrera para mejorar tu resistencia.",
              30,
              Icons.directions_run,
            ),
            const SizedBox(height: 10),
            _buildExerciseTile(
              "Entrenamiento de Fuerza",
              "Ejercicios para fortalecer músculos.",
              45,
              Icons.fitness_center,
            ),
            const SizedBox(height: 10),
            _buildExerciseTile(
              "Yoga de Relajación",
              "Estiramientos para mejorar la flexibilidad.",
              20,
              Icons.self_improvement,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTile(String title, String description, int durationMinutes, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(description),
      trailing: ElevatedButton(
        onPressed: () {
          _addExerciseToCalendar(title, description, durationMinutes);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green, // Botón verde
          foregroundColor: Colors.white,
        ),
        child: const Text("Agregar"),
      ),
    );
  }
}

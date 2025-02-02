import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'MeditationPage.dart';
import 'google_calendar_service.dart';


import 'ExercisePage.dart';



class HealthPage extends StatefulWidget {
  const HealthPage({Key? key}) : super(key: key);

  @override
  _HealthPageState createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final _googleCalendarService = GoogleCalendarService();

  // Datos de ejemplo para autoevaluación
  double _physicalProgress = 0.8; // 80%
  double _mentalProgress = 0.6; // 60%
  double _socialProgress = 0.7; // 70%
  double _emotionalProgress = 0.9; // 90%

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salud Integral"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Autoevaluación de Bienestar",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildProgressSection("Salud Física", _physicalProgress, Colors.blue),
              _buildProgressSection("Salud Mental", _mentalProgress, Colors.purple),
              _buildProgressSection("Salud Social", _socialProgress, Colors.orange),
              _buildProgressSection("Salud Emocional", _emotionalProgress, Colors.pink),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _addToCalendar();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Agregar Cuidado al Calendario"),
              ),
              const SizedBox(height: 20),
              _buildRoutineSection(),
              const SizedBox(height: 20),
              _buildTipsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(String title, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          color: color,
          backgroundColor: color.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

 Widget _buildRoutineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Rutinas Recomendadas",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        // Botón de Rutina de Ejercicio
        ListTile(
          leading: const Icon(Icons.directions_run, color: Colors.blue),
          title: const Text("Ejercicio Matutino"),
          trailing: const Icon(Icons.arrow_forward, color: Colors.blue),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ExercisePage(), // Navega a ExercisePage
              ),
            );
          },
        ),
        // Botón de Rutina de Meditación
        ListTile(
          leading: const Icon(Icons.self_improvement, color: Colors.purple),
          title: const Text("Meditación"),
          trailing: const Icon(Icons.arrow_forward, color: Colors.purple),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MeditationPage(), // Navega a MeditationPage
              ),
            );
          },
        ),
      ],
    );
  }
  Widget _buildRoutineTile(String title, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: IconButton(
        icon: const Icon(Icons.calendar_today, color: Colors.green),
        onPressed: _addToCalendar,
      ),
    );
  }

  Widget _buildTipsSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Consejos y Artículos",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ListTile(
          leading: Icon(Icons.lightbulb, color: Colors.green),
          title: Text("5 minutos al día para meditar y relajarte."),
        ),
        ListTile(
          leading: Icon(Icons.lightbulb, color: Colors.green),
          title: Text("Conecta con alguien que te haga feliz."),
        ),
        ListTile(
          leading: Icon(Icons.lightbulb, color: Colors.green),
          title: Text("Escribe tus logros del día en un diario."),
        ),
      ],
    );
  }

  Future<void> _addToCalendar() async {
    final now = DateTime.now();
    final calendarApi = await _googleCalendarService.signInAndGetCalendarApi();

    if (calendarApi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo conectar con Google Calendar")),
      );
      return;
    }

    final event = calendar.Event(
      summary: "Cuidado de Salud Integral",
      description: "Tiempo dedicado al bienestar físico, mental, social y emocional.",
      start: calendar.EventDateTime(
        dateTime: now.add(const Duration(minutes: 10)), // Evento en 10 minutos
        timeZone: "America/Lima",
      ),
      end: calendar.EventDateTime(
        dateTime: now.add(const Duration(hours: 1)), // Dura 1 hora
        timeZone: "America/Lima",
      ),
    );

    try {
      await calendarApi.events.insert(event, "primary");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Evento agregado al calendario")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al agregar evento: $e")),
      );
    }
  }
}

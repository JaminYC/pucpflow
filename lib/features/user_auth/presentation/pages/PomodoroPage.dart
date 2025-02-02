import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({Key? key}) : super(key: key);

  @override
  _PomodoroPageState createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  int workDuration = 25; // Duración del trabajo en minutos
  int breakDuration = 5; // Duración del descanso en minutos
  int remainingSeconds = 1500; // Tiempo restante en segundos
  bool isRunning = false; // Estado del temporizador
  bool isWorkInterval = true; // Intervalo de trabajo o descanso
  Timer? timer;
  int completedPomodoros = 0; // Pomodoros completados
  String currentTask = "Sin Tarea"; // Tarea actual
  List<Map<String, dynamic>> pomodoroHistory = []; // Historial de pomodoros

  final FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initNotifications();
  }

  void initNotifications() {
    final initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    localNotificationsPlugin.initialize(initializationSettings);
  }

  void showNotification(String title, String body) async {
    final androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro',
      channelDescription: 'Notificaciones para el Pomodoro',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true, // Habilita sonido predeterminado
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    await localNotificationsPlugin.show(0, title, body, notificationDetails);
  }

  void startTimer() {
    if (timer != null) timer!.cancel(); // Cancela el temporizador previo
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          // Cambia entre intervalos de trabajo y descanso
          if (isWorkInterval) {
            completedPomodoros++;
            pomodoroHistory.add({
              "task": currentTask,
              "completedAt": DateTime.now(),
            });
            showNotification("¡Descanso!", "Relájate antes del próximo ciclo.");
          } else {
            showNotification("¡Tiempo de trabajar!", "Enfócate en tu tarea.");
          }
          isWorkInterval = !isWorkInterval;
          remainingSeconds = (isWorkInterval ? workDuration : breakDuration) * 60;
        }
      });
    });
    setState(() {
      isRunning = true;
    });
  }

  void pauseTimer() {
    if (timer != null) timer!.cancel();
    setState(() {
      isRunning = false;
    });
  }

  void resetTimer() {
    if (timer != null) timer!.cancel();
    setState(() {
      remainingSeconds = workDuration * 60;
      isWorkInterval = true;
      isRunning = false;
    });
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void openCustomizationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Personalizar Duraciones"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Duración de Trabajo (min)"),
              onChanged: (value) {
                workDuration = int.tryParse(value) ?? workDuration;
              },
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Duración de Descanso (min)"),
              onChanged: (value) {
                breakDuration = int.tryParse(value) ?? breakDuration;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              resetTimer();
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void openTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Establecer Tarea"),
        content: TextField(
          decoration: const InputDecoration(labelText: "Tarea Actual"),
          onChanged: (value) {
            currentTask = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void viewHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PomodoroHistoryPage(history: pomodoroHistory),
      ),
    );
  }

  @override
  void dispose() {
    if (timer != null) timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWorkInterval ? Colors.red.shade100 : Colors.green.shade100,
      appBar: AppBar(
        title: const Text("Pomodoro Timer"),
        backgroundColor: isWorkInterval ? Colors.red : Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Tarea Actual: $currentTask",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              isWorkInterval ? "Trabajo Enfocado" : "Descanso",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              formatTime(remainingSeconds),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isRunning ? null : startTimer,
                  child: const Text("Iniciar"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isRunning ? pauseTimer : null,
                  child: const Text("Pausar"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: resetTimer,
                  child: const Text("Reiniciar"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: openCustomizationDialog,
              child: const Text("Personalizar Duraciones"),
            ),
            ElevatedButton(
              onPressed: openTaskDialog,
              child: const Text("Establecer Tarea"),
            ),
            ElevatedButton(
              onPressed: viewHistory,
              child: const Text("Ver Historial"),
            ),
            const SizedBox(height: 30),
            Text(
              "Pomodoros Completados: $completedPomodoros",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class PomodoroHistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const PomodoroHistoryPage({Key? key, required this.history}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Pomodoros"),
      ),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          return ListTile(
            title: Text("Tarea: ${item['task']}"),
            subtitle: Text("Completado: ${item['completedAt']}"),
          );
        },
      ),
    );
  }
}

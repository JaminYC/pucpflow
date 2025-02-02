import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ProyectoDetallePage.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({Key? key}) : super(key: key);

  @override
  _PomodoroPageState createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> with WidgetsBindingObserver {
  int workDuration = 25;
  int breakDuration = 5;
  int remainingSeconds = 1500;
  bool isRunning = false;
  bool isWorkInterval = true;
  Timer? timer;
  int completedPomodoros = 0;
  String currentTask = "Sin Tarea";
  List<Map<String, dynamic>> pomodoroHistory = [];

  final FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<Proyecto> proyectos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initNotifications();
    loadProyectos();
    loadPomodoroHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (timer != null) timer!.cancel();
    super.dispose();
  }

  void initNotifications() {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    localNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> loadProyectos() async {
    final prefs = await SharedPreferences.getInstance();
    final proyectosData = prefs.getStringList('proyectos') ?? [];

    setState(() {
      proyectos = proyectosData
          .map((proyectoJson) => Proyecto.fromJson(jsonDecode(proyectoJson)))
          .toList();
    });
  }

  Future<void> loadPomodoroHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyData = prefs.getStringList('pomodoroHistory') ?? [];
    setState(() {
      pomodoroHistory = historyData
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> savePomodoroHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyData = pomodoroHistory.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('pomodoroHistory', historyData);
  }

  void showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro',
      channelDescription: 'Notificaciones para el Pomodoro',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    await localNotificationsPlugin.show(0, title, body, notificationDetails);
  }

  void startTimer() {
    if (timer != null) timer!.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          if (isWorkInterval) {
            completedPomodoros++;
            pomodoroHistory.add({
              "task": currentTask,
              "completedAt": DateTime.now().toIso8601String(),
            });
            savePomodoroHistory();
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

  void setTask(String task) {
    setState(() {
      currentTask = task;
    });
  }

  void openTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Seleccionar Tarea"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: proyectos.map((proyecto) {
            return ListTile(
              title: Text(proyecto.nombre),
              onTap: () {
                setTask(proyecto.nombre);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
        ],
      ),
    );
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

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && isRunning) {
      showNotification(
        "¡No te distraigas!",
        "Vuelve al Pomodoro y mantente enfocado 😡"
      );
      Future.delayed(const Duration(seconds: 2), () => showFocusWarning());
    }
  }

  void showFocusWarning() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.red.shade100,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning, size: 100, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  "¡Vuelve a concentrarte!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Regresar al Pomodoro"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWorkInterval ? Colors.red.shade100 : Colors.green.shade100,
      appBar: AppBar(
        title: const Text("Pomodoro Timer"),
        backgroundColor: isWorkInterval ? Colors.red : Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment),
            onPressed: openTaskDialog,
          ),
          IconButton(
            icon: const Icon(Icons.timer),
            onPressed: openCustomizationDialog,
          ),
        ],
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

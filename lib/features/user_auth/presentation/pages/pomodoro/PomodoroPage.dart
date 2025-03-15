// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';

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
  Tarea? selectedTarea;
  List<Map<String, dynamic>> pomodoroHistory = [];

  final FlutterLocalNotificationsPlugin localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late VideoPlayerController _videoController;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _videoController = VideoPlayerController.asset("assets/Pomodoro.mp4")
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        _videoController.play();
        setState(() {
          _videoReady = true;
        });
      });
      loadPomodoroHistory();
    }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    _videoController.dispose();
    super.dispose();
  }

  void initNotifications() {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    localNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> loadPomodoroHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyData = prefs.getStringList('pomodoroHistory') ?? [];
    setState(() {
      pomodoroHistory = historyData.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
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
    if (!_videoController.value.isPlaying) _videoController.play();
    if (timer != null) timer!.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          if (isWorkInterval) {
            completedPomodoros++;
            if (selectedTarea != null) _marcarTareaCompletada(selectedTarea!);
            pomodoroHistory.add({
              "task": currentTask,
              "completedAt": DateTime.now().toIso8601String(),
            });
            savePomodoroHistory();
            showNotification("\u{1F389} Descanso", "¡Has completado un Pomodoro!");
          } else {
            showNotification("\u{1F4AA} Trabajo", "¡Hora de concentrarse!");
          }
          isWorkInterval = !isWorkInterval;
          remainingSeconds = (isWorkInterval ? workDuration : breakDuration) * 60;
        }
      });
    });
    setState(() => isRunning = true);
  }

  void pauseTimer() {
    timer?.cancel();
    setState(() => isRunning = false);
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      remainingSeconds = workDuration * 60;
      isWorkInterval = true;
      isRunning = false;
    });
  }

  Future<void> _marcarTareaCompletada(Tarea tarea) async {
    final userId = _auth.currentUser!.uid;
    final querySnapshot = await _firestore.collection("proyectos").get();
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      List<dynamic> tareas = data["tareas"] ?? [];
      for (int i = 0; i < tareas.length; i++) {
        if (tareas[i]["titulo"] == tarea.titulo && (tareas[i]["responsables"] as List).contains(userId)) {
          tareas[i]["completado"] = true;
        }
      }
      await _firestore.collection("proyectos").doc(doc.id).update({"tareas": tareas});
    }
  }

  void openTaskDialog() async {
    final userId = _auth.currentUser!.uid;
    final snapshot = await _firestore.collection("proyectos").get();
    List<Tarea> tareasUsuario = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      List<dynamic> tareas = data["tareas"] ?? [];
      for (var tareaJson in tareas) {
        Tarea tarea = Tarea.fromJson(tareaJson);
        if (tarea.responsables.contains(userId) && !tarea.completado) {
          tareasUsuario.add(tarea);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Seleccionar Tarea Asignada"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tareasUsuario.length,
            itemBuilder: (context, index) {
              Tarea tarea = tareasUsuario[index];
              return ListTile(
                title: Text(tarea.titulo),
                trailing: Checkbox(
                  value: tarea.completado,
                  onChanged: (bool? value) {
                    Navigator.pop(context);
                    setState(() {
                      selectedTarea = tarea;
                      currentTask = tarea.titulo;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void openCustomizationDialog() {
    final controllerWork = TextEditingController(text: workDuration.toString());
    final controllerBreak = TextEditingController(text: breakDuration.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Personalizar Duraciones"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controllerWork,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Trabajo (min)"),
            ),
            TextField(
              controller: controllerBreak,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Descanso (min)"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              int? newWork = int.tryParse(controllerWork.text);
              int? newBreak = int.tryParse(controllerBreak.text);
              if (newWork == null || newBreak == null || newWork <= 0 || newBreak <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Los tiempos deben ser mayores a 0")),
                );
                return;
              }
              setState(() {
                workDuration = newWork;
                breakDuration = newBreak;
                remainingSeconds = workDuration * 60;
              });
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
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _videoReady
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                )
              : Container(color: Colors.black),
        ),

        Scaffold(
          backgroundColor: Colors.black.withOpacity(0.6),
          appBar: AppBar(
            title: const Text("Pomodoro Timer"),
            backgroundColor: isWorkInterval ? Colors.red : Colors.green,
            actions: [
              IconButton(icon: const Icon(Icons.assignment), onPressed: openTaskDialog),
              IconButton(icon: const Icon(Icons.timer), onPressed: openCustomizationDialog),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Tarea Actual:",
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  currentTask,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(isWorkInterval ? "Trabajo Enfocado" : "Descanso",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),
                Text(formatTime(remainingSeconds),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildButton("Iniciar", isRunning ? null : startTimer),
                    const SizedBox(width: 10),
                    _buildButton("Pausar", isRunning ? pauseTimer : null),
                    const SizedBox(width: 10),
                    _buildButton("Reiniciar", resetTimer),
                  ],
                ),
                const SizedBox(height: 20),
                Text("Pomodoros Completados: $completedPomodoros",
                    style: const TextStyle(fontSize: 18, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String label, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}

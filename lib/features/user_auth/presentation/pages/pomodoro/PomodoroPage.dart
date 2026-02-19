// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({Key? key}) : super(key: key);

  @override
  _PomodoroPageState createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  int workDuration = 25;
  int breakDuration = 5;
  int longBreakDuration = 15;
  int pomodorosBeforeLongBreak = 4;

  int remainingSeconds = 1500;
  int completedPomodoros = 0;
  int completedWorkSessions = 0;
  bool isRunning = false;
  bool isWorkInterval = true;
  bool isLongBreak = false;
  bool autoStartNextInterval = true;

  Timer? timer;
  String currentTask = "Sin tarea";
  Tarea? selectedTarea;
  List<Map<String, dynamic>> pomodoroHistory = [];

  final FlutterLocalNotificationsPlugin localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    initNotifications();
    loadPomodoroHistory();
    _loadTimerState(); // Cargar estado del timer
  }

  @override
  void dispose() {
    _saveTimerState(); // Guardar estado antes de cerrar
    timer?.cancel();
    super.dispose();
  }

  int get _currentIntervalTotalSeconds {
    if (isWorkInterval) return workDuration * 60;
    return isLongBreak ? longBreakDuration * 60 : breakDuration * 60;
  }

  String get _currentIntervalName {
    if (isWorkInterval) return "Trabajo enfocado";
    return isLongBreak ? "Descanso largo" : "Descanso corto";
  }

  String get _nextIntervalName {
    if (isWorkInterval) {
      final remainingToLongBreak = pomodorosBeforeLongBreak - (completedWorkSessions % pomodorosBeforeLongBreak) - 1;
      return remainingToLongBreak == 0 ? "Descanso largo" : "Descanso corto";
    }
    return "Trabajo enfocado";
  }

  int get _remainingToLongBreak => pomodorosBeforeLongBreak - (completedWorkSessions % pomodorosBeforeLongBreak);

  double get _progress {
    if (_currentIntervalTotalSeconds == 0) return 0;
    final value = 1 - (remainingSeconds / _currentIntervalTotalSeconds);
    return value.clamp(0.0, 1.0).toDouble();
  }

  int get _todayWorkSessions {
    return pomodoroHistory.where((entry) {
      final date = DateTime.tryParse(entry["completedAt"] ?? "");
      return date != null && _isToday(date) && (entry["type"] ?? "work") == "work";
    }).length;
  }

  int get _todayFocusMinutes {
    return pomodoroHistory.where((entry) {
      final date = DateTime.tryParse(entry["completedAt"] ?? "");
      return date != null && _isToday(date) && (entry["type"] ?? "work") == "work";
    }).fold(0, (sum, entry) => sum + (entry["duration"] as int? ?? workDuration));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year && now.month == date.month && now.day == date.day;
  }

  Future<void> loadPomodoroHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyData = prefs.getStringList('pomodoroHistory') ?? [];
    setState(() {
      pomodoroHistory = historyData.map((item) {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        return {
          "task": decoded["task"] ?? "Sin tarea",
          "completedAt": decoded["completedAt"] ?? DateTime.now().toIso8601String(),
          "type": decoded["type"] ?? "work",
          "duration": decoded["duration"] ?? workDuration,
        };
      }).toList();
    });
  }

  Future<void> savePomodoroHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyData = pomodoroHistory.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('pomodoroHistory', historyData);
  }

  // ===== PERSISTENCIA DEL ESTADO DEL TIMER =====
  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro.remainingSeconds', remainingSeconds);
    await prefs.setBool('pomodoro.isRunning', isRunning);
    await prefs.setBool('pomodoro.isWorkInterval', isWorkInterval);
    await prefs.setBool('pomodoro.isLongBreak', isLongBreak);
    await prefs.setInt('pomodoro.completedPomodoros', completedPomodoros);
    await prefs.setInt('pomodoro.completedWorkSessions', completedWorkSessions);
    await prefs.setString('pomodoro.currentTask', currentTask);
    await prefs.setInt('pomodoro.lastSaveTime', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();

    final savedTime = prefs.getInt('pomodoro.lastSaveTime');
    if (savedTime != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - savedTime;
      final elapsedSeconds = (elapsed / 1000).floor();

      setState(() {
        remainingSeconds = prefs.getInt('pomodoro.remainingSeconds') ?? 1500;
        isRunning = prefs.getBool('pomodoro.isRunning') ?? false;
        isWorkInterval = prefs.getBool('pomodoro.isWorkInterval') ?? true;
        isLongBreak = prefs.getBool('pomodoro.isLongBreak') ?? false;
        completedPomodoros = prefs.getInt('pomodoro.completedPomodoros') ?? 0;
        completedWorkSessions = prefs.getInt('pomodoro.completedWorkSessions') ?? 0;
        currentTask = prefs.getString('pomodoro.currentTask') ?? "Sin tarea";

        // Si el timer estaba corriendo, restar el tiempo transcurrido
        if (isRunning) {
          remainingSeconds = (remainingSeconds - elapsedSeconds).clamp(0, _currentIntervalTotalSeconds);

          // Si se acabó el tiempo mientras la app estaba cerrada
          if (remainingSeconds <= 0) {
            _completeInterval();
          } else {
            // Reanudar timer
            startTimer();
          }
        }
      });
    }
  }

  void _logHistory(String type, int durationMinutes) {
    pomodoroHistory.add({
      "task": currentTask,
      "completedAt": DateTime.now().toIso8601String(),
      "type": type,
      "duration": durationMinutes,
    });
    savePomodoroHistory();
  }

  void initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    await localNotificationsPlugin.initialize(initializationSettings);

    // Crear canal de notificaciones en Android
    const androidChannel = AndroidNotificationChannel(
      'pomodoro_channel',
      'Pomodoro Timer',
      description: 'Notificaciones cuando termina un intervalo Pomodoro',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  void showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Timer',
      channelDescription: 'Notificaciones cuando termina un intervalo Pomodoro',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
      icon: '@mipmap/ic_launcher',
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID único
      title,
      body,
      notificationDetails,
    );
  }

  void startTimer() {
    if (timer != null) timer!.cancel();
    setState(() => isRunning = true);
    _saveTimerState(); // Guardar estado
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
        // Guardar cada 10 segundos para no saturar
        if (remainingSeconds % 10 == 0) {
          _saveTimerState();
        }
      } else {
        _completeInterval();
      }
    });
  }

  void pauseTimer() {
    timer?.cancel();
    setState(() => isRunning = false);
    _saveTimerState(); // Guardar estado
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      remainingSeconds = workDuration * 60;
      isWorkInterval = true;
      isLongBreak = false;
      isRunning = false;
    });
    _saveTimerState(); // Guardar estado
  }

  Future<void> skipInterval() async {
    await _completeInterval(skip: true);
  }

  Future<void> _completeInterval({bool skip = false}) async {
    timer?.cancel();
    timer = null;

    if (!skip) {
      if (isWorkInterval) {
        completedPomodoros++;
        completedWorkSessions++;
        _logHistory("work", workDuration);
        if (selectedTarea != null) {
          await _marcarTareaCompletada(selectedTarea!);
        }
        showNotification(
          "🎉 ¡Pomodoro completado!",
          "Completaste un pomodoro de ${workDuration} minutos. Toma un descanso.",
        );
      } else {
        _logHistory(isLongBreak ? "long_break" : "break", isLongBreak ? longBreakDuration : breakDuration);
        showNotification(
          "⏰ Descanso terminado",
          "Hora de volver a concentrarse. ¡Vamos!",
        );
      }
    }

    final shouldTakeLongBreak =
        isWorkInterval && !skip && completedWorkSessions > 0 && completedWorkSessions % pomodorosBeforeLongBreak == 0;

    setState(() {
      isWorkInterval = !isWorkInterval;
      isLongBreak = !isWorkInterval && shouldTakeLongBreak;
      remainingSeconds = _currentIntervalTotalSeconds;
      isRunning = autoStartNextInterval && !skip;
    });

    _saveTimerState(); // Guardar estado después de completar intervalo

    if (autoStartNextInterval && !skip) {
      startTimer();
    }
  }

  Future<void> _marcarTareaCompletada(Tarea tarea) async {
    final userId = _auth.currentUser!.uid;
    final querySnapshot = await _firestore.collection("proyectos").get();
    for (var doc in querySnapshot.docs) {
      final tareasSnapshot = await _firestore.collection("proyectos").doc(doc.id).collection("tareas")
          .where("titulo", isEqualTo: tarea.titulo).get();
      for (var tareaDoc in tareasSnapshot.docs) {
        final data = tareaDoc.data();
        final responsables = List<String>.from(data["responsables"] ?? []);
        if (responsables.contains(userId)) {
          await tareaDoc.reference.update({
            "completado": true,
            "estado": "completada",
            "fechaCompletada": DateTime.now().toIso8601String(),
          });
        }
      }
    }
  }

  void openTaskDialog() async {
    final userId = _auth.currentUser!.uid;
    final snapshot = await _firestore.collection("proyectos").get();
    List<Tarea> tareasUsuario = [];
    Map<String, String> tareaProyectos = {};
    Set<String> proyectosUnicos = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final nombreProyecto = data["nombre"] ?? "Proyecto";
      final tareasSnapshot = await _firestore.collection("proyectos").doc(doc.id).collection("tareas").get();
      for (var tareaDoc in tareasSnapshot.docs) {
        Tarea tarea = Tarea.fromJson(tareaDoc.data());
        if (tarea.responsables.contains(userId) && !tarea.completado) {
          tareasUsuario.add(tarea);
          tareaProyectos[tarea.titulo] = nombreProyecto;
          proyectosUnicos.add(nombreProyecto);
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _TaskSelectionDialog(
        tareasUsuario: tareasUsuario,
        tareaProyectos: tareaProyectos,
        proyectosUnicos: proyectosUnicos.toList()..sort(),
        onTareaSelected: (tarea) {
          setState(() {
            selectedTarea = tarea;
            currentTask = tarea?.titulo ?? "Sin tarea";
          });
        },
        currentlySelected: selectedTarea,
      ),
    );
  }

  void openCustomizationDialog() {
    final controllerWork = TextEditingController(text: workDuration.toString());
    final controllerBreak = TextEditingController(text: breakDuration.toString());
    final controllerLongBreak = TextEditingController(text: longBreakDuration.toString());
    final controllerCycle = TextEditingController(text: pomodorosBeforeLongBreak.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Personalizar ritmos"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numberField(controllerWork, "Trabajo (min)"),
              _numberField(controllerBreak, "Descanso corto (min)"),
              _numberField(controllerLongBreak, "Descanso largo (min)"),
              _numberField(controllerCycle, "Pomodoros antes del descanso largo"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              final newWork = int.tryParse(controllerWork.text);
              final newBreak = int.tryParse(controllerBreak.text);
              final newLongBreak = int.tryParse(controllerLongBreak.text);
              final newCycle = int.tryParse(controllerCycle.text);
              if (newWork == null || newBreak == null || newLongBreak == null || newCycle == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ingresa solo numeros.")),
                );
                return;
              }
              if (newWork <= 0 || newBreak <= 0 || newLongBreak <= 0 || newCycle <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Los tiempos deben ser mayores a 0.")),
                );
                return;
              }
              setState(() {
                workDuration = newWork;
                breakDuration = newBreak;
                longBreakDuration = newLongBreak;
                pomodorosBeforeLongBreak = newCycle;
                remainingSeconds =
                    (isWorkInterval ? workDuration : (isLongBreak ? longBreakDuration : breakDuration)) * 60;
              });
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  TextField _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }

  void _openHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Historial",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          pomodoroHistory.clear();
                        });
                        savePomodoroHistory();
                        Navigator.pop(context);
                      },
                      child: const Text("Limpiar", style: TextStyle(color: Colors.redAccent)),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                pomodoroHistory.isEmpty
                    ? const Text("Aun no hay sesiones guardadas.", style: TextStyle(color: Colors.white70))
                    : SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
                        child: ListView.builder(
                          itemCount: pomodoroHistory.length,
                          itemBuilder: (context, index) {
                            final entry = pomodoroHistory[pomodoroHistory.length - 1 - index];
                            return _historyTile(entry);
                          },
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  String _formatIntervalDate(String isoString) {
    final date = DateTime.tryParse(isoString);
    if (date == null) return "Fecha desconocida";
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return _isToday(date) ? "Hoy $time" : "${date.day}/${date.month} $time";
  }

  Widget _historyTile(Map<String, dynamic> entry) {
    final type = entry["type"] ?? "work";
    IconData icon;
    Color color;
    String label;
    switch (type) {
      case "break":
        icon = Icons.free_breakfast;
        color = Colors.lightGreenAccent;
        label = "Descanso corto";
        break;
      case "long_break":
        icon = Icons.spa;
        color = Colors.cyanAccent;
        label = "Descanso largo";
        break;
      default:
        icon = Icons.local_fire_department;
        color = Colors.orangeAccent;
        label = "Trabajo";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(entry["task"] ?? "Sin tarea", style: const TextStyle(color: Colors.white70)),
                Text(_formatIntervalDate(entry["completedAt"] ?? ""),
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Text("${entry["duration"] ?? "-"} min", style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildBackgroundLayer() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xCC0A0F1F), Color(0xAA101A3D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tarea actual", style: TextStyle(color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  currentTask,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: openTaskDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                label: const Text("Cambiar"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _infoChip(Icons.bolt, _currentIntervalName, Colors.orangeAccent),
              _infoChip(Icons.schedule, "Siguiente: $_nextIntervalName", Colors.cyanAccent),
              _infoChip(Icons.emoji_events, "Total: $completedPomodoros", Colors.pinkAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(_currentIntervalName, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            width: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 220,
                  width: 220,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(isWorkInterval ? Colors.redAccent : Colors.greenAccent),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatTime(remainingSeconds),
                      style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text("${(_progress * 100).round()}% completado", style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton(Icons.skip_next, "Saltar", skipInterval),
              const SizedBox(width: 10),
              _actionButton(
                isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill,
                isRunning ? "Pausar" : "Iniciar",
                isRunning ? pauseTimer : startTimer,
                primary: true,
              ),
              const SizedBox(width: 10),
              _actionButton(Icons.restart_alt, "Reiniciar", resetTimer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onPressed, {bool primary = false}) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? Colors.redAccent : Colors.white.withOpacity(0.08),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _buildPresets() {
    final presets = [
      {"label": "Clasico 25/5", "work": 25, "break": 5, "long": 15, "cycle": 4},
      {"label": "Profundo 52/17", "work": 52, "break": 17, "long": 25, "cycle": 3},
      {"label": "Sprint 15/5", "work": 15, "break": 5, "long": 15, "cycle": 4},
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Presets rapidos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: presets.map((preset) {
              return ChoiceChip(
                label: Text(preset["label"] as String),
                selected: workDuration == preset["work"] && breakDuration == preset["break"],
                onSelected: (_) {
                  setState(() {
                    workDuration = preset["work"] as int;
                    breakDuration = preset["break"] as int;
                    longBreakDuration = preset["long"] as int;
                    pomodorosBeforeLongBreak = preset["cycle"] as int;
                    remainingSeconds =
                        (isWorkInterval ? workDuration : (isLongBreak ? longBreakDuration : breakDuration)) * 60;
                  });
                },
                labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                selectedColor: Colors.redAccent.withOpacity(0.65),
                backgroundColor: const Color(0xFF1E2438),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white24),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            value: autoStartNextInterval,
            activeColor: Colors.redAccent,
            title: const Text("Autoiniciar siguiente intervalo", style: TextStyle(color: Colors.white)),
            onChanged: (value) {
              setState(() {
                autoStartNextInterval = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _statTile(Icons.timer, "$_todayWorkSessions hoy", "Pomodoros", Colors.orangeAccent),
          const SizedBox(width: 12),
          _statTile(Icons.hourglass_bottom, "$_remainingToLongBreak", "Para descanso largo", Colors.cyanAccent),
          const SizedBox(width: 12),
          _statTile(Icons.rocket_launch, "$_todayFocusMinutes min", "Enfoque hoy", Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPreview() {
    final recent = pomodoroHistory.reversed.take(4).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text("Resumen rapido", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              TextButton(
                onPressed: _openHistorySheet,
                child: const Text("Ver todo", style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            const Text("Aun no registras sesiones.", style: TextStyle(color: Colors.white70))
          else
            Column(
              children: recent.map((entry) => _historyTile(entry)).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBackgroundLayer(),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text("Sala Pomodoro"),
            actions: [
              IconButton(icon: const Icon(Icons.history_toggle_off), onPressed: _openHistorySheet),
              IconButton(icon: const Icon(Icons.tune), onPressed: openCustomizationDialog),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 14),
                  _buildTimerCard(),
                  const SizedBox(height: 14),
                  _buildPresets(),
                  const SizedBox(height: 14),
                  _buildStats(),
                  const SizedBox(height: 14),
                  _buildHistoryPreview(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget separado para el diálogo de selección de tareas con filtro
class _TaskSelectionDialog extends StatefulWidget {
  final List<Tarea> tareasUsuario;
  final Map<String, String> tareaProyectos;
  final List<String> proyectosUnicos;
  final Function(Tarea?) onTareaSelected;
  final Tarea? currentlySelected;

  const _TaskSelectionDialog({
    required this.tareasUsuario,
    required this.tareaProyectos,
    required this.proyectosUnicos,
    required this.onTareaSelected,
    this.currentlySelected,
  });

  @override
  State<_TaskSelectionDialog> createState() => _TaskSelectionDialogState();
}

class _TaskSelectionDialogState extends State<_TaskSelectionDialog> {
  String? _proyectoFiltrado; // null = todos los proyectos

  List<Tarea> get _tareasFiltradas {
    if (_proyectoFiltrado == null) return widget.tareasUsuario;
    return widget.tareasUsuario.where((tarea) {
      return widget.tareaProyectos[tarea.titulo] == _proyectoFiltrado;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A0F1F), Color(0xFF101A3D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_ind,
                      color: Colors.orangeAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Seleccionar Tarea",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Elige la tarea en la que trabajarás",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Filtro por proyectos
            if (widget.proyectosUnicos.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: "Todos",
                        count: widget.tareasUsuario.length,
                        isSelected: _proyectoFiltrado == null,
                        onTap: () => setState(() => _proyectoFiltrado = null),
                      ),
                      const SizedBox(width: 8),
                      ...widget.proyectosUnicos.map((proyecto) {
                        final count = widget.tareasUsuario.where((tarea) {
                          return widget.tareaProyectos[tarea.titulo] == proyecto;
                        }).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            label: proyecto,
                            count: count,
                            isSelected: _proyectoFiltrado == proyecto,
                            onTap: () => setState(() => _proyectoFiltrado = proyecto),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            // Content
            Flexible(
              child: _tareasFiltradas.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _proyectoFiltrado == null
                                ? "No tienes tareas pendientes"
                                : "No hay tareas en este proyecto",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "¡Genial! Puedes trabajar en modo libre",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: _tareasFiltradas.length,
                      itemBuilder: (context, index) {
                        Tarea tarea = _tareasFiltradas[index];
                        final isSelected = widget.currentlySelected == tarea;
                        final proyecto = widget.tareaProyectos[tarea.titulo] ?? "Proyecto";

                        // Determinar color por prioridad
                        Color priorityColor;
                        String priorityLabel;
                        IconData priorityIcon;

                        switch (tarea.prioridad) {
                          case 1:
                            priorityColor = Colors.redAccent;
                            priorityLabel = 'Alta';
                            priorityIcon = Icons.priority_high;
                            break;
                          case 2:
                            priorityColor = Colors.orangeAccent;
                            priorityLabel = 'Media';
                            priorityIcon = Icons.remove;
                            break;
                          case 3:
                            priorityColor = Colors.greenAccent;
                            priorityLabel = 'Baja';
                            priorityIcon = Icons.arrow_downward;
                            break;
                          default:
                            priorityColor = Colors.blueAccent;
                            priorityLabel = 'Normal';
                            priorityIcon = Icons.info_outline;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.orangeAccent.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.orangeAccent : Colors.white10,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onTareaSelected(tarea);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Radio button personalizado
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? Colors.orangeAccent : Colors.white30,
                                          width: 2,
                                        ),
                                        color: isSelected ? Colors.orangeAccent : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),

                                    // Contenido de la tarea
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Título de la tarea
                                          Text(
                                            tarea.titulo,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),

                                          // Chips de información
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              // Proyecto (solo si no hay filtro)
                                              if (_proyectoFiltrado == null)
                                                _buildInfoChip(
                                                  Icons.folder_outlined,
                                                  proyecto,
                                                  Colors.cyanAccent,
                                                ),

                                              // Prioridad
                                              _buildInfoChip(
                                                priorityIcon,
                                                priorityLabel,
                                                priorityColor,
                                              ),

                                              // Fecha (si existe)
                                              if (tarea.fecha != null)
                                                _buildInfoChip(
                                                  Icons.calendar_today,
                                                  _formatDate(tarea.fecha!),
                                                  Colors.pinkAccent,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Ícono de selección
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orangeAccent.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.task_alt,
                                          color: Colors.orangeAccent,
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Footer
            if (_tareasFiltradas.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${_tareasFiltradas.length} tarea${_tareasFiltradas.length > 1 ? 's' : ''}${_proyectoFiltrado != null ? ' en $_proyectoFiltrado' : ' disponible${_tareasFiltradas.length > 1 ? 's' : ''}'}",
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onTareaSelected(null);
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text("Sin tarea"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper para crear chips de filtro
  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.orangeAccent.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.orangeAccent : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.orangeAccent : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.orangeAccent.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper para crear chips de información
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Helper para formatear fechas
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return "Hoy";
    if (dateOnly == tomorrow) return "Mañana";

    final diff = dateOnly.difference(today).inDays;
    if (diff > 0 && diff < 7) return "En $diff días";

    return "${date.day}/${date.month}";
  }
}

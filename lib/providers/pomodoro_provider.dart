import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider global para sincronizar el estado del Pomodoro
/// entre el widget compacto y la página principal
class PomodoroProvider with ChangeNotifier {
  // Configuración
  int workDuration = 25;
  int breakDuration = 5;
  int longBreakDuration = 15;
  int sessionsUntilLongBreak = 4;

  // Estado del timer
  int remainingSeconds = 1500; // 25 minutos por defecto
  bool isRunning = false;
  bool isWorkInterval = true;
  bool isLongBreak = false;

  // Contadores
  int completedPomodoros = 0;
  int completedWorkSessions = 0;
  String currentTask = "Sin tarea";

  Timer? _timer;

  PomodoroProvider() {
    _loadTimerState();
  }

  int get currentIntervalTotalSeconds {
    if (isWorkInterval) {
      return workDuration * 60;
    } else if (isLongBreak) {
      return longBreakDuration * 60;
    } else {
      return breakDuration * 60;
    }
  }

  double get progress {
    if (currentIntervalTotalSeconds == 0) return 0;
    return 1 - (remainingSeconds / currentIntervalTotalSeconds);
  }

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ===== PERSISTENCIA =====
  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro.remainingSeconds', remainingSeconds);
    await prefs.setBool('pomodoro.isRunning', isRunning);
    await prefs.setBool('pomodoro.isWorkInterval', isWorkInterval);
    await prefs.setBool('pomodoro.isLongBreak', isLongBreak);
    await prefs.setInt('pomodoro.completedPomodoros', completedPomodoros);
    await prefs.setInt('pomodoro.completedWorkSessions', completedWorkSessions);
    await prefs.setString('pomodoro.currentTask', currentTask);
    await prefs.setInt('pomodoro.workDuration', workDuration);
    await prefs.setInt('pomodoro.breakDuration', breakDuration);
    await prefs.setInt('pomodoro.longBreakDuration', longBreakDuration);
    await prefs.setInt('pomodoro.lastSaveTime', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTime = prefs.getInt('pomodoro.lastSaveTime');

    workDuration = prefs.getInt('pomodoro.workDuration') ?? 25;
    breakDuration = prefs.getInt('pomodoro.breakDuration') ?? 5;
    longBreakDuration = prefs.getInt('pomodoro.longBreakDuration') ?? 15;
    remainingSeconds = prefs.getInt('pomodoro.remainingSeconds') ?? (workDuration * 60);
    isRunning = prefs.getBool('pomodoro.isRunning') ?? false;
    isWorkInterval = prefs.getBool('pomodoro.isWorkInterval') ?? true;
    isLongBreak = prefs.getBool('pomodoro.isLongBreak') ?? false;
    completedPomodoros = prefs.getInt('pomodoro.completedPomodoros') ?? 0;
    completedWorkSessions = prefs.getInt('pomodoro.completedWorkSessions') ?? 0;
    currentTask = prefs.getString('pomodoro.currentTask') ?? "Sin tarea";

    // Si el timer estaba corriendo, calcular tiempo transcurrido
    if (savedTime != null && isRunning) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - savedTime;
      final elapsedSeconds = (elapsed / 1000).floor();

      remainingSeconds = (remainingSeconds - elapsedSeconds).clamp(0, currentIntervalTotalSeconds);

      // Si se acabó el tiempo mientras la app estaba cerrada
      if (remainingSeconds <= 0) {
        completeInterval();
      } else {
        // Reanudar timer
        startTimer();
      }
    }

    notifyListeners();
  }

  // ===== CONTROL DEL TIMER =====
  void startTimer() {
    if (isRunning) return;

    isRunning = true;
    _saveTimerState();
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        // Guardar cada 10 segundos
        if (remainingSeconds % 10 == 0) {
          _saveTimerState();
        }
        notifyListeners();
      } else {
        completeInterval();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    isRunning = false;
    _saveTimerState();
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    isRunning = false;
    remainingSeconds = currentIntervalTotalSeconds;
    _saveTimerState();
    notifyListeners();
  }

  void completeInterval() {
    _timer?.cancel();

    if (isWorkInterval) {
      completedPomodoros++;
      completedWorkSessions++;

      // Verificar si es hora de un descanso largo
      if (completedPomodoros % sessionsUntilLongBreak == 0) {
        isLongBreak = true;
      }
      isWorkInterval = false;
    } else {
      isWorkInterval = true;
      isLongBreak = false;
    }

    remainingSeconds = currentIntervalTotalSeconds;
    isRunning = false;
    _saveTimerState();
    notifyListeners();
  }

  void skipInterval() {
    _timer?.cancel();
    completeInterval();
  }

  void setCurrentTask(String task) {
    currentTask = task;
    _saveTimerState();
    notifyListeners();
  }

  void updateSettings({
    int? newWorkDuration,
    int? newBreakDuration,
    int? newLongBreakDuration,
    int? newSessionsUntilLongBreak,
  }) {
    if (newWorkDuration != null) workDuration = newWorkDuration;
    if (newBreakDuration != null) breakDuration = newBreakDuration;
    if (newLongBreakDuration != null) longBreakDuration = newLongBreakDuration;
    if (newSessionsUntilLongBreak != null) sessionsUntilLongBreak = newSessionsUntilLongBreak;

    _saveTimerState();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _saveTimerState();
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Widget compacto de Pomodoro para usar en overlay global
///
/// Versión minimalista del Pomodoro que se puede mostrar flotante
/// en todas las pantallas de la aplicación.
///
/// ✅ Incluye persistencia completa y notificaciones
class PomodoroCompactWidget extends StatefulWidget {
  const PomodoroCompactWidget({Key? key}) : super(key: key);

  @override
  State<PomodoroCompactWidget> createState() => _PomodoroCompactWidgetState();
}

class _PomodoroCompactWidgetState extends State<PomodoroCompactWidget> {
  int workDuration = 25;
  int breakDuration = 5;

  int remainingSeconds = 1500; // 25 minutos por defecto
  bool isRunning = false;
  bool isWorkInterval = true;

  Timer? timer;

  // Plugin de notificaciones
  final FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadTimerState(); // Cargar estado completo del timer
  }

  @override
  void dispose() {
    _saveTimerState(); // Guardar estado antes de cerrar
    timer?.cancel();
    super.dispose();
  }

  // ===== NOTIFICACIONES =====
  Future<void> _initNotifications() async {
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

  void _showNotification(String title, String body) async {
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
      icon: '@mipmap/ic_launcher',
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }

  // ===== PERSISTENCIA COMPLETA DEL ESTADO =====
  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro_compact.remainingSeconds', remainingSeconds);
    await prefs.setBool('pomodoro_compact.isRunning', isRunning);
    await prefs.setBool('pomodoro_compact.isWorkInterval', isWorkInterval);
    await prefs.setInt('pomodoro_compact.workDuration', workDuration);
    await prefs.setInt('pomodoro_compact.breakDuration', breakDuration);
    await prefs.setInt('pomodoro_compact.lastSaveTime', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTime = prefs.getInt('pomodoro_compact.lastSaveTime');

    setState(() {
      workDuration = prefs.getInt('pomodoro_compact.workDuration') ?? 25;
      breakDuration = prefs.getInt('pomodoro_compact.breakDuration') ?? 5;
      remainingSeconds = prefs.getInt('pomodoro_compact.remainingSeconds') ?? (workDuration * 60);
      isRunning = prefs.getBool('pomodoro_compact.isRunning') ?? false;
      isWorkInterval = prefs.getBool('pomodoro_compact.isWorkInterval') ?? true;
    });

    // Si el timer estaba corriendo, calcular tiempo transcurrido
    if (savedTime != null && isRunning) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - savedTime;
      final elapsedSeconds = (elapsed / 1000).floor();

      setState(() {
        remainingSeconds = (remainingSeconds - elapsedSeconds).clamp(0, _currentIntervalTotalSeconds);

        // Si se acabó el tiempo mientras la app estaba cerrada
        if (remainingSeconds <= 0) {
          _completeInterval();
        } else {
          // Reanudar timer
          _startTimer();
        }
      });
    }
  }

  int get _currentIntervalTotalSeconds {
    return (isWorkInterval ? workDuration : breakDuration) * 60;
  }

  double get _progress {
    if (_currentIntervalTotalSeconds == 0) return 0;
    return 1 - (remainingSeconds / _currentIntervalTotalSeconds);
  }

  String get _formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    if (isRunning) return;

    setState(() => isRunning = true);
    _saveTimerState(); // Guardar al iniciar

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
          // Guardar cada 10 segundos para no saturar
          if (remainingSeconds % 10 == 0) {
            _saveTimerState();
          }
        } else {
          _completeInterval();
        }
      });
    });
  }

  void _pauseTimer() {
    timer?.cancel();
    setState(() => isRunning = false);
    _saveTimerState(); // Guardar al pausar
  }

  void _resetTimer() {
    timer?.cancel();
    setState(() {
      isRunning = false;
      remainingSeconds = _currentIntervalTotalSeconds;
    });
    _saveTimerState(); // Guardar al resetear
  }

  void _completeInterval() {
    timer?.cancel();

    setState(() {
      isWorkInterval = !isWorkInterval;
      remainingSeconds = _currentIntervalTotalSeconds;
      isRunning = false;
    });

    _saveTimerState(); // Guardar al completar

    // Mostrar notificación REAL en lugar de SnackBar
    if (isWorkInterval) {
      _showNotification(
        "⏰ Descanso terminado",
        "Hora de volver a concentrarse. ¡Vamos!",
      );
    } else {
      _showNotification(
        "🎉 ¡Pomodoro completado!",
        "Completaste un pomodoro de $workDuration minutos. Toma un descanso.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Indicador de modo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isWorkInterval
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isWorkInterval ? '🎯 TRABAJO' : '☕ DESCANSO',
              style: TextStyle(
                color: isWorkInterval ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Timer circular
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progreso circular
                CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isWorkInterval ? Colors.red : Colors.green,
                  ),
                ),
                // Tiempo restante
                Text(
                  _formattedTime,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Controles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón reset
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _resetTimer,
                tooltip: 'Reiniciar',
                color: Colors.grey.shade700,
              ),

              const SizedBox(width: 8),

              // Botón play/pause
              Container(
                decoration: BoxDecoration(
                  color: isRunning ? Colors.orange : Colors.green,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: isRunning ? _pauseTimer : _startTimer,
                  tooltip: isRunning ? 'Pausar' : 'Iniciar',
                ),
              ),

              const SizedBox(width: 8),

              // Botón skip
              IconButton(
                icon: const Icon(Icons.skip_next, size: 20),
                onPressed: () {
                  timer?.cancel();
                  _completeInterval();
                },
                tooltip: 'Saltar',
                color: Colors.grey.shade700,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Info texto
          Text(
            isWorkInterval
              ? 'Enfócate en tu tarea'
              : 'Relájate un momento',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

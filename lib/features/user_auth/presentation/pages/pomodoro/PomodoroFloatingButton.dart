import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/pomodoro/PomodoroPage.dart';

/// Botón flotante compacto del Pomodoro con timer persistente
///
/// Muestra el countdown del timer directamente en el botón
/// ✅ Persistencia completa
/// ✅ Notificaciones persistentes en background
/// ✅ Contador visible en la notificación
/// ✅ Diseño simple y compacto
class PomodoroFloatingButton extends StatefulWidget {
  const PomodoroFloatingButton({Key? key}) : super(key: key);

  @override
  State<PomodoroFloatingButton> createState() => _PomodoroFloatingButtonState();
}

class _PomodoroFloatingButtonState extends State<PomodoroFloatingButton> with WidgetsBindingObserver {
  int workDuration = 25;
  int breakDuration = 5;

  int remainingSeconds = 1500; // 25 minutos por defecto
  bool isRunning = false;
  bool isWorkInterval = true;
  String currentTask = ""; // Tarea actual

  Timer? timer;

  // Plugin de notificaciones
  final FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ID de la notificación persistente
  static const int _persistentNotificationId = 100;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestNotificationPermission();
    _initNotifications();
    _loadTimerState();
  }

  // Solicitar permiso de notificaciones (Android 13+)
  Future<void> _requestNotificationPermission() async {
    final plugin = localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.requestNotificationsPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimerState();
    timer?.cancel();
    _clearPersistentNotification();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cuando la app va a background, guardar el estado
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveTimerState();
    }
    // Cuando vuelve a foreground, recargar
    else if (state == AppLifecycleState.resumed) {
      _loadTimerState();
    }
  }

  // ===== NOTIFICACIONES =====
  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    await localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Al tocar la notificación, abrir la app
        if (details.id == _persistentNotificationId) {
          _toggleTimer();
        }
      },
    );

    // Canal para la notificación persistente
    const androidChannelPersistent = AndroidNotificationChannel(
      'pomodoro_persistent',
      'Pomodoro Activo',
      description: 'Muestra el timer del Pomodoro en tiempo real',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    // Canal para notificaciones de finalización
    const androidChannelComplete = AndroidNotificationChannel(
      'pomodoro_complete',
      'Pomodoro Completado',
      description: 'Notificaciones cuando termina un intervalo Pomodoro',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final plugin = localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await plugin?.createNotificationChannel(androidChannelPersistent);
    await plugin?.createNotificationChannel(androidChannelComplete);
  }

  Future<void> _updatePersistentNotification() async {
    if (!isRunning) {
      await _clearPersistentNotification();
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'pomodoro_persistent',
      'Pomodoro Activo',
      channelDescription: 'Muestra el timer del Pomodoro en tiempo real',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      enableLights: false,
      ongoing: true, // No se puede deslizar para cerrar
      autoCancel: false,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
      // Botones de acción
      actions: [
        AndroidNotificationAction(
          'pause',
          '⏸ Pausar',
          showsUserInterface: false,
        ),
      ],
    );

    final title = isWorkInterval ? '🍅 Pomodoro en progreso' : '☕ Descanso en progreso';

    // Construir el texto de la notificación con el timer y la tarea
    String notificationText = _formattedTime;
    if (currentTask.isNotEmpty) {
      notificationText += '\n📝 $currentTask';
    }

    await localNotificationsPlugin.show(
      _persistentNotificationId,
      title,
      notificationText,
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> _showTaskInputDialog() async {
    final TextEditingController controller = TextEditingController(text: currentTask);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿En qué estás trabajando?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ej: Estudiar para examen de matemáticas',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        currentTask = result;
      });
      _saveTimerState();
      if (isRunning) {
        _updatePersistentNotification();
      }
    }
  }

  Future<void> _clearPersistentNotification() async {
    await localNotificationsPlugin.cancel(_persistentNotificationId);
  }

  void _showCompletionNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'pomodoro_complete',
      'Pomodoro Completado',
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

  // ===== PERSISTENCIA =====
  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro.remainingSeconds', remainingSeconds);
    await prefs.setBool('pomodoro.isRunning', isRunning);
    await prefs.setBool('pomodoro.isWorkInterval', isWorkInterval);
    await prefs.setInt('pomodoro.workDuration', workDuration);
    await prefs.setInt('pomodoro.breakDuration', breakDuration);
    await prefs.setString('pomodoro.currentTask', currentTask);
    await prefs.setInt('pomodoro.lastSaveTime', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTime = prefs.getInt('pomodoro.lastSaveTime');

    setState(() {
      workDuration = prefs.getInt('pomodoro.workDuration') ?? 25;
      breakDuration = prefs.getInt('pomodoro.breakDuration') ?? 5;
      remainingSeconds = prefs.getInt('pomodoro.remainingSeconds') ?? (workDuration * 60);
      isRunning = prefs.getBool('pomodoro.isRunning') ?? false;
      isWorkInterval = prefs.getBool('pomodoro.isWorkInterval') ?? true;
      currentTask = prefs.getString('pomodoro.currentTask') ?? "";
    });

    // Si el timer estaba corriendo, calcular tiempo transcurrido
    if (savedTime != null && isRunning) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - savedTime;
      final elapsedSeconds = (elapsed / 1000).floor();

      setState(() {
        remainingSeconds = (remainingSeconds - elapsedSeconds).clamp(0, _currentIntervalTotalSeconds);

        if (remainingSeconds <= 0) {
          _completeInterval();
        } else {
          _startTimer();
        }
      });
    }
  }

  int get _currentIntervalTotalSeconds {
    return (isWorkInterval ? workDuration : breakDuration) * 60;
  }

  String get _formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ===== TIMER =====
  void _startTimer() {
    if (isRunning) return;

    setState(() => isRunning = true);
    _saveTimerState();
    _updatePersistentNotification();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });

        // Actualizar notificación cada segundo (sin esperar)
        _updatePersistentNotification();

        // Guardar cada 10 segundos
        if (remainingSeconds % 10 == 0) {
          _saveTimerState();
        }
      } else {
        _completeInterval();
      }
    });
  }

  void _pauseTimer() {
    timer?.cancel();
    setState(() => isRunning = false);
    _saveTimerState();
    _clearPersistentNotification();
  }

  void _completeInterval() {
    timer?.cancel();

    setState(() {
      isWorkInterval = !isWorkInterval;
      remainingSeconds = _currentIntervalTotalSeconds;
      isRunning = false;
    });

    _saveTimerState();
    _clearPersistentNotification();

    // Notificación de finalización
    if (isWorkInterval) {
      _showCompletionNotification(
        "⏰ Descanso terminado",
        "Hora de volver a concentrarse. ¡Vamos!",
      );
    } else {
      _showCompletionNotification(
        "🎉 ¡Pomodoro completado!",
        "Completaste un pomodoro de $workDuration minutos. Toma un descanso.",
      );
    }
  }

  void _toggleTimer() {
    if (isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _openFullPage() async {
    // Pausar el timer del botón flotante antes de abrir la página
    if (isRunning) {
      timer?.cancel();
      setState(() => isRunning = false);
      _saveTimerState();
      // NO limpiar la notificación aquí, la página completa la manejará
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PomodoroPage(),
      ),
    );

    // Al volver, recargar el estado por si cambió algo
    await _loadTimerState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón para configurar tarea actual
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: currentTask.isEmpty
                ? [Color(0xFF95A5A6), Color(0xFF7F8C8D)]
                : [Color(0xFF9B59B6), Color(0xFF8E44AD)],
            ),
            boxShadow: [
              BoxShadow(
                color: (currentTask.isEmpty ? Color(0xFF95A5A6) : Color(0xFF9B59B6))
                    .withValues(alpha: 0.3),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: FloatingActionButton(
            mini: true,
            heroTag: "pomodoro_task",
            onPressed: _showTaskInputDialog,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Icon(
              currentTask.isEmpty ? Icons.edit_note : Icons.check_circle,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Botón para ir a la página completa (Settings)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3498DB).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: FloatingActionButton(
            mini: true,
            heroTag: "pomodoro_settings",
            onPressed: _openFullPage,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Botón principal del timer
        GestureDetector(
          onTap: _toggleTimer,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isWorkInterval
                    ? [Color(0xFFE74C3C), Color(0xFFC0392B)]
                    : [Color(0xFF27AE60), Color(0xFF229954)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isWorkInterval ? Color(0xFFE74C3C) : Color(0xFF27AE60))
                      .withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Botón principal
                FloatingActionButton(
                  heroTag: "pomodoro",
                  onPressed: null, // El GestureDetector maneja los toques
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Icon(
                    isRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                // Timer superpuesto
                if (isRunning || remainingSeconds < _currentIntervalTotalSeconds)
                  Positioned(
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _formattedTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

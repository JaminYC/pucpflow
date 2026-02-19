import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─── Handler FCM background (top-level function requerida por FCM) ──────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 [FCM Background] ${message.notification?.title}');
}

// ─── Modelo de notificación in-app ──────────────────────────────────────────
class AppNotificacion {
  final String id;
  final String titulo;
  final String cuerpo;
  final String tipo;
  final DateTime fecha;
  final bool leida;
  final String? proyectoId;
  final String? tareaId;
  final String? proyectoNombre;

  AppNotificacion({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.tipo,
    required this.fecha,
    this.leida = false,
    this.proyectoId,
    this.tareaId,
    this.proyectoNombre,
  });

  factory AppNotificacion.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppNotificacion(
      id: doc.id,
      titulo: d['titulo'] ?? '',
      cuerpo: d['cuerpo'] ?? '',
      tipo: d['tipo'] ?? 'general',
      fecha: d['fecha'] is Timestamp
          ? (d['fecha'] as Timestamp).toDate()
          : DateTime.now(),
      leida: d['leida'] ?? false,
      proyectoId: d['proyectoId'],
      tareaId: d['tareaId'],
      proyectoNombre: d['proyectoNombre'],
    );
  }

  IconData get icono {
    switch (tipo) {
      case 'tarea_asignada': return Icons.assignment_ind;
      case 'tarea_completada': return Icons.check_circle;
      case 'fecha_cambiada': return Icons.event;
      case 'comentario': return Icons.comment;
      case 'estado_cambiado': return Icons.swap_horiz;
      case 'mencionado': return Icons.alternate_email;
      default: return Icons.notifications;
    }
  }

  Color get color {
    switch (tipo) {
      case 'tarea_asignada': return const Color(0xFF8B5CF6);
      case 'tarea_completada': return const Color(0xFF10B981);
      case 'fecha_cambiada': return const Color(0xFFF59E0B);
      case 'comentario': return const Color(0xFF3B82F6);
      case 'estado_cambiado': return const Color(0xFF6366F1);
      default: return Colors.white54;
    }
  }

  String get emoji {
    switch (tipo) {
      case 'tarea_asignada': return '📋';
      case 'tarea_completada': return '✅';
      case 'fecha_cambiada': return '📅';
      case 'comentario': return '💬';
      case 'estado_cambiado': return '🔄';
      case 'mencionado': return '👋';
      default: return '🔔';
    }
  }
}

// ─── Servicio central de notificaciones ─────────────────────────────────────
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'pucpflow_tareas';
  static const _channelName = 'PucpFlow - Tareas y Proyectos';

  bool _initialized = false;

  // ── Inicialización única ─────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Pedir permisos FCM
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 2. Configurar local notifications (móvil)
    if (!kIsWeb) {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _local.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (resp) {
          debugPrint('🔔 Notif tapped: ${resp.payload}');
        },
      );

      const channel = AndroidNotificationChannel(
        _channelId, _channelName,
        description: 'Alertas de tareas, asignaciones y actividad del equipo',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 3. Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 4. Notificaciones cuando la app está en foreground
    FirebaseMessaging.onMessage.listen(_manejarMensajeForeground);

    // 5. Guardar token FCM del usuario
    await _guardarToken();
  }

  Future<void> _guardarToken() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      String? token;
      if (kIsWeb) {
        try {
          // VAPID key de Firebase Console (opcional)
          token = await _fcm.getToken();
        } catch (_) {}
      } else {
        token = await _fcm.getToken();
      }

      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': token,
          'fcmPlatforma': kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase(),
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('✅ FCM Token: ${token.substring(0, 30)}...');
      }

      // Auto-renovar token
      _fcm.onTokenRefresh.listen((t) async {
        final u = FirebaseAuth.instance.currentUser?.uid;
        if (u != null) {
          await FirebaseFirestore.instance.collection('users').doc(u).set(
            {'fcmToken': t, 'fcmUpdatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true),
          );
        }
      });
    } catch (e) {
      debugPrint('⚠️ FCM token error: $e');
    }
  }

  void _manejarMensajeForeground(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null || kIsWeb) return;

    _local.show(
      message.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── API pública ──────────────────────────────────────────────────────────

  /// Stream reactivo de todas las notificaciones del usuario
  static Stream<List<AppNotificacion>> streamNotificaciones(String uid) {
    return FirebaseFirestore.instance
        .collection('notificaciones')
        .doc(uid)
        .collection('items')
        .orderBy('fecha', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(AppNotificacion.fromFirestore).toList());
  }

  /// Stream del contador de no leídas (para el badge)
  static Stream<int> streamNoLeidas(String uid) {
    return FirebaseFirestore.instance
        .collection('notificaciones')
        .doc(uid)
        .collection('items')
        .where('leida', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Marcar una notificación como leída
  static Future<void> marcarLeida(String uid, String id) async {
    await FirebaseFirestore.instance
        .collection('notificaciones').doc(uid)
        .collection('items').doc(id)
        .update({'leida': true});
  }

  /// Marcar todas como leídas
  static Future<void> marcarTodasLeidas(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('notificaciones').doc(uid)
        .collection('items')
        .where('leida', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) batch.update(d.reference, {'leida': true});
    await batch.commit();
  }

  /// Eliminar una notificación
  static Future<void> eliminar(String uid, String id) async {
    await FirebaseFirestore.instance
        .collection('notificaciones').doc(uid)
        .collection('items').doc(id)
        .delete();
  }

  /// Crear una notificación in-app para un usuario (desde el cliente)
  static Future<void> crear({
    required String uid,
    required String titulo,
    required String cuerpo,
    required String tipo,
    String? proyectoId,
    String? tareaId,
    String? proyectoNombre,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('notificaciones').doc(uid)
          .collection('items')
          .add({
        'titulo': titulo,
        'cuerpo': cuerpo,
        'tipo': tipo,
        'fecha': FieldValue.serverTimestamp(),
        'leida': false,
        'proyectoId': proyectoId,
        'tareaId': tareaId,
        'proyectoNombre': proyectoNombre,
      });
    } catch (e) {
      debugPrint('⚠️ Error creando notificación: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pucpflow/utils/notification_service.dart';

/// Campana de notificaciones para el AppBar
/// Muestra un badge con el conteo de no leídas y abre el panel al tocar
class NotificacionesBell extends StatelessWidget {
  const NotificacionesBell({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: NotificationService.streamNoLeidas(uid),
      builder: (context, snap) {
        final noLeidas = snap.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                noLeidas > 0 ? Icons.notifications_active : Icons.notifications_outlined,
                color: noLeidas > 0 ? const Color(0xFFF59E0B) : Colors.white70,
                size: 22,
              ),
              tooltip: 'Notificaciones',
              onPressed: () => _mostrarPanelNotificaciones(context, uid),
            ),
            if (noLeidas > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      noLeidas > 9 ? '9+' : '$noLeidas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _mostrarPanelNotificaciones(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PanelNotificaciones(uid: uid),
    );
  }
}

// ─── Panel deslizable de notificaciones ────────────────────────────────────
class _PanelNotificaciones extends StatelessWidget {
  final String uid;
  const _PanelNotificaciones({required this.uid});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0E27),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Notificaciones',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => NotificationService.marcarTodasLeidas(uid),
                    icon: const Icon(Icons.done_all, size: 14, color: Color(0xFF8B5CF6)),
                    label: const Text('Marcar leídas', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 12)),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Lista
            Expanded(
              child: StreamBuilder<List<AppNotificacion>>(
                stream: NotificationService.streamNotificaciones(uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
                  }

                  final notifs = snap.data ?? [];

                  if (notifs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 52, color: Colors.white.withOpacity(0.1)),
                          const SizedBox(height: 14),
                          const Text('Sin notificaciones', style: TextStyle(color: Colors.white24, fontSize: 15)),
                          const SizedBox(height: 6),
                          const Text(
                            'Te avisaremos cuando te asignen una tarea\no haya actividad en tus proyectos',
                            style: TextStyle(color: Colors.white12, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifs.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1, indent: 60),
                    itemBuilder: (ctx, i) => _NotifItem(uid: uid, notif: notifs[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Item individual de notificación ───────────────────────────────────────
class _NotifItem extends StatelessWidget {
  final String uid;
  final AppNotificacion notif;
  const _NotifItem({required this.uid, required this.notif});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _timeAgo(notif.fecha);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withOpacity(0.15),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => NotificationService.eliminar(uid, notif.id),
      child: InkWell(
        onTap: () => NotificationService.marcarLeida(uid, notif.id),
        child: Container(
          color: notif.leida ? Colors.transparent : const Color(0xFF8B5CF6).withOpacity(0.05),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícono tipo
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: notif.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(notif.emoji, style: const TextStyle(fontSize: 17)),
                ),
              ),
              const SizedBox(width: 12),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.titulo,
                            style: TextStyle(
                              color: notif.leida ? Colors.white54 : Colors.white,
                              fontSize: 13,
                              fontWeight: notif.leida ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notif.leida)
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B5CF6),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.cuerpo,
                      style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (notif.proyectoNombre != null) ...[
                          Icon(Icons.folder_outlined, size: 11, color: Colors.white24),
                          const SizedBox(width: 3),
                          Text(
                            notif.proyectoNombre!,
                            style: const TextStyle(color: Colors.white24, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(timeAgo, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return DateFormat('dd/MM/yy').format(fecha);
  }
}

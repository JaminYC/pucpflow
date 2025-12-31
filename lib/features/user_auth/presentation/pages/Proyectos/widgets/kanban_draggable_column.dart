import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';

/// Columna Kanban con soporte para drag & drop
class KanbanDraggableColumn extends StatelessWidget {
  final String titulo;
  final List<Tarea> tareas;
  final Color color;
  final IconData icono;
  final String estadoObjetivo; // 'pendiente', 'en_progreso', 'completada'
  final void Function(Tarea tarea, String nuevoEstado) onTareaMoved;
  final void Function(Tarea tarea) onTareaTapped;
  final void Function(Tarea tarea, bool completado, String userId) onCheckboxChanged;
  final Map<String, String> nombreResponsables;
  final String userId;

  const KanbanDraggableColumn({
    super.key,
    required this.titulo,
    required this.tareas,
    required this.color,
    required this.icono,
    required this.estadoObjetivo,
    required this.onTareaMoved,
    required this.onTareaTapped,
    required this.onCheckboxChanged,
    required this.nombreResponsables,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la columna
          _buildHeader(),

          // Zona de drop
          Expanded(
            child: DragTarget<Tarea>(
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) {
                final tarea = details.data;
                onTareaMoved(tarea, estadoObjetivo);
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isHovering
                        ? color.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: tareas.isEmpty
                      ? _buildEmptyState()
                      : _buildTaskList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${tareas.length}',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              color: color.withOpacity(0.3),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay tareas',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tareas.length,
      itemBuilder: (context, index) {
        return _DraggableTaskCard(
          tarea: tareas[index],
          accentColor: color,
          nombreResponsables: nombreResponsables,
          onTap: () => onTareaTapped(tareas[index]),
          onCheckboxChanged: (value) {
            onCheckboxChanged(tareas[index], value, userId);
          },
        );
      },
    );
  }
}

/// Tarjeta de tarea draggable
class _DraggableTaskCard extends StatelessWidget {
  final Tarea tarea;
  final Color accentColor;
  final Map<String, String> nombreResponsables;
  final VoidCallback onTap;
  final Function(bool value) onCheckboxChanged;

  const _DraggableTaskCard({
    required this.tarea,
    required this.accentColor,
    required this.nombreResponsables,
    required this.onTap,
    required this.onCheckboxChanged,
  });

  Color _getPriorityColor(int prioridad) {
    switch (prioridad) {
      case 3:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 1:
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _colorDesdeUID(String uid) {
    final int hash = uid.hashCode;
    final double hue = 40 + (hash % 280);
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.7).toColor();
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'diseño':
        return Icons.design_services;
      case 'desarrollo':
        return Icons.code;
      case 'testing':
        return Icons.bug_report;
      case 'documentación':
        return Icons.description;
      case 'reunión':
        return Icons.group;
      default:
        return Icons.task;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(tarea.prioridad);

    return LongPressDraggable<Tarea>(
      data: tarea,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E27),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Text(
            tarea.titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCardContent(priorityColor),
      ),
      child: _buildCardContent(priorityColor),
    );
  }

  Widget _buildCardContent(Color priorityColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título con checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox
                    Transform.scale(
                      scale: 0.9,
                      child: Checkbox(
                        value: tarea.completado,
                        activeColor: const Color(0xFF10B981),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            onCheckboxChanged(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Título
                    Expanded(
                      child: Text(
                        tarea.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: tarea.completado ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),

                    // Indicador de prioridad
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Responsables
                if (tarea.responsables.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tarea.responsables.take(3).map((uid) {
                      final nombre = nombreResponsables[uid] ?? 'Usuario';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _colorDesdeUID(uid).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _colorDesdeUID(uid).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              size: 12,
                              color: _colorDesdeUID(uid),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              nombre.split(' ').first,
                              style: TextStyle(
                                color: _colorDesdeUID(uid),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],

                // Metadata
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${tarea.duracion} min',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      _getTipoIcon(tarea.tipoTarea),
                      size: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tarea.tipoTarea,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

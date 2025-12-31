import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';

/// Vista de estadísticas visual y motivacional para proyectos personales
class PersonalStatsView extends StatelessWidget {
  final List<Tarea> tareas;

  const PersonalStatsView({
    super.key,
    required this.tareas,
  });

  @override
  Widget build(BuildContext context) {
    final total = tareas.length;
    final completadas = tareas.where((t) => t.completado).length;
    final pendientes = total - completadas;
    final progreso = total > 0 ? (completadas / total * 100).toInt() : 0;

    // Calcular próximas deadlines (próximos 7 días)
    final ahora = DateTime.now();
    final proximasDeadlines = tareas
        .where((t) => !t.completado && t.fecha != null && t.fecha!.isAfter(ahora))
        .toList()
      ..sort((a, b) => a.fecha!.compareTo(b.fecha!));
    final tareasProximas = proximasDeadlines.take(5).toList();

    // Agrupar tareas por fase
    final tareasPorFase = <String, List<Tarea>>{};
    for (var tarea in tareas) {
      final fase = tarea.fasePMI ?? 'Sin fase';
      tareasPorFase.putIfAbsent(fase, () => []).add(tarea);
    }

    // Distribución de prioridades
    final prioridadBaja = tareas.where((t) => t.prioridad <= 2).length;
    final prioridadMedia = tareas.where((t) => t.prioridad == 3).length;
    final prioridadAlta = tareas.where((t) => t.prioridad >= 4).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 Progreso General GRANDE y Visual
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.3),
                  const Color(0xFF3B82F6).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'Progreso General',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: progreso / 100,
                        strokeWidth: 16,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '$progreso%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$completadas de $total tareas',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniStat('✅', completadas.toString(), 'Completadas', const Color(0xFF10B981)),
                    _buildMiniStat('⏳', pendientes.toString(), 'Pendientes', const Color(0xFFF59E0B)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 📅 Próximas Deadlines
          const Text(
            '📅 Próximas Deadlines',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (tareasProximas.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.celebration, color: Color(0xFF10B981), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¡Sin deadlines próximos! Buen trabajo 🎉',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            )
          else
            ...tareasProximas.map((tarea) {
              final diasRestantes = tarea.fecha!.difference(ahora).inDays;
              final urgente = diasRestantes <= 2;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: urgente
                      ? const Color(0xFFEF4444).withOpacity(0.15)
                      : const Color(0xFF1A1F3A).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: urgente
                        ? const Color(0xFFEF4444).withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: urgente ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        diasRestantes == 0
                            ? '¡Hoy!'
                            : diasRestantes == 1
                                ? 'Mañana'
                                : '$diasRestantes días',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tarea.titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (tarea.fasePMI != null)
                            Text(
                              tarea.fasePMI!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      urgente ? Icons.warning_amber : Icons.calendar_today,
                      color: urgente ? const Color(0xFFEF4444) : Colors.white54,
                      size: 20,
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          // 📊 Progreso por Fase
          const Text(
            '📊 Progreso por Fase',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...tareasPorFase.entries.map((entry) {
            final fase = entry.key;
            final tareas = entry.value;
            final completadasFase = tareas.where((t) => t.completado).length;
            final progresoFase = tareas.isNotEmpty ? completadasFase / tareas.length : 0.0;
            final color = tareas.isNotEmpty ? Color(tareas.first.colorId) : const Color(0xFF8B5CF6);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          fase,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '$completadasFase/${tareas.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progresoFase,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progresoFase * 100).toInt()}% completado',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // 🎯 Distribución de Prioridades
          const Text(
            '🎯 Distribución de Prioridades',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              if (prioridadBaja > 0)
                Expanded(
                  flex: prioridadBaja,
                  child: _buildPriorityBar('Baja', prioridadBaja, const Color(0xFF10B981)),
                ),
              if (prioridadBaja > 0 && prioridadMedia > 0) const SizedBox(width: 4),
              if (prioridadMedia > 0)
                Expanded(
                  flex: prioridadMedia,
                  child: _buildPriorityBar('Media', prioridadMedia, const Color(0xFFF59E0B)),
                ),
              if (prioridadMedia > 0 && prioridadAlta > 0) const SizedBox(width: 4),
              if (prioridadAlta > 0)
                Expanded(
                  flex: prioridadAlta,
                  child: _buildPriorityBar('Alta', prioridadAlta, const Color(0xFFEF4444)),
                ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBar(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

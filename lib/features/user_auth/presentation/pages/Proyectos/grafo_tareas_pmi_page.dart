import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'tarea_model.dart';

/// Página de visualización de flujo de tareas con jerarquía PMI
/// Muestra: Fases → Entregables → Paquetes de Trabajo → Tareas
class GrafoTareasPMIPage extends StatefulWidget {
  final List<Tarea> tareas;
  final Map<String, String> nombreResponsables;

  const GrafoTareasPMIPage({
    super.key,
    required this.tareas,
    required this.nombreResponsables,
  });

  @override
  State<GrafoTareasPMIPage> createState() => _GrafoTareasPMIPageState();
}

class _GrafoTareasPMIPageState extends State<GrafoTareasPMIPage> {
  String vistaActual = 'jerarquia'; // 'jerarquia' o 'recursos'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Flujo de Tareas PMI',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Toggle entre vista de jerarquía y recursos
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'jerarquia',
                label: Text('Fases PMI'),
                icon: Icon(Icons.account_tree),
              ),
              ButtonSegment(
                value: 'recursos',
                label: Text('Recursos'),
                icon: Icon(Icons.people),
              ),
            ],
            selected: {vistaActual},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                vistaActual = newSelection.first;
              });
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.blue;
                }
                return Colors.grey.shade800;
              }),
              foregroundColor: WidgetStateProperty.all(Colors.white),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: vistaActual == 'jerarquia'
          ? _buildVistaJerarquiaPMI()
          : _buildVistaRecursos(),
    );
  }

  // ========================================
  // VISTA: JERARQUÍA PMI
  // ========================================

  Widget _buildVistaJerarquiaPMI() {
    // Agrupar tareas por Fase → Entregable → Paquete
    final Map<String, Map<String, Map<String, List<Tarea>>>> jerarquia = {};

    for (var tarea in widget.tareas) {
      final fase = tarea.fasePMI ?? 'Sin fase';
      final entregable = tarea.entregable ?? 'Sin entregable';
      final paquete = tarea.paqueteTrabajo ?? 'Sin paquete';

      jerarquia.putIfAbsent(fase, () => {});
      jerarquia[fase]!.putIfAbsent(entregable, () => {});
      jerarquia[fase]![entregable]!.putIfAbsent(paquete, () => []);
      jerarquia[fase]![entregable]![paquete]!.add(tarea);
    }

    // Ordenar fases según orden PMI
    final fasesOrdenadas = _ordenarFasesPMI(jerarquia.keys.toList());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: fasesOrdenadas.map((fase) {
        final colorFase = _obtenerColorFase(fase);
        final entregables = jerarquia[fase]!;

        return _buildFaseCard(fase, entregables, colorFase);
      }).toList(),
    );
  }

  Widget _buildFaseCard(
    String nombreFase,
    Map<String, Map<String, List<Tarea>>> entregables,
    Color colorFase,
  ) {
    int totalTareas = 0;
    int tareasCompletadas = 0;

    entregables.forEach((_, paquetes) {
      paquetes.forEach((_, tareas) {
        totalTareas += tareas.length;
        tareasCompletadas += tareas.where((t) => t.completado).length;
      });
    });

    final progreso = totalTareas > 0 ? tareasCompletadas / totalTareas : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorFase, width: 2),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorFase.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorFase, width: 2),
          ),
          child: Icon(_obtenerIconoFase(nombreFase), color: colorFase),
        ),
        title: Text(
          nombreFase,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              '$tareasCompletadas/$totalTareas tareas completadas',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progreso,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(colorFase),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
        children: entregables.entries.map((entregableEntry) {
          return _buildEntregableSection(
            entregableEntry.key,
            entregableEntry.value,
            colorFase,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEntregableSection(
    String nombreEntregable,
    Map<String, List<Tarea>> paquetes,
    Color colorFase,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorFase.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, color: colorFase, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '📦 $nombreEntregable',
                  style: TextStyle(
                    color: colorFase,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...paquetes.entries.map((paqueteEntry) {
            return _buildPaqueteTrabajoSection(
              paqueteEntry.key,
              paqueteEntry.value,
              colorFase,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaqueteTrabajoSection(
    String nombrePaquete,
    List<Tarea> tareas,
    Color colorFase,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nombrePaquete,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorFase.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tareas.length} tareas',
                  style: TextStyle(
                    color: colorFase,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tareas.map((tarea) => _buildTareaItem(tarea, colorFase)),
        ],
      ),
    );
  }

  Widget _buildTareaItem(Tarea tarea, Color colorFase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tarea.completado
            ? Colors.green.shade900.withOpacity(0.3)
            : Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tarea.completado ? Colors.green : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            tarea.completado ? Icons.check_circle : Icons.radio_button_unchecked,
            color: tarea.completado ? Colors.green : Colors.white54,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarea.titulo,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    decoration: tarea.completado
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (tarea.area != 'Sin asignar' && tarea.area != 'General')
                      _buildChip(
                        '👥 ${tarea.area}',
                        Colors.blue.shade700,
                      ),
                    if (tarea.dificultad != null)
                      _buildChip(
                        '🎯 ${tarea.dificultad}',
                        Colors.purple.shade700,
                      ),
                    _buildChip(
                      '⏱️ ${tarea.duracion} min',
                      Colors.indigo.shade700,
                    ),
                    if (tarea.prioridad >= 4)
                      _buildChip(
                        '🔥 Alta prioridad',
                        Colors.red.shade700,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // VISTA: RECURSOS (ÁREAS)
  // ========================================

  Widget _buildVistaRecursos() {
    // Agrupar tareas por área (recurso)
    final Map<String, List<Tarea>> tareasPorRecurso = {};

    for (var tarea in widget.tareas) {
      final recurso = tarea.area;
      tareasPorRecurso.putIfAbsent(recurso, () => []);
      tareasPorRecurso[recurso]!.add(tarea);
    }

    final recursosOrdenados = tareasPorRecurso.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: recursosOrdenados.map((recurso) {
        final tareas = tareasPorRecurso[recurso]!;
        final colorRecurso = _obtenerColorRecurso(recurso);

        return _buildRecursoCard(recurso, tareas, colorRecurso);
      }).toList(),
    );
  }

  Widget _buildRecursoCard(
    String nombreRecurso,
    List<Tarea> tareas,
    Color colorRecurso,
  ) {
    final tareasCompletadas = tareas.where((t) => t.completado).length;
    final progreso = tareas.isNotEmpty ? tareasCompletadas / tareas.length : 0.0;

    // Agrupar tareas por fase dentro del recurso
    final Map<String, List<Tarea>> tareasPorFase = {};
    for (var tarea in tareas) {
      final fase = tarea.fasePMI ?? 'Sin fase';
      tareasPorFase.putIfAbsent(fase, () => []);
      tareasPorFase[fase]!.add(tarea);
    }

    final fasesOrdenadas = _ordenarFasesPMI(tareasPorFase.keys.toList());

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorRecurso, width: 2),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorRecurso.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorRecurso, width: 2),
          ),
          child: Icon(Icons.group, color: colorRecurso),
        ),
        title: Text(
          nombreRecurso,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              '$tareasCompletadas/${tareas.length} tareas completadas',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progreso,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(colorRecurso),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
        children: fasesOrdenadas.map((fase) {
          final tareasEnFase = tareasPorFase[fase]!;
          final colorFase = _obtenerColorFase(fase);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorFase.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_obtenerIconoFase(fase), color: colorFase, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      fase,
                      style: TextStyle(
                        color: colorFase,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorFase.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tareasEnFase.length} tareas',
                        style: TextStyle(
                          color: colorFase,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...tareasEnFase
                    .map((tarea) => _buildTareaItem(tarea, colorFase)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ========================================
  // UTILIDADES
  // ========================================

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<String> _ordenarFasesPMI(List<String> fases) {
    final orden = {
      'Iniciación': 1,
      'Planificación': 2,
      'Ejecución': 3,
      'Monitoreo y Control': 4,
      'Monitoreo': 4,
      'Cierre': 5,
    };

    fases.sort((a, b) {
      final ordenA = orden[a] ?? 999;
      final ordenB = orden[b] ?? 999;
      return ordenA.compareTo(ordenB);
    });

    return fases;
  }

  Color _obtenerColorFase(String fase) {
    switch (fase) {
      case 'Iniciación':
        return const Color(0xFF4CAF50); // Verde
      case 'Planificación':
        return const Color(0xFF2196F3); // Azul
      case 'Ejecución':
        return const Color(0xFFFF9800); // Naranja
      case 'Monitoreo y Control':
      case 'Monitoreo':
        return const Color(0xFF9C27B0); // Púrpura
      case 'Cierre':
        return const Color(0xFF607D8B); // Gris azulado
      default:
        return const Color(0xFF757575); // Gris
    }
  }

  IconData _obtenerIconoFase(String fase) {
    switch (fase) {
      case 'Iniciación':
        return Icons.flag;
      case 'Planificación':
        return Icons.edit_calendar;
      case 'Ejecución':
        return Icons.build;
      case 'Monitoreo y Control':
      case 'Monitoreo':
        return Icons.monitor_heart;
      case 'Cierre':
        return Icons.check_circle;
      default:
        return Icons.work;
    }
  }

  Color _obtenerColorRecurso(String recurso) {
    final hash = recurso.hashCode;
    final paleta = [
      Colors.blue.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.orange.shade600,
      Colors.pink.shade600,
      Colors.cyan.shade600,
      Colors.indigo.shade600,
      Colors.lime.shade700,
    ];
    return paleta[hash % paleta.length];
  }
}

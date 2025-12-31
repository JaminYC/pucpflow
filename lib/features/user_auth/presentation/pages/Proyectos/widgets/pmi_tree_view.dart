import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';

/// Vista de árbol jerárquica para proyectos PMI
/// Muestra: Fase > Entregable > Paquete de Trabajo > Tarea
class PMITreeView extends StatefulWidget {
  final List<Tarea> tareas;
  final void Function(Tarea tarea) onTareaTapped;
  final void Function(Tarea tarea, bool completado, String userId) onCheckboxChanged;
  final Map<String, String> nombreResponsables;
  final String userId;

  const PMITreeView({
    super.key,
    required this.tareas,
    required this.onTareaTapped,
    required this.onCheckboxChanged,
    required this.nombreResponsables,
    required this.userId,
  });

  @override
  State<PMITreeView> createState() => _PMITreeViewState();
}

class _PMITreeViewState extends State<PMITreeView> {
  final Map<String, bool> _expandedFases = {};
  final Map<String, bool> _expandedEntregables = {};
  final Map<String, bool> _expandedPaquetes = {};

  @override
  Widget build(BuildContext context) {
    // Agrupar tareas por jerarquía PMI
    final fases = _agruparPorFase(widget.tareas);

    if (fases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Este proyecto no tiene estructura PMI',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: fases.entries.map((faseEntry) {
        return _buildFaseNode(faseEntry.key, faseEntry.value);
      }).toList(),
    );
  }

  Map<String, Map<String, Map<String, List<Tarea>>>> _agruparPorFase(List<Tarea> tareas) {
    final Map<String, Map<String, Map<String, List<Tarea>>>> fases = {};

    for (var tarea in tareas) {
      if (tarea.fasePMI == null) continue;

      final fase = tarea.fasePMI!;
      final entregable = tarea.entregable ?? 'Sin entregable';
      final paquete = tarea.paqueteTrabajo ?? 'Sin paquete';

      fases.putIfAbsent(fase, () => {});
      fases[fase]!.putIfAbsent(entregable, () => {});
      fases[fase]![entregable]!.putIfAbsent(paquete, () => []);
      fases[fase]![entregable]![paquete]!.add(tarea);
    }

    return fases;
  }

  Widget _buildFaseNode(String fase, Map<String, Map<String, List<Tarea>>> entregables) {
    final isExpanded = _expandedFases[fase] ?? false;
    final colorFase = _getColorFase(fase);
    final totalTareas = entregables.values
        .expand((e) => e.values)
        .expand((t) => t)
        .length;
    final tareasCompletadas = entregables.values
        .expand((e) => e.values)
        .expand((t) => t)
        .where((t) => t.completado)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorFase.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header de Fase
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedFases[fase] = !isExpanded;
                });
              },
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorFase.withOpacity(0.2),
                      colorFase.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                      color: colorFase,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorFase.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconFase(fase),
                        color: colorFase,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fase,
                            style: TextStyle(
                              color: colorFase,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$tareasCompletadas/$totalTareas tareas completadas',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Progress indicator
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        children: [
                          Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                value: totalTareas > 0 ? tareasCompletadas / totalTareas : 0,
                                strokeWidth: 4,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(colorFase),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              '${totalTareas > 0 ? ((tareasCompletadas / totalTareas) * 100).toInt() : 0}%',
                              style: TextStyle(
                                color: colorFase,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Entregables (hijos)
          if (isExpanded)
            ...entregables.entries.map((entregableEntry) {
              return _buildEntregableNode(
                fase,
                entregableEntry.key,
                entregableEntry.value,
                colorFase,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEntregableNode(
    String fase,
    String entregable,
    Map<String, List<Tarea>> paquetes,
    Color colorFase,
  ) {
    final key = '$fase-$entregable';
    final isExpanded = _expandedEntregables[key] ?? false;
    final totalTareas = paquetes.values.expand((t) => t).length;
    final tareasCompletadas = paquetes.values
        .expand((t) => t)
        .where((t) => t.completado)
        .length;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedEntregables[key] = !isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.folder_outlined,
                      color: colorFase.withOpacity(0.7),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entregable,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorFase.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$tareasCompletadas/$totalTareas',
                        style: TextStyle(
                          color: colorFase,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Paquetes de trabajo
          if (isExpanded)
            ...paquetes.entries.map((paqueteEntry) {
              return _buildPaqueteNode(
                key,
                paqueteEntry.key,
                paqueteEntry.value,
                colorFase,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPaqueteNode(
    String parentKey,
    String paquete,
    List<Tarea> tareas,
    Color colorFase,
  ) {
    final key = '$parentKey-$paquete';
    final isExpanded = _expandedPaquetes[key] ?? true; // Por defecto expandido
    final tareasCompletadas = tareas.where((t) => t.completado).length;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedPaquetes[key] = !isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                      color: Colors.white.withOpacity(0.5),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.work_outline,
                      color: colorFase.withOpacity(0.5),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        paquete,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '$tareasCompletadas/${tareas.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tareas
          if (isExpanded)
            ...tareas.map((tarea) => _buildTareaItem(tarea, colorFase)),
        ],
      ),
    );
  }

  Widget _buildTareaItem(Tarea tarea, Color colorFase) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onTareaTapped(tarea),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Transform.scale(
                  scale: 0.8,
                  child: Checkbox(
                    value: tarea.completado,
                    activeColor: const Color(0xFF10B981),
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        widget.onCheckboxChanged(tarea, value, widget.userId);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tarea.titulo,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      decoration: tarea.completado ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (tarea.responsables.isNotEmpty)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _colorDesdeUID(tarea.responsables.first).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (widget.nombreResponsables[tarea.responsables.first] ?? 'U')[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorFase(String fase) {
    switch (fase.toLowerCase()) {
      case 'iniciación':
        return const Color(0xFF10B981);
      case 'planificación':
        return const Color(0xFF3B82F6);
      case 'ejecución':
        return const Color(0xFFF59E0B);
      case 'monitoreo':
      case 'monitoreo y control':
        return const Color(0xFF8B5CF6);
      case 'cierre':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _getIconFase(String fase) {
    switch (fase.toLowerCase()) {
      case 'iniciación':
        return Icons.flag_outlined;
      case 'planificación':
        return Icons.analytics_outlined;
      case 'ejecución':
        return Icons.build_outlined;
      case 'monitoreo':
      case 'monitoreo y control':
        return Icons.trending_up;
      case 'cierre':
        return Icons.check_circle_outline;
      default:
        return Icons.folder_outlined;
    }
  }

  Color _colorDesdeUID(String uid) {
    final int hash = uid.hashCode;
    final double hue = 40 + (hash % 280);
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.7).toColor();
  }
}

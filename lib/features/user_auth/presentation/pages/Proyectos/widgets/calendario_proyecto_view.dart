import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';

/// Vista Gantt por semanas del proyecto.
/// Muestra todas las tareas agrupadas por semana con barras de progreso
/// horizontales, diferenciando estado, prioridad y área.
class CalendarioProyectoView extends StatefulWidget {
  final String proyectoId;

  const CalendarioProyectoView({super.key, required this.proyectoId});

  @override
  State<CalendarioProyectoView> createState() => _CalendarioProyectoViewState();
}

class _CalendarioProyectoViewState extends State<CalendarioProyectoView> {
  List<({String docId, Tarea tarea})> _tareas = [];
  bool _cargando = true;

  // Filtro de estado activo (null = todos)
  String? _filtroEstado;

  static const _purple  = Color(0xFF8B5CF6);
  static const _green   = Color(0xFF10B981);
  static const _amber   = Color(0xFFF59E0B);
  static const _red     = Color(0xFFEF4444);
  static const _blue    = Color(0xFF3B82F6);
  static const _bgCard  = Color(0xFF1A1F3A);
  static const _bgPage  = Color(0xFF0A0E27);

  @override
  void initState() {
    super.initState();
    _cargarTareas();
  }

  Future<void> _cargarTareas() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('proyectos')
          .doc(widget.proyectoId)
          .collection('tareas')
          .get();

      final lista = snap.docs.map((doc) {
        final t = Tarea.fromJson(doc.data());
        return (docId: doc.id, tarea: t);
      }).toList();

      if (mounted) setState(() { _tareas = lista; _cargando = false; });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Fecha relevante para posicionar en Gantt:
  /// prioriza fechaLimite (deadline), luego fechaProgramada, luego fecha legado
  DateTime? _fechaTarea(Tarea t) =>
      t.fechaLimite ?? t.fechaProgramada ?? t.fecha;

  /// Lunes de la semana que contiene [d]
  DateTime _lunesDe(DateTime d) {
    final lun = d.subtract(Duration(days: d.weekday - 1));
    return DateTime(lun.year, lun.month, lun.day);
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'completada':  return _green;
      case 'en_progreso': return _blue;
      default:            return _amber;
    }
  }

  Color _colorPrioridad(int p) {
    if (p >= 3) return _red;
    if (p == 1) return _green;
    return _amber;
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'completada':  return 'Completada';
      case 'en_progreso': return 'En progreso';
      default:            return 'Pendiente';
    }
  }

  String _labelPrioridad(int p) {
    if (p >= 3) return 'Alta';
    if (p == 1) return 'Baja';
    return 'Media';
  }

  // ── Datos derivados ────────────────────────────────────────────────────────

  List<({String docId, Tarea tarea})> get _tareasFiltradas {
    if (_filtroEstado == null) return _tareas;
    return _tareas.where((e) => e.tarea.estado == _filtroEstado).toList();
  }

  /// Agrupa tareas filtradas por semana (lunes). Tareas sin fecha van aparte.
  ({
    List<DateTime> semanas,
    Map<DateTime, List<({String docId, Tarea tarea})>> porSemana,
    List<({String docId, Tarea tarea})> sinFecha,
  }) get _ganttData {
    final Map<DateTime, List<({String docId, Tarea tarea})>> map = {};
    final List<({String docId, Tarea tarea})> sinFecha = [];

    for (final e in _tareasFiltradas) {
      final dt = _fechaTarea(e.tarea);
      if (dt != null) {
        final lun = _lunesDe(dt);
        map.putIfAbsent(lun, () => []).add(e);
      } else {
        sinFecha.add(e);
      }
    }

    final semanas = map.keys.toList()..sort();
    return (semanas: semanas, porSemana: map, sinFecha: sinFecha);
  }

  // ── UI principal ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }

    if (_tareas.isEmpty) {
      return _buildEmpty();
    }

    final total      = _tareas.length;
    final completadas = _tareas.where((e) => e.tarea.estado == 'completada').length;
    final enProgreso = _tareas.where((e) => e.tarea.estado == 'en_progreso').length;
    final pendientes = _tareas.where((e) => e.tarea.estado == 'pendiente').length;
    final sinFechaTotal = _tareas.where((e) => _fechaTarea(e.tarea) == null).length;

    final data = _ganttData;
    final hoy  = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Resumen estadístico ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de progreso global
              Row(
                children: [
                  const Text('Progreso', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const Spacer(),
                  Text(
                    '$completadas/$total tareas',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? completadas / total : 0,
                  minHeight: 7,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(_green),
                ),
              ),
              const SizedBox(height: 10),

              // Chips de resumen + filtro
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filtroChip(null, 'Todos', total, Colors.white54),
                    const SizedBox(width: 6),
                    _filtroChip('completada', 'Listas', completadas, _green),
                    const SizedBox(width: 6),
                    _filtroChip('en_progreso', 'En curso', enProgreso, _blue),
                    const SizedBox(width: 6),
                    _filtroChip('pendiente', 'Pendientes', pendientes, _amber),
                    if (sinFechaTotal > 0) ...[
                      const SizedBox(width: 6),
                      _infoChip('$sinFechaTotal sin fecha', Colors.white24),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 4),

        // ── Leyenda del Gantt ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.bar_chart, size: 13, color: _purple),
              const SizedBox(width: 5),
              const Text('GANTT POR SEMANA',
                  style: TextStyle(color: _purple, fontSize: 10,
                      fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const Spacer(),
              _legendaDot(_green, 'Lista'),
              const SizedBox(width: 8),
              _legendaDot(_blue, 'En curso'),
              const SizedBox(width: 8),
              _legendaDot(_amber, 'Pendiente'),
              const SizedBox(width: 8),
              _legendaDot(_red, 'Alta prio'),
            ],
          ),
        ),

        // ── Gantt scrollable ───────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
            children: [
              // Semanas con tareas
              ...data.semanas.map((lun) {
                final tareasSem = data.porSemana[lun]!;
                final dom = lun.add(const Duration(days: 6));
                final esActual = !hoy.isBefore(lun) && !hoy.isAfter(dom);
                final compSem = tareasSem.where((e) => e.tarea.estado == 'completada').length;

                return _buildSemanaBlock(
                  lunes: lun,
                  domingo: dom,
                  tareas: tareasSem,
                  completadas: compSem,
                  esActual: esActual,
                  hoy: hoy,
                );
              }),

              // Tareas sin fecha
              if (data.sinFecha.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildSinFechaBlock(data.sinFecha),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Bloque de semana ───────────────────────────────────────────────────────

  Widget _buildSemanaBlock({
    required DateTime lunes,
    required DateTime domingo,
    required List<({String docId, Tarea tarea})> tareas,
    required int completadas,
    required bool esActual,
    required DateTime hoy,
  }) {
    final fmt = DateFormat('dd MMM', 'es_ES');
    final pct = tareas.isNotEmpty ? completadas / tareas.length : 0.0;
    final semLabel = '${fmt.format(lunes)} – ${fmt.format(domingo)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esActual ? _purple.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.07),
          width: esActual ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de semana
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: esActual ? _purple.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                if (esActual)
                  Container(
                    margin: const EdgeInsets.only(right: 7),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _purple,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('HOY', style: TextStyle(color: Colors.white,
                        fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                Expanded(
                  child: Text(semLabel,
                      style: TextStyle(
                        color: esActual ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      )),
                ),
                Text('$completadas/${tareas.length}',
                    style: TextStyle(color: _green.withValues(alpha: 0.8), fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                // Mini barra de progreso de semana
                SizedBox(
                  width: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pct == 1.0 ? _green : esActual ? _purple : _blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filas de tareas (barra Gantt)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              children: tareas.map((e) => _buildGanttRow(e, hoy)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fila Gantt de una tarea ────────────────────────────────────────────────

  Widget _buildGanttRow(({String docId, Tarea tarea}) entry, DateTime hoy) {
    final t = entry.tarea;
    final colorEstado = _colorEstado(t.estado);
    final colorPrio   = _colorPrioridad(t.prioridad);
    final esAltaPrio  = t.prioridad >= 3;
    final fechaFmt    = _fechaTarea(t) != null
        ? DateFormat('dd/MM').format(_fechaTarea(t)!)
        : null;
    final vencida     = !t.completado &&
        _fechaTarea(t) != null &&
        _fechaTarea(t)!.isBefore(hoy);

    // Porcentaje de la barra según estado
    final barPct = t.estado == 'completada'
        ? 1.0
        : t.estado == 'en_progreso'
            ? 0.55
            : 0.08;

    return GestureDetector(
      onTap: () => _mostrarDetalle(entry.docId, t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Indicador de prioridad
            Container(
              width: 3,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colorPrio,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Nombre de tarea (ancho fijo)
            SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.titulo,
                    style: TextStyle(
                      color: t.completado ? Colors.white38 : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      decoration: t.completado ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      if (esAltaPrio) ...[
                        Icon(Icons.priority_high, size: 9, color: _red.withValues(alpha: 0.8)),
                      ],
                      if (vencida) ...[
                        Icon(Icons.warning_amber_rounded, size: 9,
                            color: _red.withValues(alpha: 0.9)),
                        const SizedBox(width: 2),
                      ],
                      if (fechaFmt != null)
                        Text(fechaFmt,
                            style: TextStyle(
                              color: vencida ? _red.withValues(alpha: 0.8) : Colors.white24,
                              fontSize: 9,
                            )),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Barra Gantt
            Expanded(
              child: LayoutBuilder(builder: (ctx, box) {
                final maxW = box.maxWidth;
                final barW = (maxW * barPct).clamp(4.0, maxW);
                return Stack(
                  children: [
                    // Fondo
                    Container(
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Barra de progreso
                    Container(
                      width: barW,
                      height: 22,
                      decoration: BoxDecoration(
                        color: colorEstado.withValues(alpha: t.estado == 'completada' ? 0.3 : 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: colorEstado.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                    ),
                    // Etiqueta de estado dentro de la barra
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            _labelEstado(t.estado),
                            style: TextStyle(
                              color: colorEstado,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),

            const SizedBox(width: 6),
            // Área / área chip
            if (t.area.isNotEmpty && t.area != 'General')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  t.area.length > 8 ? '${t.area.substring(0, 7)}…' : t.area,
                  style: const TextStyle(color: Colors.white24, fontSize: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Bloque tareas sin fecha ────────────────────────────────────────────────

  Widget _buildSinFechaBlock(List<({String docId, Tarea tarea})> tareas) {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_busy, size: 13, color: Colors.white38),
                const SizedBox(width: 6),
                const Text('Sin fecha asignada',
                    style: TextStyle(color: Colors.white38, fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${tareas.length} tarea${tareas.length != 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              children: tareas.map((e) {
                final t = e.tarea;
                final colorPrio = _colorPrioridad(t.prioridad);
                return GestureDetector(
                  onTap: () => _mostrarDetalle(e.docId, t),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorPrio.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(width: 3, height: 20,
                            decoration: BoxDecoration(color: colorPrio,
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(t.titulo,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        Text(_labelEstado(t.estado),
                            style: TextStyle(color: _colorEstado(t.estado).withValues(alpha: 0.8),
                                fontSize: 10)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Modal de detalle (reutilizado del original) ────────────────────────────

  void _mostrarDetalle(String docId, Tarea tarea) {
    final colorP = _colorPrioridad(tarea.prioridad);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: _bgPage,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Título + toggle
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(tarea.titulo,
                              style: TextStyle(
                                color: tarea.completado ? Colors.white38 : Colors.white,
                                fontSize: 17, fontWeight: FontWeight.bold,
                                decoration: tarea.completado ? TextDecoration.lineThrough : null,
                              )),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _toggleCompletada(docId, tarea.completado);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: tarea.completado
                                  ? _green.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tarea.completado ? _green.withValues(alpha: 0.4) : Colors.white12,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tarea.completado ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 14,
                                  color: tarea.completado ? _green : Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Text(tarea.completado ? 'Hecha' : 'Marcar',
                                    style: TextStyle(
                                        color: tarea.completado ? _green : Colors.white38,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Prioridad + estado
                    Row(
                      children: [
                        _badgeTexto(_labelPrioridad(tarea.prioridad), colorP),
                        const SizedBox(width: 8),
                        _badgeTexto(_labelEstado(tarea.estado), _colorEstado(tarea.estado)),
                        if (tarea.area.isNotEmpty && tarea.area != 'General') ...[
                          const SizedBox(width: 8),
                          _badgeTexto(tarea.area, Colors.white38),
                        ],
                      ],
                    ),

                    if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text('Descripción', style: TextStyle(color: Colors.white54,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(tarea.descripcion!,
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                    ],

                    const SizedBox(height: 14),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),

                    if (tarea.fechaProgramada != null)
                      _infoRow(Icons.access_time, 'Programada',
                          DateFormat('dd/MM/yyyy HH:mm').format(tarea.fechaProgramada!), _blue),
                    if (tarea.fechaLimite != null)
                      _infoRow(Icons.flag_outlined, 'Deadline',
                          DateFormat('dd/MM/yyyy').format(tarea.fechaLimite!), _red),
                    if (tarea.fechaCompletada != null)
                      _infoRow(Icons.check_circle_outline, 'Completada el',
                          DateFormat('dd/MM/yyyy HH:mm').format(tarea.fechaCompletada!), _green),

                    const SizedBox(height: 14),
                    const Text('Cambiar estado',
                        style: TextStyle(color: Colors.white54, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _estadoBtn(docId, 'pendiente', tarea.estado, '⏳ Pendiente', _amber),
                        const SizedBox(width: 6),
                        _estadoBtn(docId, 'en_progreso', tarea.estado, '▶ En progreso', _blue),
                        const SizedBox(width: 6),
                        _estadoBtn(docId, 'completada', tarea.estado, '✓ Hecha', _green),
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

  // ── Helpers UI ─────────────────────────────────────────────────────────────

  Widget _filtroChip(String? estado, String label, int count, Color color) {
    final activo = _filtroEstado == estado;
    return GestureDetector(
      onTap: () => setState(() => _filtroEstado = estado),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: activo ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? color.withValues(alpha: 0.6) : Colors.white12,
            width: activo ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count', style: TextStyle(
                color: activo ? color : Colors.white38,
                fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
                color: activo ? color : Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }

  Widget _legendaDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }

  Widget _badgeTexto(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(texto, style: TextStyle(color: color, fontSize: 11,
          fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          Expanded(child: Text(value,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _estadoBtn(String docId, String estado, String estadoActual, String label, Color color) {
    final activo = estadoActual == estado;
    return Expanded(
      child: GestureDetector(
        onTap: activo ? null : () async {
          Navigator.pop(context);
          await FirebaseFirestore.instance
              .collection('proyectos')
              .doc(widget.proyectoId)
              .collection('tareas')
              .doc(docId)
              .update({
            'estado': estado,
            'completado': estado == 'completada',
            if (estado == 'completada') 'fechaCompletada': FieldValue.serverTimestamp(),
          });
          await _cargarTareas();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: activo ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: activo ? color.withValues(alpha: 0.5) : Colors.white12),
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(color: activo ? color : Colors.white38,
                  fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Future<void> _toggleCompletada(String docId, bool actual) async {
    try {
      await FirebaseFirestore.instance
          .collection('proyectos')
          .doc(widget.proyectoId)
          .collection('tareas')
          .doc(docId)
          .update({
        'completado': !actual,
        'estado': !actual ? 'completada' : 'pendiente',
        if (!actual) 'fechaCompletada': FieldValue.serverTimestamp(),
      });
      await _cargarTareas();
    } catch (_) {}
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.view_timeline_outlined, size: 52, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 14),
          const Text('No hay tareas en este proyecto',
              style: TextStyle(color: Colors.white24, fontSize: 14)),
          const SizedBox(height: 6),
          const Text('Crea tareas desde el Kanban para\nverlas aquí en el Gantt',
              style: TextStyle(color: Colors.white12, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

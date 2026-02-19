import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';

/// Vista de calendario del proyecto para el panel lateral
/// Muestra las tareas del proyecto en un calendario mensual reactivo
class CalendarioProyectoView extends StatefulWidget {
  final String proyectoId;

  const CalendarioProyectoView({super.key, required this.proyectoId});

  @override
  State<CalendarioProyectoView> createState() => _CalendarioProyectoViewState();
}

class _CalendarioProyectoViewState extends State<CalendarioProyectoView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Lista de (docId, Tarea)
  List<({String docId, Tarea tarea})> _tareas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
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

  /// Obtener la fecha de la tarea para el calendario:
  /// usa fechaProgramada si existe, si no fechaLimite, si no fecha legado
  DateTime? _fechaCalendario(Tarea t) =>
      t.fechaProgramada ?? t.fechaLimite ?? t.fecha;

  Map<DateTime, List<({String docId, Tarea tarea})>> get _tareasPorFecha {
    final Map<DateTime, List<({String docId, Tarea tarea})>> map = {};
    for (final entry in _tareas) {
      final fecha = _fechaCalendario(entry.tarea);
      if (fecha != null) {
        final key = DateTime(fecha.year, fecha.month, fecha.day);
        map.putIfAbsent(key, () => []).add(entry);
      }
    }
    return map;
  }

  List<({String docId, Tarea tarea})> _getTareasDelDia(DateTime dia) {
    final key = DateTime(dia.year, dia.month, dia.day);
    return _tareasPorFecha[key] ?? [];
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

  Color _colorPrioridad(int p) {
    switch (p) {
      case 1: return const Color(0xFF10B981);
      case 3: return const Color(0xFFEF4444);
      default: return const Color(0xFFF59E0B);
    }
  }

  String _labelPrioridad(int p) {
    switch (p) {
      case 1: return 'Baja';
      case 3: return 'Alta';
      default: return 'Media';
    }
  }

  void _mostrarDetalleTarea(String docId, Tarea tarea) {
    final colorP = _colorPrioridad(tarea.prioridad);
    final fechaLimFmt = tarea.fechaLimite != null
        ? DateFormat('dd/MM/yyyy').format(tarea.fechaLimite!)
        : null;
    final fechaPrgFmt = tarea.fechaProgramada != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(tarea.fechaProgramada!)
        : null;

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
            color: Color(0xFF0A0E27),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
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
                    // Título y estado
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            tarea.titulo,
                            style: TextStyle(
                              color: tarea.completado ? Colors.white38 : Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              decoration: tarea.completado ? TextDecoration.lineThrough : null,
                            ),
                          ),
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
                                  ? const Color(0xFF10B981).withOpacity(0.15)
                                  : Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tarea.completado
                                    ? const Color(0xFF10B981).withOpacity(0.4)
                                    : Colors.white12,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tarea.completado ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 14,
                                  color: tarea.completado ? const Color(0xFF10B981) : Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tarea.completado ? 'Hecha' : 'Marcar',
                                  style: TextStyle(
                                    color: tarea.completado ? const Color(0xFF10B981) : Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Prioridad + Estado Kanban
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colorP.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colorP.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Prioridad ${_labelPrioridad(tarea.prioridad)}',
                            style: TextStyle(color: colorP, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tarea.estado.replaceAll('_', ' '),
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ),
                      ],
                    ),

                    if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text('Descripción', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(tarea.descripcion!, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                    ],

                    const SizedBox(height: 14),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),

                    // Fechas
                    if (fechaPrgFmt != null)
                      _buildInfoRow(Icons.access_time, 'Programada', fechaPrgFmt, const Color(0xFF3B82F6)),
                    if (fechaLimFmt != null)
                      _buildInfoRow(Icons.flag_outlined, 'Deadline', fechaLimFmt, const Color(0xFFEF4444)),

                    // Área
                    if (tarea.area.isNotEmpty && tarea.area != 'General')
                      _buildInfoRow(Icons.group_work_outlined, 'Área', tarea.area, Colors.white38),

                    // Estado Kanban para cambiar
                    const SizedBox(height: 14),
                    const Text('Cambiar estado', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildEstadoBtn(docId, 'pendiente', tarea.estado, '⏳ Pendiente', const Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        _buildEstadoBtn(docId, 'en_progreso', tarea.estado, '▶ En progreso', const Color(0xFF3B82F6)),
                        const SizedBox(width: 6),
                        _buildEstadoBtn(docId, 'completada', tarea.estado, '✓ Hecha', const Color(0xFF10B981)),
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

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          Expanded(child: Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildEstadoBtn(String docId, String estado, String estadoActual, String label, Color color) {
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
            color: activo ? color.withOpacity(0.2) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: activo ? color.withOpacity(0.5) : Colors.white12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: activo ? color : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
    }

    final tareasDelDia = _selectedDay != null ? _getTareasDelDia(_selectedDay!) : <({String docId, Tarea tarea})>[];
    final totalConFecha = _tareas.where((e) => _fechaCalendario(e.tarea) != null).length;
    final totalSinFecha = _tareas.length - totalConFecha;
    final totalHechas = _tareas.where((e) => e.tarea.completado).length;

    return Column(
      children: [
        // Chips resumen
        if (_tareas.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Row(
              children: [
                _buildChip('${_tareas.length}', 'Total', const Color(0xFF8B5CF6)),
                const SizedBox(width: 6),
                _buildChip('$totalHechas', 'Hechas', const Color(0xFF10B981)),
                const SizedBox(width: 6),
                _buildChip('$totalSinFecha', 'Sin fecha', Colors.white38),
              ],
            ),
          ),

        // Calendario
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
            ),
            child: TableCalendar<({String docId, Tarea tarea})>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getTareasDelDia,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
                weekendTextStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                outsideTextStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
                selectedDecoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)]),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                todayDecoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.3), shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                markerDecoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                markersMaxCount: 3,
                markerSize: 5,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                formatButtonTextStyle: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 11),
                leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white, size: 18),
                rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                titleTextStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                headerPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                weekendStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
              ),
              rowHeight: 36,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Header del día seleccionado
        if (_selectedDay != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.event_note, size: 14, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    DateFormat('EEEE d MMMM', 'es_ES').format(_selectedDay!),
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${tareasDelDia.length} tarea${tareasDelDia.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

        const SizedBox(height: 6),

        // Lista de tareas del día
        Expanded(
          child: tareasDelDia.isEmpty
              ? _buildEmptyDia()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: tareasDelDia.length,
                  itemBuilder: (context, index) {
                    final entry = tareasDelDia[index];
                    return _buildTareaCard(entry.docId, entry.tarea);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChip(String valor, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(valor, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 40, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 10),
          const Text('Sin tareas este día', style: TextStyle(color: Colors.white24, fontSize: 13)),
          const SizedBox(height: 4),
          const Text(
            'Selecciona un día con marcador\no crea una tarea con esa fecha',
            style: TextStyle(color: Colors.white12, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTareaCard(String docId, Tarea tarea) {
    final color = _colorPrioridad(tarea.prioridad);
    final esHoy = isSameDay(_fechaCalendario(tarea), DateTime.now());

    return GestureDetector(
      onTap: () => _mostrarDetalleTarea(docId, tarea),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: tarea.completado
                ? const Color(0xFF10B981).withOpacity(0.3)
                : color.withOpacity(0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            GestureDetector(
              onTap: () => _toggleCompletada(docId, tarea.completado),
              child: Container(
                width: 20, height: 20,
                margin: const EdgeInsets.only(top: 2, right: 10),
                decoration: BoxDecoration(
                  color: tarea.completado ? const Color(0xFF10B981).withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: tarea.completado ? const Color(0xFF10B981) : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: tarea.completado
                    ? const Icon(Icons.check, size: 13, color: Color(0xFF10B981))
                    : null,
              ),
            ),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tarea.titulo,
                          style: TextStyle(
                            color: tarea.completado ? Colors.white38 : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: tarea.completado ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (esHoy && !tarea.completado)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Hoy', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        tarea.descripcion!,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          _labelPrioridad(tarea.prioridad),
                          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (tarea.fechaLimite != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.flag_outlined, size: 10, color: const Color(0xFFEF4444).withOpacity(0.7)),
                        const SizedBox(width: 2),
                        Text(
                          DateFormat('dd/MM').format(tarea.fechaLimite!),
                          style: TextStyle(color: const Color(0xFFEF4444).withOpacity(0.7), fontSize: 10),
                        ),
                      ],
                      if (tarea.area.isNotEmpty && tarea.area != 'General') ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tarea.area,
                            style: const TextStyle(color: Colors.white24, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Colors.white12, size: 16),
          ],
        ),
      ),
    );
  }
}

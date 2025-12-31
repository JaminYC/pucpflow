import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';

/// Vista de calendario/timeline con tareas organizadas por fecha
class TimelineCalendarView extends StatefulWidget {
  final List<Tarea> tareas;
  final void Function(Tarea tarea) onTareaTapped;
  final void Function(Tarea tarea, bool completado, String userId) onCheckboxChanged;
  final Map<String, String> nombreResponsables;
  final String userId;

  const TimelineCalendarView({
    super.key,
    required this.tareas,
    required this.onTareaTapped,
    required this.onCheckboxChanged,
    required this.nombreResponsables,
    required this.userId,
  });

  @override
  State<TimelineCalendarView> createState() => _TimelineCalendarViewState();
}

class _TimelineCalendarViewState extends State<TimelineCalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Map<DateTime, List<Tarea>> get _agruparTareasPorFecha {
    final Map<DateTime, List<Tarea>> eventos = {};

    print('\n🔍 DEBUG Timeline - Agrupando tareas:');
    print('   📊 Total tareas recibidas: ${widget.tareas.length}');

    int tareasSinFecha = 0;
    int tareasConFecha = 0;

    for (var tarea in widget.tareas) {
      if (tarea.fecha != null) {
        final fecha = DateTime(
          tarea.fecha!.year,
          tarea.fecha!.month,
          tarea.fecha!.day,
        );
        eventos.putIfAbsent(fecha, () => []);
        eventos[fecha]!.add(tarea);
        tareasConFecha++;

        print('   ✅ Tarea: "${tarea.titulo}" → ${DateFormat('dd/MM/yyyy').format(fecha)}');
      } else {
        tareasSinFecha++;
        print('   ⚠️ Tarea sin fecha: "${tarea.titulo}"');
      }
    }

    print('   📈 Resumen:');
    print('      - Tareas con fecha: $tareasConFecha');
    print('      - Tareas sin fecha: $tareasSinFecha');
    print('      - Días con tareas: ${eventos.length}');
    print('      - Fechas: ${eventos.keys.map((d) => DateFormat('dd/MM/yyyy').format(d)).toList()}\n');

    return eventos;
  }

  List<Tarea> _getTareasDelDia(DateTime dia) {
    final fecha = DateTime(dia.year, dia.month, dia.day);
    return _agruparTareasPorFecha[fecha] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildCalendar(),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 8),
        ),
        SliverToBoxAdapter(
          child: _buildTareasDelDia(),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.3),
        ),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) => _getTareasDelDia(day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          // Días actuales
          defaultTextStyle: const TextStyle(color: Colors.white),
          weekendTextStyle: TextStyle(color: Colors.white.withOpacity(0.7)),

          // Día seleccionado
          selectedDecoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
            ),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),

          // Día de hoy
          todayDecoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),

          // Marcadores de eventos
          markerDecoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,

          // Días fuera del mes
          outsideTextStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          formatButtonTextStyle: const TextStyle(
            color: Color(0xFF8B5CF6),
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          weekendStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        ),
      ),
    );
  }

  Widget _buildTareasDelDia() {
    final List<Tarea> tareas = _selectedDay != null ? _getTareasDelDia(_selectedDay!) : <Tarea>[];
    final fechaFormateada = _selectedDay != null
        ? DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(_selectedDay!)
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fechaFormateada,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${tareas.length} tarea${tareas.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tareas.isNotEmpty)
                  _buildProgressChip(tareas),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withOpacity(0.1),
          ),

          // Lista de tareas
          if (tareas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: _buildEmptyState(),
            )
          else
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tareas.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildTareaCard(tareas[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProgressChip(List<Tarea> tareas) {
    final completadas = tareas.where((t) => t.completado).length;
    final progreso = (completadas / tareas.length * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.2),
            const Color(0xFF10B981).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 6),
          Text(
            '$progreso%',
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay tareas para este día',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTareaCard(Tarea tarea) {
    final priorityColor = _getPriorityColor(tarea.prioridad);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priorityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onTareaTapped(tarea),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
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
                        widget.onCheckboxChanged(tarea, value, widget.userId);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        tarea.titulo,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: tarea.completado ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Metadata
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          // Tipo
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tarea.tipoTarea,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Duración
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
                        ],
                      ),
                    ],
                  ),
                ),

                // Prioridad indicator
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
}

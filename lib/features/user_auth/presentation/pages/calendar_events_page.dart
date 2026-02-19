import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'Login/google_calendar_service.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Proyectos/tarea_model.dart';

class CalendarEvent {
  final String titulo;
  final DateTime? fecha;
  final String tipo; // 'google' o 'tarea'
  final String? proyecto;
  final String? descripcion;
  final calendar.Event? googleEvent;
  final Tarea? tarea;
  final String? tareaId;
  final String? proyectoId;

  CalendarEvent({
    required this.titulo,
    this.fecha,
    required this.tipo,
    this.proyecto,
    this.descripcion,
    this.googleEvent,
    this.tarea,
    this.tareaId,
    this.proyectoId,
  });
}

class CalendarEventsPage extends StatefulWidget {
  const CalendarEventsPage({super.key});

  @override
  _CalendarEventsPageState createState() => _CalendarEventsPageState();
}

class _CalendarEventsPageState extends State<CalendarEventsPage> {
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  List<CalendarEvent> _allEvents = [];
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final LinkedHashMap<DateTime, List<CalendarEvent>> _eventsByDay = LinkedHashMap<DateTime, List<CalendarEvent>>(
    equals: isSameDay,
    hashCode: (date) => date.day * 1000000 + date.month * 10000 + date.year,
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCalendarEvents();
  }

  Future<void> _fetchCalendarEvents() async {
    setState(() {
      _isLoading = true;
    });

    List<CalendarEvent> allEvents = [];

    // Fetch Google Calendar events
    final calendarApi = await _calendarService.signInAndGetCalendarApi(silentOnly: true);
    if (calendarApi != null) {
      final now = DateTime.now().toUtc();
      print("Fetching events from Google Calendar...");
      final events = await calendarApi.events.list(
        "primary",
        timeMin: now.subtract(const Duration(days: 30)),
        timeMax: now.add(const Duration(days: 90)),
        maxResults: 250,
        singleEvents: true,
        orderBy: 'startTime',
      );

      // Convert Google Calendar events to CalendarEvent
      for (var event in events.items ?? []) {
        final eventDateTime = event.start?.dateTime ?? event.start?.date;
        allEvents.add(CalendarEvent(
          titulo: event.summary ?? "(Sin título)",
          fecha: eventDateTime,
          tipo: 'google',
          descripcion: event.description,
          googleEvent: event,
        ));
      }
      print("Eventos de Google Calendar: ${allEvents.length}");
    } else {
      print("No se pudo obtener el acceso a Google Calendar.");
    }

    // Fetch Firestore tasks from all projects
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        print("Fetching tasks from Firestore...");
        final proyectosSnapshot = await FirebaseFirestore.instance
            .collection('proyectos')
            .where('propietario', isEqualTo: user.uid)
            .get();

        for (var proyectoDoc in proyectosSnapshot.docs) {
          final proyectoId = proyectoDoc.id;
          final proyectoNombre = proyectoDoc.data()['nombre'] ?? 'Sin nombre';

          final tareasSnapshot = await FirebaseFirestore.instance
              .collection('proyectos')
              .doc(proyectoId)
              .collection('tareas')
              .get();

          for (var tareaDoc in tareasSnapshot.docs) {
            final tareaData = tareaDoc.data();
            final tarea = Tarea.fromJson(tareaData);

            // Only add tasks with dates
            if (tarea.fecha != null) {
              allEvents.add(CalendarEvent(
                titulo: tarea.titulo,
                fecha: tarea.fecha,
                tipo: 'tarea',
                proyecto: proyectoNombre,
                descripcion: tarea.descripcion,
                tarea: tarea,
                tareaId: tareaDoc.id,
                proyectoId: proyectoId,
              ));
            }
          }
        }
        print("Total de tareas agregadas: ${allEvents.where((e) => e.tipo == 'tarea').length}");
      } catch (e) {
        print("Error fetching tasks: $e");
      }
    }

    setState(() {
      _allEvents = allEvents;
      print("Total de eventos: ${_allEvents.length}");
      _groupEventsByDay();
      _isLoading = false;
    });
  }

  void _groupEventsByDay() {
    _eventsByDay.clear();
    for (var event in _allEvents) {
      if (event.fecha != null) {
        final date = DateTime(event.fecha!.year, event.fecha!.month, event.fecha!.day);
        if (_eventsByDay[date] == null) {
          _eventsByDay[date] = [];
        }
        _eventsByDay[date]!.add(event);
      }
    }
    print("Eventos agrupados por día: ${_eventsByDay.length}");
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final events = _eventsByDay[day] ?? [];
    print("Eventos para el día $day: ${events.length}");
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("📅 Calendario de FLOW"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepPurple),
                  SizedBox(height: 16),
                  Text("Cargando eventos..."),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2000, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    eventLoader: _getEventsForDay,
                    calendarFormat: CalendarFormat.month,
                    onFormatChanged: (format) {
                      setState(() {});
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildEventList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearEventoEnGoogleCalendar,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nuevo Evento", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
    );
  }

  Future<void> _crearEventoEnGoogleCalendar() async {
    // Controllers para el formulario
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    DateTime? fechaSeleccionada;
    TimeOfDay? horaSeleccionada;
    int duracionMinutos = 60;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("📅 Crear Evento en Google Calendar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título del evento
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(
                    labelText: "Título del evento",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title, color: Colors.deepPurple),
                  ),
                ),
                const SizedBox(height: 16),

                // Descripción
                TextField(
                  controller: descripcionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Descripción (opcional)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description, color: Colors.deepPurple),
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de fecha
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                  title: Text(
                    fechaSeleccionada == null
                        ? "Seleccionar fecha"
                        : "${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year}",
                    style: TextStyle(
                      fontWeight: fechaSeleccionada == null ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        fechaSeleccionada = picked;
                      });
                    }
                  },
                ),
                const Divider(),

                // Selector de hora
                ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.deepPurple),
                  title: Text(
                    horaSeleccionada == null
                        ? "Seleccionar hora"
                        : "${horaSeleccionada!.hour.toString().padLeft(2, '0')}:${horaSeleccionada!.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontWeight: horaSeleccionada == null ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        horaSeleccionada = picked;
                      });
                    }
                  },
                ),
                const Divider(),

                // Duración
                ListTile(
                  leading: const Icon(Icons.timer, color: Colors.deepPurple),
                  title: Text("Duración: $duracionMinutos minutos"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setState(() {
                            if (duracionMinutos > 15) duracionMinutos -= 15;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() {
                            duracionMinutos += 15;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (tituloController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Por favor ingresa un título"), backgroundColor: Colors.red),
                  );
                  return;
                }
                if (fechaSeleccionada == null || horaSeleccionada == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Por favor selecciona fecha y hora"), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text("Crear Evento", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && fechaSeleccionada != null && horaSeleccionada != null) {
      // Crear el evento en Google Calendar
      try {
        final calendarApi = await _calendarService.signInAndGetCalendarApi(silentOnly: false);

        if (calendarApi == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No se pudo conectar con Google Calendar. Por favor inicia sesión."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final fechaHora = DateTime(
          fechaSeleccionada!.year,
          fechaSeleccionada!.month,
          fechaSeleccionada!.day,
          horaSeleccionada!.hour,
          horaSeleccionada!.minute,
        );

        final event = calendar.Event(
          summary: tituloController.text,
          description: descripcionController.text.isEmpty ? null : descripcionController.text,
          start: calendar.EventDateTime(
            dateTime: fechaHora.toUtc(),
            timeZone: "America/Lima",
          ),
          end: calendar.EventDateTime(
            dateTime: fechaHora.add(Duration(minutes: duracionMinutos)).toUtc(),
            timeZone: "America/Lima",
          ),
        );

        await calendarApi.events.insert(event, "primary");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Evento creado exitosamente en Google Calendar"),
            backgroundColor: Colors.green,
          ),
        );

        // Recargar eventos
        _fetchCalendarEvents();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al crear evento: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _agregarTareaAGoogleCalendar(CalendarEvent event) async {
    if (event.tarea == null || event.fecha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Esta tarea no tiene fecha asignada"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final calendarApi = await _calendarService.signInAndGetCalendarApi(silentOnly: false);

      if (calendarApi == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se pudo conectar con Google Calendar"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Verificar si la tarea ya existe en Google Calendar
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final yaExiste = await _calendarService.verificarTareaEnCalendario(
          calendarApi,
          event.tarea!,
          user.uid,
        );

        if (yaExiste) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Esta tarea ya existe en tu Google Calendar"),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Agregar la tarea a Google Calendar
        await _calendarService.agendarEventoEnCalendario(
          calendarApi,
          event.tarea!,
          user.uid,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Tarea agregada exitosamente a Google Calendar"),
            backgroundColor: Colors.green,
          ),
        );

        // Recargar eventos
        _fetchCalendarEvents();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al agregar tarea: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarMenuOpcionesTarea(CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Opciones de Tarea",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: Colors.orange),
              ),
              title: const Text("Editar Fecha", style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Cambiar la fecha de la tarea", style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showTaskEditDialog(event);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_month, color: Colors.deepPurple),
              ),
              title: const Text("Agregar a Google Calendar", style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Sincronizar con tu calendario", style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _agregarTareaAGoogleCalendar(event);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No hay eventos para este día",
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              "Toca el botón '+' para crear un nuevo evento",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Separar tareas de eventos
    final tareas = events.where((e) => e.tipo == 'tarea').toList();
    final eventosGoogle = events.where((e) => e.tipo == 'google').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sección de Tareas
        if (tareas.isNotEmpty) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.task_alt, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "MIS TAREAS (${tareas.length})",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tareas.map((event) => _buildTareaCard(event)),
          const SizedBox(height: 20),
        ],

        // Sección de Eventos de Google Calendar
        if (eventosGoogle.isNotEmpty) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "GOOGLE CALENDAR (${eventosGoogle.length})",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...eventosGoogle.map((event) => _buildEventoGoogleCard(event)),
        ],
      ],
    );
  }

  Widget _buildTareaCard(CalendarEvent event) {
    final tarea = event.tarea!;
    final horaFormat = event.fecha != null
        ? "${event.fecha!.hour.toString().padLeft(2, '0')}:${event.fecha!.minute.toString().padLeft(2, '0')}"
        : "Sin hora";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _mostrarMenuOpcionesTarea(event),
        borderRadius: BorderRadius.circular(16),
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con hora y estado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          horaFormat,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (tarea.completado)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            "Completada",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Título de la tarea
              Text(
                event.titulo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  decoration: tarea.completado ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 8),

              // Proyecto
              if (event.proyecto != null)
                Row(
                  children: [
                    const Icon(Icons.folder, size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.proyecto!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),

              // Descripción si existe
              if (event.descripcion != null && event.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  event.descripcion!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Botón de opciones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => _mostrarMenuOpcionesTarea(event),
                    icon: const Icon(Icons.more_vert),
                    color: Colors.orange,
                    tooltip: "Opciones",
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

  Widget _buildEventoGoogleCard(CalendarEvent event) {
    final horaFormat = event.fecha != null
        ? "${event.fecha!.hour.toString().padLeft(2, '0')}:${event.fecha!.minute.toString().padLeft(2, '0')}"
        : "Sin hora";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          horaFormat,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today, color: Colors.deepPurple, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.titulo,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (event.descripcion != null && event.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  event.descripcion!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTaskEditDialog(CalendarEvent event) async {
    DateTime selectedDate = event.fecha ?? DateTime.now();

    final newDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDate != null && newDate != selectedDate && mounted) {
      final timeOfDay = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.deepPurple,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (timeOfDay != null) {
        final newDateTime = DateTime(
          newDate.year,
          newDate.month,
          newDate.day,
          timeOfDay.hour,
          timeOfDay.minute,
        );

        // Update task in Firestore
        try {
          await FirebaseFirestore.instance
              .collection('proyectos')
              .doc(event.proyectoId)
              .collection('tareas')
              .doc(event.tareaId)
              .update({'fecha': newDateTime.toIso8601String()});

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Fecha de tarea actualizada"),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh calendar
          _fetchCalendarEvents();
        } catch (e) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al actualizar: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

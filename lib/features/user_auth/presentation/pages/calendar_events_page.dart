import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'google_calendar_service.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

class CalendarEventsPage extends StatefulWidget {
  const CalendarEventsPage({super.key});

  @override
  _CalendarEventsPageState createState() => _CalendarEventsPageState();
}

class _CalendarEventsPageState extends State<CalendarEventsPage> {
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  List<calendar.Event> _events = [];
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final LinkedHashMap<DateTime, List<calendar.Event>> _eventsByDay = LinkedHashMap<DateTime, List<calendar.Event>>(
    equals: isSameDay,
    hashCode: (date) => date.day * 1000000 + date.month * 10000 + date.year,
  );

  @override
  void initState() {
    super.initState();
    _fetchCalendarEvents();
  }

  Future<void> _fetchCalendarEvents() async {
    final calendarApi = await _calendarService.signInAndGetCalendarApi();
    if (calendarApi == null) {
      print("No se pudo obtener el acceso a Google Calendar.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo obtener el acceso a Google Calendar")),
      );
      return;
    }

    final now = DateTime.now().toUtc();
    print("Fetching events from Google Calendar...");
    final events = await calendarApi.events.list(
      "primary",
      timeMin: now,
      maxResults: 100,
      singleEvents: true,
      orderBy: 'startTime',
    );

    setState(() {
      _events = events.items ?? [];
      print("Eventos obtenidos: ${_events.length}");
      _groupEventsByDay();
    });
  }

  void _groupEventsByDay() {
    _eventsByDay.clear();
    for (var event in _events) {
      final eventDateTime = event.start?.dateTime ?? event.start?.date;
      if (eventDateTime != null) {
        final date = DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day);
        if (_eventsByDay[date] == null) {
          _eventsByDay[date] = [];
        }
        _eventsByDay[date]!.add(event);
      }
    }
    print("Eventos agrupados por día: ${_eventsByDay.length}");
  }

  List<calendar.Event> _getEventsForDay(DateTime day) {
    final events = _eventsByDay[day] ?? [];
    print("Eventos para el día $day: ${events.length}");
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Eventos de Google Calendar")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              print("Día seleccionado: $selectedDay");
              _getEventsForDay(selectedDay);
            },
            eventLoader: _getEventsForDay,
            calendarFormat: CalendarFormat.month,
            onFormatChanged: (format) {
              setState(() {
                print("Formato de calendario cambiado a: $format");
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              print("Página cambiada, día enfocado: $_focusedDay");
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay);
    if (events.isEmpty) {
      print("No hay eventos para el día: $_selectedDay");
      return const Center(child: Text("No hay eventos para este día."));
    }
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final eventTime = event.start?.dateTime ?? event.start?.date;
        return ListTile(
          title: Text(event.summary ?? "Sin título"),
          subtitle: Text(eventTime != null
              ? "Fecha y hora: ${eventTime.toLocal()}"
              : "Sin fecha"),
        );
      },
    );
  }
}

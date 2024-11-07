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
  final Map<DateTime, List<calendar.Event>> _eventsByDay = {};

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
    final events = await calendarApi.events.list(
      "primary",
      timeMin: now,
      maxResults: 100,
      singleEvents: true,
      orderBy: 'startTime',
    );

    setState(() {
      _events = events.items ?? [];
      _groupEventsByDay();
    });
  }

  void _groupEventsByDay() {
    _eventsByDay.clear();
    for (var event in _events) {
      final eventDate = event.start?.dateTime ?? event.start?.date;
      if (eventDate != null) {
        final date = DateTime(eventDate.year, eventDate.month, eventDate.day);
        if (_eventsByDay[date] == null) {
          _eventsByDay[date] = [];
        }
        _eventsByDay[date]!.add(event);
      }
    }
  }

  List<calendar.Event> _getEventsForDay(DateTime day) {
    return _eventsByDay[day] ?? [];
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
            focusedDay: _selectedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
            eventLoader: _getEventsForDay,
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
      return const Center(child: Text("No hay eventos para este día."));
    }
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final eventTime = event.start?.dateTime ?? event.start?.date;
        return ListTile(
          title: Text(event.summary ?? "Sin título"),
          subtitle: Text(eventTime?.toString() ?? "Sin fecha"),
        );
      },
    );
  }
}

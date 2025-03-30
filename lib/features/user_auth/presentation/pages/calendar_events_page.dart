import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'Login/google_calendar_service.dart';
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
    final calendarApi = await _calendarService.signInAndGetCalendarApi(silentOnly: true);
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
      timeMin: now.subtract(const Duration(days: 30)),
      timeMax: now.add(const Duration(days: 90)),
      maxResults: 250,
      singleEvents: true,
      orderBy: 'startTime',
    );

    setState(() {
      _events = events.items ?? [];
      print("Eventos obtenidos: \${_events.length}");
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
    print("Eventos agrupados por día: \${_eventsByDay.length}");
  }

  List<calendar.Event> _getEventsForDay(DateTime day) {
    final events = _eventsByDay[day] ?? [];
    print("Eventos para el día \$day: \${events.length}");
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
      body: Column(
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
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay);
    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text("No hay eventos para este día.", style: TextStyle(fontSize: 16))
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final eventTime = event.start?.dateTime ?? event.start?.date;
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.event, color: Colors.white),
            ),
            title: Text(event.summary ?? "(Sin título)", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(eventTime != null
                ? "${eventTime.toLocal()}"
                : "Sin fecha definida"),
          ),
        );
      },
    );
  }
}

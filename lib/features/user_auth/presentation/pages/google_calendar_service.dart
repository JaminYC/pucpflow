  import 'package:google_sign_in/google_sign_in.dart';
  import 'package:googleapis/calendar/v3.dart' as calendar;
  import 'package:googleapis_auth/auth_io.dart';
  import 'package:http/http.dart' as http;
import 'package:pucpflow/features/user_auth/presentation/pages/AsistenteIA/comando_service.dart';
  import 'dart:convert';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ProyectoDetallePage.dart';  
  import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ProyectosPage.dart'; 
  import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_model.dart';
class GoogleCalendarService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [calendar.CalendarApi.calendarScope],
  );

  // 🔹 Inicia sesión y obtiene la API de Google Calendar
  Future<calendar.CalendarApi?> signInAndGetCalendarApi() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        print("⚠️ El usuario canceló el inicio de sesión");
        return null;
      }

      final headers = await account.authHeaders;
      final client = GoogleAuthClient(headers);
      return calendar.CalendarApi(client);
    } catch (e) {
      print("❌ Error en Google Sign-In: $e");
      return null;
    }
  }

  // 🔹 Extraer tareas pendientes de los proyectos almacenados
  Future<List<Tarea>> _obtenerTareasPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    final proyectosData = prefs.getStringList('proyectos') ?? [];

    List<Tarea> tareasPendientes = [];

    for (String proyectoJson in proyectosData) {
      Proyecto proyecto = Proyecto.fromJson(jsonDecode(proyectoJson));
      for (Tarea tarea in proyecto.tareas) {
        if (!tarea.completado) {
          tareasPendientes.add(tarea);
        }
      }
    }

    return tareasPendientes;
  }

  // 🔹 Obtiene los horarios disponibles en la semana
  Future<List<DateTime>> _obtenerHorariosDisponiblesSemana() async {
    final calendarApi = await signInAndGetCalendarApi();
    if (calendarApi == null) return [];

    List<DateTime> horariosDisponibles = [];

    for (int i = 0; i < 7; i++) {
      DateTime fecha = DateTime.now().add(Duration(days: i));
      final horarios = await getAvailableTimes(fecha);
      horariosDisponibles.addAll(horarios);
    }

    return horariosDisponibles;
  }

  // 🔹 Organiza automáticamente eventos en la semana
  Future<void> organizarEventosSemana() async {
    final calendarApi = await signInAndGetCalendarApi();
    if (calendarApi == null) {
      print("⚠️ No se pudo conectar con Google Calendar.");
      return;
    }

    List<Tarea> tareasPendientes = await _obtenerTareasPendientes();
    List<DateTime> horariosDisponibles = await _obtenerHorariosDisponiblesSemana();

    if (tareasPendientes.isEmpty) {
      print("✅ No hay tareas pendientes para organizar.");
      return;
    }

    for (Tarea tarea in tareasPendientes) {
      if (horariosDisponibles.isEmpty) break; // No hay más espacios disponibles

      DateTime slot = horariosDisponibles.removeAt(0);
      await _agendarEventoEnCalendario(calendarApi, tarea, slot);
    }

    print("✅ Eventos organizados correctamente.");
  }

  // 🔹 Agendar un evento en Google Calendar con fecha exacta
  Future<void> _agendarEventoEnCalendario(
      calendar.CalendarApi calendarApi, Tarea tarea, DateTime startTime) async {
    try {
      final event = calendar.Event(
        summary: tarea.titulo,
        start: calendar.EventDateTime(
          dateTime: startTime.toUtc(),
          timeZone: "America/Lima",
        ),
        end: calendar.EventDateTime(
          dateTime: startTime.toUtc().add(Duration(minutes: tarea.duracion)),
          timeZone: "America/Lima",
        ),
        colorId: tarea.colorId.toString(),
        reminders: calendar.EventReminders(
          useDefault: false,
          overrides: [
            calendar.EventReminder(method: "popup", minutes: 10),
          ],
        ),
      );

      await calendarApi.events.insert(event, "primary");
      print("✅ Evento '${tarea.titulo}' agendado en ${startTime.toLocal()}.");
    } catch (e) {
      print("❌ Error al agendar evento: $e");
    }
  }

  // 🔹 Obtener tiempos ocupados en Google Calendar
  Future<List<calendar.TimePeriod>> getBusyTimes(
      calendar.CalendarApi calendarApi, DateTime start, DateTime end) async {
    try {
      final request = calendar.FreeBusyRequest(
        timeMin: start.toUtc(),
        timeMax: end.toUtc(),
        timeZone: "America/Lima",
        items: [calendar.FreeBusyRequestItem(id: "primary")],
      );

      final response = await calendarApi.freebusy.query(request);

      if (response.calendars != null &&
          response.calendars!.containsKey("primary") &&
          response.calendars!["primary"]!.busy != null) {
        return response.calendars!["primary"]!.busy!;
      }
    } catch (e) {
      print("Error al obtener tiempos ocupados: $e");
    }

    return [];
  }

  // 🔹 Encontrar espacio libre en los horarios
  DateTime? findFreeSlot(List<calendar.TimePeriod> busyTimes, int durationMinutes) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 7, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 12, 0);

    try {
      busyTimes.sort((a, b) {
        final aStart = a.start;
        final bStart = b.start;

        if (aStart == null || bStart == null) {
          return 0;
        }
        return aStart.compareTo(bStart);
      });

      DateTime previousEnd = startOfDay;
      for (final busy in busyTimes) {
        final busyStart = busy.start;
        final busyEnd = busy.end;

        if (busyStart == null || busyEnd == null) continue;

        if (busyStart.difference(previousEnd).inMinutes >= durationMinutes) {
          return previousEnd;
        }
        previousEnd = busyEnd;
      }

      if (endOfDay.difference(previousEnd).inMinutes >= durationMinutes) {
        return previousEnd;
      }
    } catch (e) {
      print("Error al buscar espacio libre: $e");
    }

    return null;
  }

  Future<void> addEventWithExactTime(
    calendar.CalendarApi calendarApi, String calendarId, String title, String description, DateTime startTime) async {
  try {
    print("📡 Enviando evento a Google Calendar: $title el $startTime");

    final event = calendar.Event(
      summary: title,
      description: description,
      start: calendar.EventDateTime(
        dateTime: startTime.toUtc(),
        timeZone: "America/Lima",
      ),
      end: calendar.EventDateTime(
        dateTime: startTime.toUtc().add(Duration(minutes: 60)),
        timeZone: "America/Lima",
      ),
      colorId: "5",
      reminders: calendar.EventReminders(
        useDefault: false,
        overrides: [calendar.EventReminder(method: "popup", minutes: 10)],
      ),
    );

    final insertedEvent = await calendarApi.events.insert(event, calendarId);
    print("✅ Evento creado exitosamente: ${insertedEvent.htmlLink}");
  } catch (e) {
    print("❌ Error al añadir el evento en Google Calendar: $e");
  }
}


  // 🔹 Obtener horarios disponibles
  Future<List<DateTime>> getAvailableTimes(DateTime date) async {
    final calendarApi = await signInAndGetCalendarApi();
    if (calendarApi == null) return [];

    final startOfDay = DateTime(date.year, date.month, date.day, 7, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 12, 0);

    final busyTimes = await getBusyTimes(calendarApi, startOfDay, endOfDay);
    final availableTimes = <DateTime>[];

    DateTime current = startOfDay;
    for (final busy in busyTimes) {
      if (busy.start != null && current.isBefore(busy.start!)) {
        availableTimes.add(current);
      }
      current = busy.end ?? current;
    }

    if (current.isBefore(endOfDay)) {
      availableTimes.add(current);
    }

    return availableTimes;
  }
    // Método para añadir un evento automáticamente
    Future<void> addEventAutomatically(
        calendar.CalendarApi calendarApi, String calendarId, String title, String description, int durationMinutes) async {
      try {
        // Define el rango de tiempo para buscar disponibilidad
        final now = DateTime.now();
        final oneWeekLater = now.add(Duration(days: 7));

        // Obtén los tiempos ocupados
        final busyTimes = await getBusyTimes(calendarApi, now, oneWeekLater);

        // Encuentra un espacio libre
        final freeSlot = findFreeSlot(busyTimes, durationMinutes);

        if (freeSlot == null) {
          print("No se encontró espacio libre para el evento.");
          return;
        }

        // Define el evento
        final event = calendar.Event(
          summary: title,
          description: description,
          start: calendar.EventDateTime(
            dateTime: freeSlot,
            timeZone: "GMT-5:00",
          ),
          end: calendar.EventDateTime(
            dateTime: freeSlot.add(Duration(minutes: durationMinutes)),
            timeZone: "GMT-5:00",
          ),
          colorId: "5", // Personaliza el color del evento
          reminders: calendar.EventReminders(
            useDefault: false,
            overrides: [
              calendar.EventReminder(
                method: "popup",
                minutes: 10,
              ),
            ],
          ),
        );

        // Inserta el evento
        final insertedEvent = await calendarApi.events.insert(event, calendarId);
        print("Evento creado exitosamente: ${insertedEvent.htmlLink}");
      } catch (e) {
        print("Error al añadir el evento: $e");
      }
    }

  }

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

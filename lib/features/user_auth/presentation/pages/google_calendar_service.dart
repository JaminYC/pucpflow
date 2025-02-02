  import 'package:google_sign_in/google_sign_in.dart';
  import 'package:googleapis/calendar/v3.dart' as calendar;
  import 'package:googleapis_auth/auth_io.dart';
  import 'package:http/http.dart' as http;

 class GoogleCalendarService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [calendar.CalendarApi.calendarScope],
  );

  // Método para obtener los tiempos ocupados
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


  // Método para encontrar un espacio libre
  DateTime? findFreeSlot(List<calendar.TimePeriod> busyTimes, int durationMinutes) {
  final now = DateTime.now();
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);

  try {
    // Ordena los tiempos ocupados por la hora de inicio
    busyTimes.sort((a, b) {
      final aStart = a.start; // `a.start` ya es un DateTime o null
      final bStart = b.start;

      if (aStart == null || bStart == null) {
        return 0; // Si alguno es nulo, no se pueden comparar
      }
      return aStart.compareTo(bStart);
    });
  
    // Busca un espacio entre los tiempos ocupados
    DateTime previousEnd = now;
    for (final busy in busyTimes) {
      final busyStart = busy.start; // Usamos directamente el valor de `start`
      final busyEnd = busy.end;

      if (busyStart == null || busyEnd == null) continue;

      if (busyStart.difference(previousEnd).inMinutes >= durationMinutes) {
        return previousEnd;
      }
      previousEnd = busyEnd;
    }

    // Si no hay espacio durante el día, usa el final del último bloque ocupado
    if (endOfDay.difference(previousEnd).inMinutes >= durationMinutes) {
      return previousEnd;
    }
  } catch (e) {
    print("Error al buscar espacio libre: $e");
  }

  // No se encontró espacio
  return null;
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

  // Método para iniciar sesión y obtener la API de Google Calendar
  Future<calendar.CalendarApi?> signInAndGetCalendarApi() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        print("El usuario canceló el inicio de sesión");
        return null;
      }

      final headers = await account.authHeaders;
      final client = GoogleAuthClient(headers);
      return calendar.CalendarApi(client);
    } catch (e) {
      print("Error durante Google Sign-In: $e");
      return null;
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

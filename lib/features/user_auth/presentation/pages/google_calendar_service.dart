import 'package:google_sign_in/google_sign_in.dart'; 
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';

class GoogleCalendarService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [calendar.CalendarApi.calendarScope],
  );
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 **Corrección de `signInAndGetCalendarApi()`**
  Future<calendar.CalendarApi?> signInAndGetCalendarApi() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        print("⚠️ No se pudo iniciar sesión en Google.");
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
  Future<bool> verificarTareaEnCalendario(calendar.CalendarApi calendarApi, Tarea tarea) async {
  try {
    final events = await calendarApi.events.list(
      "primary",
      timeMin: tarea.fecha.subtract(const Duration(minutes: 1)), 
      timeMax: tarea.fecha.add(const Duration(minutes: 1)), 
    );

    for (var event in events.items ?? []) {
      if (event.summary == tarea.titulo) {
        return true; // ✅ La tarea ya existe en el calendario
      }
    }
  } catch (e) {
    print("❌ Error al verificar tarea en Google Calendar: $e");
  }
  return false; // ❌ No se encontró la tarea en el calendario
}

  /// 🔹 **Corrección en Firestore**
  Future<DateTime?> encontrarHorarioParaProyecto(String proyectoId, int duracionMinutos) async {
    final calendarApi = await signInAndGetCalendarApi();
    if (calendarApi == null) return null;

    DocumentSnapshot proyectoDoc = await _firestore.collection("proyectos").doc(proyectoId).get();

    if (!proyectoDoc.exists) {
      print("⚠️ Proyecto no encontrado.");
      return null;
    }

    Proyecto proyecto = Proyecto.fromJson(proyectoDoc.data() as Map<String, dynamic>);
    List<String> participantes = proyecto.participantes;

    if (participantes.isEmpty) {
      print("⚠️ No hay participantes en el proyecto.");
      return null;
    }

    DateTime fechaReunion = DateTime.now().add(Duration(days: 2));
    List<calendar.TimePeriod> horariosOcupadosTotales = [];

    for (String usuario in participantes) {
      print("🔍 Verificando disponibilidad para $usuario...");
      List<calendar.TimePeriod> busyTimes =
          await getBusyTimes(calendarApi, fechaReunion, fechaReunion.add(Duration(days: 1)));

      horariosOcupadosTotales.addAll(busyTimes);
    }

    return findFreeSlot(horariosOcupadosTotales, duracionMinutos);
  }

  /// 🔹 **Obtener horarios ocupados de Google Calendar**
  Future<List<calendar.TimePeriod>> getBusyTimes(calendar.CalendarApi calendarApi, DateTime start, DateTime end) async {
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
      print("❌ Error al obtener tiempos ocupados: $e");
    }

    return [];
  }

  /// 🔹 **Buscar espacio libre en horarios**
  DateTime? findFreeSlot(List<calendar.TimePeriod> busyTimes, int durationMinutes) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 7, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 22, 0);

    try {
      busyTimes.sort((a, b) {
        final aStart = a.start;
        final bStart = b.start;
        if (aStart == null || bStart == null) return 0;
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
      print("❌ Error al buscar espacio libre: $e");
    }

    return null;
  }
    /// ✅ **Agendar evento en Google Calendar**
  Future<void> agendarEventoEnCalendario(calendar.CalendarApi calendarApi, Tarea tarea) async {
    try {
      final event = calendar.Event(
        summary: tarea.titulo,
        start: calendar.EventDateTime(
          dateTime: tarea.fecha.toUtc(),
          timeZone: "America/Lima",
        ),
        end: calendar.EventDateTime(
          dateTime: tarea.fecha.toUtc().add(Duration(minutes: tarea.duracion)),
          timeZone: "America/Lima",
        ),
      );

      await calendarApi.events.insert(event, "primary");
      print("✅ Evento agregado a Google Calendar correctamente.");
    } catch (e) {
      print("❌ Error al agendar evento: $e");
    }
  }





}
  

/// 🔹 **Clase para manejar autenticación de Google**
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

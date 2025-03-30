import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    clientId: kIsWeb
      ? "547054267025-62eputqjlamebrmshg37rfohl9s10q0c.apps.googleusercontent.com"
      : null,
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
      // agrega los que necesites
    ],
  );

  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 **Corrección de `signInAndGetCalendarApi()`**
Future<calendar.CalendarApi?> signInAndGetCalendarApi({bool silentOnly = true}) async {
  try {
    GoogleSignInAccount? account = await _googleSignIn.signInSilently();

    if (account == null && !silentOnly) {
      account = await _googleSignIn.signIn();
    }

    if (account == null) {
      print("⚠️ No se pudo obtener sesión de Google.");
      return null;
    }

    final headers = await account.authHeaders;
    return calendar.CalendarApi(GoogleAuthClient(headers));
  } catch (e) {
    print("❌ Error al conectar con Google APIs: $e");
    return null;
  }
}


/// 🔹 **Encuentra el primer horario disponible para una tarea**
  Future<DateTime?> encontrarHorarioDisponible(
    calendar.CalendarApi calendarApi, String responsableUid, int duracion) async {
  try {
    final userQuery = await _firestore.collection("users").doc(responsableUid).get();
    if (!userQuery.exists) return null;

    final responsibleEmail = userQuery["email"];
    if (responsibleEmail == null || responsibleEmail.isEmpty) return null;

    DateTime now = DateTime.now();
    DateTime fechaInicio = DateTime(now.year, now.month, now.day, 8, 0);
    DateTime fechaFin = DateTime(now.year, now.month, now.day, 18, 0);

    // 🔹 Buscar eventos en los próximos 3 días
    final events = await calendarApi.events.list(
      "primary",
      timeMin: fechaInicio.toUtc(),
      timeMax: fechaInicio.add(Duration(days: 3)).toUtc(),
      orderBy: "startTime",
      singleEvents: true,
    );

    // 🔹 Si no hay eventos, asignar la primera hora disponible
    if (events.items == null || events.items!.isEmpty) {
      return fechaInicio;
    }

    // 🔹 Buscar la primera franja horaria disponible
    for (var event in events.items!) {
      if (event.start?.dateTime != null && event.end?.dateTime != null) {
        DateTime startTime = event.start!.dateTime!.toLocal();
        DateTime endTime = event.end!.dateTime!.toLocal();

        if (fechaInicio.isBefore(startTime) && fechaInicio.add(Duration(minutes: duracion)).isBefore(startTime)) {
          return fechaInicio; // ✅ Se encontró un espacio antes de un evento
        }
        if (fechaInicio.isBefore(endTime)) {
          fechaInicio = endTime.add(const Duration(minutes: 15)); // ✅ Saltar al final del evento actual
        }
        if (fechaInicio.hour >= 18) {
          fechaInicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day + 1, 8, 0); // ✅ Pasar al día siguiente
        }
      }
    }

    return fechaInicio; // ✅ Retorna la primera hora disponible encontrada
  } catch (e) {
    print("❌ Error al buscar horario disponible: $e");
    return null;
  }
}


Future<DateTime?> obtenerFechaDesdeSelector(BuildContext context) async {
    DateTime now = DateTime.now();

    // ✅ Seleccionar Fecha
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null) {
      // ✅ Seleccionar Hora
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
    return null;
  }
Future<bool> verificarTareaEnCalendario(calendar.CalendarApi calendarApi, Tarea tarea, String responsableUid) async {
  try {
    if (tarea.fecha == null) return false; // ✅ Asegurar que la fecha no sea null

    // 🔹 Obtener el email del responsable
    final userQuery = await _firestore.collection("users").doc(responsableUid).get();
    if (!userQuery.exists) return false;

    final responsibleEmail = userQuery["email"];
    if (responsibleEmail == null || responsibleEmail.isEmpty) return false;

    // 🔹 Buscar eventos en el rango de la tarea
    final events = await calendarApi.events.list(
      "primary",
      timeMin: tarea.fecha!.subtract(const Duration(minutes: 1)), 
      timeMax: tarea.fecha!.add(const Duration(minutes: 1)),
    );

    for (var event in events.items ?? []) {
      if (event.summary == tarea.titulo && event.attendees != null) {
        for (var attendee in event.attendees!) {
          if (attendee.email == responsibleEmail) {
            return true; // ✅ La tarea ya existe en el calendario del responsable
          }
        }
      }
    }
  } catch (e) {
    print("❌ Error al verificar tarea en Google Calendar: $e");
  }
  return false; // ❌ No se encontró la tarea en el calendario
}


 Future<DateTime?> encontrarHorarioParaProyecto(String proyectoId, int duracionMin) async {
  DateTime now = DateTime.now();
  DateTime fechaInicio = now.isBefore(DateTime(now.year, now.month, now.day, 8))
      ? DateTime(now.year, now.month, now.day, 10)
      : now;

  DateTime fechaFin = fechaInicio.add(Duration(minutes: duracionMin));

  final querySnapshot = await _firestore.collection("proyectos").doc(proyectoId).get();
  final data = querySnapshot.data();
  if (data == null) return null;

  String? responsableUid = data["responsable"];
  if (responsableUid == null) return null;

  final userQuery = await _firestore.collection("users").doc(responsableUid).get();
  if (!userQuery.exists) return null;

  final responsibleEmail = userQuery["email"];
  if (responsibleEmail == null || responsibleEmail.isEmpty) return null;

  final calendarApi = await signInAndGetCalendarApi();
  if (calendarApi == null) return null;

  // 🔹 Buscar en los próximos 3 días un horario libre
  for (int i = 0; i < 3; i++) {
    DateTime fechaPrueba = fechaInicio.add(Duration(days: i));

    for (int hora = 8; hora <= 17; hora++) {
      DateTime inicio = DateTime(fechaPrueba.year, fechaPrueba.month, fechaPrueba.day, hora);
      DateTime fin = inicio.add(Duration(minutes: duracionMin));

      bool hayConflicto = await verificarDisponibilidadHorario(calendarApi, responsibleEmail, inicio, fin);

      if (!hayConflicto) {
        return inicio; // ✅ Devuelve el primer horario libre
      }
    }
  }

  print("⚠️ No se encontraron horarios disponibles en los próximos 3 días.");
  return null;
}


DateTime? findFreeSlot(List<calendar.TimePeriod> busyTimes, int durationMinutes) {
  final now = DateTime.now();
  DateTime startOfDay = DateTime(now.year, now.month, now.day, 8, 0); // 🔹 Comienza a las 8 AM
  DateTime endOfDay = DateTime(now.year, now.month, now.day, 22, 0); // 🔹 Termina a las 10 PM

  busyTimes.sort((a, b) => a.start!.compareTo(b.start!));

  DateTime previousEnd = startOfDay;
  for (final busy in busyTimes) {
    final busyStart = busy.start!;
    final busyEnd = busy.end!;

    if (busyStart.difference(previousEnd).inMinutes >= durationMinutes) {
      return previousEnd;
    }
    previousEnd = busyEnd;
  }

  if (endOfDay.difference(previousEnd).inMinutes >= durationMinutes) {
    return previousEnd;
  }

  return null; // 🔹 No hay espacio disponible
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
  
 Future<void> asignarYAgendarTarea(Tarea tarea, String userId) async {
  final calendarApi = await signInAndGetCalendarApi(silentOnly: true);
  if (calendarApi == null) return;

  // Usa fecha existente o busca una libre
  DateTime? fechaInicio = tarea.fecha;

  if (fechaInicio == null) {
    fechaInicio = await encontrarHorarioDisponible(calendarApi, userId, tarea.duracion);
    if (fechaInicio == null) return;
    tarea.fecha = fechaInicio; // Asigna la nueva fecha a la tarea
  }

  await agendarEventoEnCalendario(calendarApi, tarea, userId);
}



    /// ✅ **Agendar evento en Google Calendar**
 Future<void> agendarEventoEnCalendario(calendar.CalendarApi calendarApi, Tarea tarea, String responsableUid) async {
  try {
    // 🔹 Obtener el email del responsable desde Firestore
    final userQuery = await _firestore.collection("users").doc(responsableUid).get();
    if (!userQuery.exists) {
      print("⚠️ Responsable no encontrado en Firestore.");
      return;
    }

    final responsibleEmail = userQuery["email"];
    if (responsibleEmail == null || responsibleEmail.isEmpty) {
      print("⚠️ No se encontró el email del responsable.");
      return;
    }

    // ✅ Crear el evento SIN INVITACIONES
    final event = calendar.Event(
      summary: tarea.titulo,
      start: calendar.EventDateTime(
        dateTime: tarea.fecha!.toUtc(),
        timeZone: "America/Lima",
      ),
      end: calendar.EventDateTime(
        dateTime: tarea.fecha!.toUtc().add(Duration(minutes: tarea.duracion)),
        timeZone: "America/Lima",
      ),
      // 🔹 NO AGREGAMOS `attendees` PARA EVITAR INVITACIONES
      guestsCanModify: false,  // Evita que se edite
      guestsCanInviteOthers: false, // Evita que se envíen invitaciones
      transparency: "opaque", // ✅ Asegura que se bloquee el horario
      visibility: "private", // ✅ El evento solo es visible para el usuario
    );

    // 🔹 Agregar el evento al calendario del responsable (NO DEL CREADOR)
    await calendarApi.events.insert(event, "primary", sendUpdates: "none");

    print("✅ Evento agregado directamente al Google Calendar del usuario $responsibleEmail sin invitación.");
  } catch (e) {
    print("❌ Error al agendar evento: $e");
  }
}





/// ✅ **Verifica si el horario ya está ocupado en el calendario del usuario**
Future<bool> verificarDisponibilidadHorario(calendar.CalendarApi calendarApi, String email, DateTime inicio, DateTime fin) async {
  final response = await calendarApi.freebusy.query(
    calendar.FreeBusyRequest(
      timeMin: inicio.toUtc(),
      timeMax: fin.toUtc(),
      items: [calendar.FreeBusyRequestItem(id: email)],
    ),
  );

  final busyPeriods = response.calendars?[email]?.busy ?? [];
  return busyPeriods.isNotEmpty;
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

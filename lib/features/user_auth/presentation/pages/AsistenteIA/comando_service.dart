import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/google_calendar_service.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ProyectoDetallePage.dart';  
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ProyectosPage.dart'; 
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ComandoService {
  final GoogleCalendarService _calendarService = GoogleCalendarService();

    Map<String, dynamic> procesarComando(String command) {
    command = command.toLowerCase().trim();

    if (command.contains("organizar eventos de la semana")) {
      print("📅 Organizando eventos de la semana automáticamente...");

// ✅ Llama a la función
      return {"completo": true};
    }

    if (!command.contains("agendar evento")) {
      print("❌ No es un comando válido: $command");
      return {"completo": false};
    }

    print("📝 Comando detectado: $command");

    String nombreEvento = _extraerNombreEvento(command);
    DateTime? fechaHoraEvento = _extraerFechaHoraEvento(command);

    print("📌 Nombre del evento extraído: $nombreEvento");
    print("📌 Fecha y hora extraídas: ${fechaHoraEvento?.toLocal()}");

    if (fechaHoraEvento == null) {
      fechaHoraEvento = _obtenerProximaHoraDisponible();
      print("⚠️ Fecha/hora no detectadas, asignando por defecto: ${fechaHoraEvento.toLocal()}");
    }

    return {
      "nombre": nombreEvento,
      "fechaHora": fechaHoraEvento,
      "completo": true,
    };
  }
  
    /// Genera tareas predeterminadas si el proyecto no tiene
  List<Tarea> generarTareasPorDefecto(Proyecto proyecto) {
    if (proyecto.tareas.isNotEmpty) return proyecto.tareas; // Evita sobreescribir tareas existentes

    List<Tarea> nuevasTareas = [];
    DateTime fechaInicio = DateTime.now();

    return nuevasTareas;
  }

  /// Asigna tareas a un proyecto si no tiene
  Future<void> asignarTareasAProyecto(Proyecto proyecto) async {
    if (proyecto.tareas.isEmpty) {
      proyecto.tareas = generarTareasPorDefecto(proyecto);
      await guardarProyectos(); // Guardar cambios en SharedPreferences
    }
  }

    Future<void> guardarProyectos([List<Proyecto>? proyectos]) async { 
      final prefs = await SharedPreferences.getInstance();
      List<String> proyectosData = prefs.getStringList('proyectos') ?? [];
      List<Proyecto> proyectosGuardados = proyectosData.map((p) => Proyecto.fromJson(jsonDecode(p))).toList();

      // Si proyectos es null, recuperar desde SharedPreferences
      if (proyectos == null) {
        final proyectosData = prefs.getStringList('proyectos') ?? [];
        proyectos = proyectosData.map((p) => Proyecto.fromJson(jsonDecode(p))).toList();
      }
      // Busca y reemplaza el proyecto modificado en la lista
      for (var p in proyectos) {
        int index = proyectosGuardados.indexWhere((proyecto) => proyecto.id == p.id);
        if (index != -1) {
          proyectosGuardados[index] = p;
        }
      }
      // Serializar los proyectos y guardar en SharedPreferences
      final updatedData = proyectosGuardados.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList('proyectos', updatedData);
    }

    void iniciarRevisionAutomatica() {
    Timer.periodic(Duration(hours: 24), (timer) async {
      DateTime now = DateTime.now();
      if (now.hour == 23) { // Ejecutar revisión a las 11 PM
        await verificarTareasPendientesYReagendar();
      }
    });
    }
Future<void> verificarTareasPendientesYReagendar() async {
  final prefs = await SharedPreferences.getInstance();
  final proyectosData = prefs.getStringList('proyectos') ?? [];
  List<Proyecto> proyectos = proyectosData.map((p) => Proyecto.fromJson(jsonDecode(p))).toList();

  DateTime now = DateTime.now();
  List<DateTime> availableTimes = [];

  for (int i = 0; i < 7; i++) {
  }

  for (var proyecto in proyectos) {
    for (var tarea in proyecto.tareas) {
      if (!tarea.completado && tarea.fecha.isBefore(now)) {
        print("⏳ Reagendando tarea pendiente: ${tarea.titulo}");
        if (availableTimes.isNotEmpty) {
          tarea.fecha = availableTimes.removeAt(0);
        }
      }
    }
  }

  await guardarProyectos(proyectos); // 🔹 Ahora pasamos los proyectos
  print("✅ Tareas no completadas han sido reagendadas.");
}

  DateTime _obtenerProximaHoraDisponible() {
    DateTime now = DateTime.now();
    if (now.hour < 10) {
      return DateTime(now.year, now.month, now.day, 10, 0);
    }
    return DateTime(now.year, now.month, now.day + 1, 10, 0);
  }

  String _extraerNombreEvento(String command) {
    final match = RegExp(r"agendar evento (.*?) el").firstMatch(command);
    return match != null ? match.group(1)!.trim() : "Evento sin nombre";
  }

  DateTime? _extraerFechaHoraEvento(String command) {
    print("🔍 Intentando extraer fecha y hora de: $command");

    final match = RegExp(
      r"el (\d{1,2} de [a-zA-Z]+(?: de \d{4})?)\s*a las (\d{1,2}(?::\d{2})?)?\s*(AM|PM|a\.m\.|p\.m\.)?"
    ).firstMatch(command);

    if (match != null) {
      print("✅ Coincidencia encontrada: ${match.group(0)}");

      String fechaTexto = match.group(1)!;
      String? horaTexto = match.group(2);
      String? periodo = match.group(3);

      print("📆 Fecha detectada: $fechaTexto");
      print("⏰ Hora detectada: ${horaTexto ?? 'null'} ${periodo ?? ''}");

      try {
        DateTime fechaBase = DateFormat("d 'de' MMMM", "es_ES").parse(fechaTexto);
        int hora = 10, minuto = 0;

        if (horaTexto != null) {
          String horaFinal = horaTexto.contains(":") ? horaTexto : "$horaTexto:00";
          String periodoFinal = (periodo ?? "AM").replaceAll(".", "").toUpperCase();
          DateTime horaBase = DateFormat("h:mm a", "en_US").parse("$horaFinal $periodoFinal");

          hora = horaBase.hour;
          minuto = horaBase.minute;
        }

        DateTime fechaHoraFinal = DateTime(
          DateTime.now().year, fechaBase.month, fechaBase.day, hora, minuto);

        print("📅 Fecha y hora final procesadas: $fechaHoraFinal");
        return fechaHoraFinal;
      } catch (e) {
        print("❌ Error al convertir fecha/hora: $e");
        return null;
      }
    }

    print("⚠️ No se detectó una fecha válida en el comando.");
    return null;
  }

  void crearEventoEnGoogleCalendar(String nombre, DateTime fechaHora) async {
    final calendarApi = await _calendarService.signInAndGetCalendarApi();

    if (calendarApi == null) {
      print("❌ No se pudo conectar con Google Calendar.");
      return;
    }

    print("📅 Agendando evento con fecha y hora exactas: $nombre el ${fechaHora.toLocal()}");

  }

}

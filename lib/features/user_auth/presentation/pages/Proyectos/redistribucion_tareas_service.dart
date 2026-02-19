import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/google_calendar_service.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

/// Resultado de la redistribución de tareas
class ResultadoRedistribucion {
  final List<Tarea> tareasActualizadas;
  final int tareasRedistribuidas;
  final int tareasCompletadas;
  final int tareasPendientes;
  final Map<String, dynamic> estadisticas;

  ResultadoRedistribucion({
    required this.tareasActualizadas,
    required this.tareasRedistribuidas,
    required this.tareasCompletadas,
    required this.tareasPendientes,
    required this.estadisticas,
  });
}

/// Servicio para redistribuir tareas pendientes de forma inteligente
class RedistribucionTareasService {
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  /// Redistribuye las tareas pendientes dentro del rango de fechas del proyecto
  /// considerando dificultad, prioridad y carga de trabajo
  /// Si se proporciona calendarApi, usará Google Calendar para encontrar slots libres
  Future<ResultadoRedistribucion> redistribuirTareas({
    required Proyecto proyecto,
    required List<Tarea> tareas,
    DateTime? fechaInicioPersonalizada,
    DateTime? fechaFinPersonalizada,
    calendar.CalendarApi? calendarApi,
    String? responsableUid,
  }) async {
    // Separar tareas completadas y pendientes
    final tareasCompletadas = tareas.where((t) => t.completado).toList();
    final tareasPendientes = tareas.where((t) => !t.completado).toList();

    if (tareasPendientes.isEmpty) {
      return ResultadoRedistribucion(
        tareasActualizadas: tareas,
        tareasRedistribuidas: 0,
        tareasCompletadas: tareasCompletadas.length,
        tareasPendientes: 0,
        estadisticas: {'mensaje': 'No hay tareas pendientes para redistribuir'},
      );
    }

    // Determinar rango de fechas - empezar desde el siguiente día laboral
    DateTime fechaInicioBase = fechaInicioPersonalizada ?? DateTime.now();

    // Si es fin de semana, empezar el lunes
    if (fechaInicioBase.weekday > 5) {
      fechaInicioBase = _siguienteDiaLaboral(fechaInicioBase);
    }

    final fechaInicio = fechaInicioBase;
    final fechaFin = fechaFinPersonalizada ?? proyecto.fechaFin ?? _calcularFechaFinDefecto(fechaInicio);

    // Validar que el rango sea válido
    if (fechaFin.isBefore(fechaInicio)) {
      return ResultadoRedistribucion(
        tareasActualizadas: tareas,
        tareasRedistribuidas: 0,
        tareasCompletadas: tareasCompletadas.length,
        tareasPendientes: tareasPendientes.length,
        estadisticas: {'error': 'El rango de fechas no es válido'},
      );
    }

    // Ordenar tareas pendientes por prioridad y dificultad
    final tareasOrdenadas = _ordenarTareasPorImportancia(tareasPendientes);

    // Calcular distribución óptima de fechas
    // Si tenemos Google Calendar API, usarla para encontrar slots libres
    List<Tarea> tareasRedistribuidas;
    if (calendarApi != null && responsableUid != null) {
      tareasRedistribuidas = await _distribuirFechasConCalendar(
        tareasOrdenadas,
        fechaInicio,
        fechaFin,
        calendarApi,
        responsableUid,
      );
    } else {
      tareasRedistribuidas = _distribuirFechas(
        tareasOrdenadas,
        fechaInicio,
        fechaFin,
      );
    }

    // Combinar tareas completadas (sin cambios) con tareas redistribuidas
    final todasLasTareas = [...tareasCompletadas, ...tareasRedistribuidas];

    // Calcular estadísticas
    final estadisticas = _calcularEstadisticas(
      tareasRedistribuidas,
      fechaInicio,
      fechaFin,
    );

    return ResultadoRedistribucion(
      tareasActualizadas: todasLasTareas,
      tareasRedistribuidas: tareasRedistribuidas.length,
      tareasCompletadas: tareasCompletadas.length,
      tareasPendientes: tareasRedistribuidas.length,
      estadisticas: estadisticas,
    );
  }

  /// Ordena las tareas por importancia (prioridad + dificultad)
  List<Tarea> _ordenarTareasPorImportancia(List<Tarea> tareas) {
    final tareasConPeso = tareas.map((tarea) {
      // Calcular peso: prioridad (1-3) * 10 + dificultad (1-3)
      final pesoPrioridad = tarea.prioridad * 10;
      final pesoDificultad = _obtenerPesoDificultad(tarea.dificultad ?? 'media');
      final pesoTotal = pesoPrioridad + pesoDificultad;

      return {'tarea': tarea, 'peso': pesoTotal};
    }).toList();

    // Ordenar por peso descendente (más importante primero)
    tareasConPeso.sort((a, b) => (b['peso'] as int).compareTo(a['peso'] as int));

    return tareasConPeso.map((item) => item['tarea'] as Tarea).toList();
  }

  /// Convierte la dificultad a un peso numérico
  int _obtenerPesoDificultad(String dificultad) {
    switch (dificultad.toLowerCase()) {
      case 'alta':
        return 3;
      case 'media':
        return 2;
      case 'baja':
        return 1;
      default:
        return 2;
    }
  }

  /// Distribuye las fechas de las tareas de forma inteligente
  List<Tarea> _distribuirFechas(
    List<Tarea> tareas,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) {
    if (tareas.isEmpty) return [];

    // Calcular capacidad de trabajo por día (en minutos)
    // Asumimos 8 horas laborales por día (480 minutos)
    const minutosLaboralesPorDia = 480;

    List<Tarea> tareasActualizadas = [];
    DateTime fechaActual = fechaInicio;
    int minutosAcumuladosHoy = 0;

    for (var tarea in tareas) {
      // Si la tarea no cabe en el día actual, pasar al siguiente día laboral
      if (minutosAcumuladosHoy + tarea.duracion > minutosLaboralesPorDia) {
        fechaActual = _siguienteDiaLaboral(fechaActual);
        minutosAcumuladosHoy = 0;
      }

      // Si excedemos la fecha fin, ajustar a la fecha fin con advertencia
      if (fechaActual.isAfter(fechaFin)) {
        fechaActual = fechaFin;
      }

      // Asignar hora basada en minutos acumulados
      final horaInicio = 9 + (minutosAcumuladosHoy ~/ 60); // Empieza a las 9 AM
      final minutos = minutosAcumuladosHoy % 60;

      final nuevaFecha = DateTime(
        fechaActual.year,
        fechaActual.month,
        fechaActual.day,
        horaInicio.clamp(9, 17), // Entre 9 AM y 5 PM
        minutos,
      );

      // Crear copia de la tarea con nueva fecha
      final tareaActualizada = Tarea(
        titulo: tarea.titulo,
        fecha: nuevaFecha,
        duracion: tarea.duracion,
        prioridad: tarea.prioridad,
        completado: tarea.completado,
        colorId: tarea.colorId,
        responsables: tarea.responsables,
        tipoTarea: tarea.tipoTarea,
        requisitos: tarea.requisitos,
        dificultad: tarea.dificultad,
        descripcion: tarea.descripcion,
        tareasPrevias: tarea.tareasPrevias,
        area: tarea.area,
        habilidadesRequeridas: tarea.habilidadesRequeridas,
        fasePMI: tarea.fasePMI,
        entregable: tarea.entregable,
        paqueteTrabajo: tarea.paqueteTrabajo,
      );

      tareasActualizadas.add(tareaActualizada);
      minutosAcumuladosHoy += tarea.duracion;
    }

    return tareasActualizadas;
  }

  /// Distribuye las fechas usando Google Calendar para encontrar slots libres
  Future<List<Tarea>> _distribuirFechasConCalendar(
    List<Tarea> tareas,
    DateTime fechaInicio,
    DateTime fechaFin,
    calendar.CalendarApi calendarApi,
    String responsableUid,
  ) async {
    if (tareas.isEmpty) return [];

    List<Tarea> tareasActualizadas = [];

    // Obtener todos los horarios ocupados en el rango
    final busyTimes = await _calendarService.getBusyTimes(
      calendarApi,
      fechaInicio,
      fechaFin,
    );

    DateTime fechaActual = fechaInicio;

    for (var tarea in tareas) {
      // Buscar el primer slot libre que pueda acomodar esta tarea
      DateTime? slotEncontrado = await _encontrarSiguienteSlotLibre(
        calendarApi,
        responsableUid,
        fechaActual,
        fechaFin,
        tarea.duracion,
        busyTimes,
      );

      if (slotEncontrado == null) {
        // Si no hay slot disponible, usar el método tradicional
        slotEncontrado = _asignarSlotTradicional(fechaActual, tarea.duracion);
      }

      // Crear copia de la tarea con nueva fecha programada
      final tareaActualizada = Tarea(
        titulo: tarea.titulo,
        fecha: tarea.fecha, // Mantener fecha límite
        fechaLimite: tarea.fechaLimite,
        fechaProgramada: slotEncontrado, // Asignar fecha programada
        fechaCompletada: tarea.fechaCompletada,
        duracion: tarea.duracion,
        prioridad: tarea.prioridad,
        completado: tarea.completado,
        colorId: tarea.colorId,
        responsables: tarea.responsables,
        tipoTarea: tarea.tipoTarea,
        requisitos: tarea.requisitos,
        dificultad: tarea.dificultad,
        descripcion: tarea.descripcion,
        tareasPrevias: tarea.tareasPrevias,
        area: tarea.area,
        habilidadesRequeridas: tarea.habilidadesRequeridas,
        fasePMI: tarea.fasePMI,
        entregable: tarea.entregable,
        paqueteTrabajo: tarea.paqueteTrabajo,
        googleCalendarEventId: tarea.googleCalendarEventId,
      );

      tareasActualizadas.add(tareaActualizada);

      // Actualizar la fecha actual para la siguiente tarea
      fechaActual = slotEncontrado.add(Duration(minutes: tarea.duracion + 15)); // 15 min buffer
    }

    return tareasActualizadas;
  }

  /// Encuentra el siguiente slot libre en Google Calendar
  Future<DateTime?> _encontrarSiguienteSlotLibre(
    calendar.CalendarApi calendarApi,
    String responsableUid,
    DateTime desde,
    DateTime hasta,
    int duracionMinutos,
    List<calendar.TimePeriod> busyTimes,
  ) async {
    DateTime fechaBusqueda = desde;
    const horaInicio = 8; // 8 AM
    const horaFin = 21; // 9 PM

    // Buscar hasta 14 días en el futuro
    final maxDias = 14;
    int diasBuscados = 0;

    while (diasBuscados < maxDias && fechaBusqueda.isBefore(hasta)) {
      // ✅ INCLUIR TODOS LOS DÍAS (lunes a domingo)
      // No saltar fines de semana

      // Probar slots cada 30 minutos dentro del horario extendido
      for (int hora = horaInicio; hora < horaFin; hora++) {
        for (int minuto = 0; minuto < 60; minuto += 30) {
          final slotInicio = DateTime(
            fechaBusqueda.year,
            fechaBusqueda.month,
            fechaBusqueda.day,
            hora,
            minuto,
          );

          final slotFin = slotInicio.add(Duration(minutes: duracionMinutos));

          // Verificar que el slot termine antes de las 9 PM
          if (slotFin.hour >= horaFin) continue;

          // Verificar si este slot está libre
          final hayConflicto = await _calendarService.verificarDisponibilidadHorario(
            calendarApi,
            responsableUid,
            slotInicio,
            slotFin,
          );

          if (!hayConflicto) {
            return slotInicio; // ✅ Slot libre encontrado
          }
        }
      }

      // Pasar al siguiente día (todos los días)
      fechaBusqueda = fechaBusqueda.add(const Duration(days: 1));
      diasBuscados++;
    }

    return null; // No se encontró slot libre
  }

  /// Asignar slot de forma tradicional (sin Google Calendar)
  DateTime _asignarSlotTradicional(DateTime fecha, int duracion) {
    // ✅ TODOS LOS DÍAS son válidos (lunes a domingo)
    DateTime fechaAjustada = fecha;

    // Asignar a las 8 AM si no tiene hora o está fuera del rango
    if (fechaAjustada.hour < 8 || fechaAjustada.hour >= 21) {
      fechaAjustada = DateTime(
        fechaAjustada.year,
        fechaAjustada.month,
        fechaAjustada.day,
        8,
        0,
      );
    }

    return fechaAjustada;
  }

  /// Calcula el siguiente día laboral (lunes a viernes)
  DateTime _siguienteDiaLaboral(DateTime fecha) {
    DateTime siguiente = fecha.add(const Duration(days: 1));

    // Si es sábado (6) o domingo (7), avanzar al lunes
    while (siguiente.weekday > 5) {
      siguiente = siguiente.add(const Duration(days: 1));
    }

    return siguiente;
  }

  /// Calcula una fecha fin por defecto (30 días desde el inicio)
  DateTime _calcularFechaFinDefecto(DateTime fechaInicio) {
    return fechaInicio.add(const Duration(days: 30));
  }

  /// Calcula estadísticas sobre la redistribución
  Map<String, dynamic> _calcularEstadisticas(
    List<Tarea> tareas,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) {
    if (tareas.isEmpty) {
      return {
        'duracionTotalHoras': 0,
        'promedioTareasPorDia': 0,
        'distribucionPorDificultad': {},
        'cargaPorResponsable': {},
      };
    }

    // Duración total en horas
    final duracionTotal = tareas.fold<int>(0, (sum, t) => sum + t.duracion);
    final duracionTotalHoras = (duracionTotal / 60).toStringAsFixed(1);

    // Promedio de tareas por día
    final diasDisponibles = fechaFin.difference(fechaInicio).inDays + 1;
    final promedioTareasPorDia = (tareas.length / diasDisponibles).toStringAsFixed(1);

    // Distribución por dificultad
    final distribucionDificultad = <String, int>{};
    for (var tarea in tareas) {
      final dif = tarea.dificultad ?? 'media';
      distribucionDificultad[dif] = (distribucionDificultad[dif] ?? 0) + 1;
    }

    // Carga por responsable
    final cargaResponsable = <String, int>{};
    for (var tarea in tareas) {
      for (var responsable in tarea.responsables) {
        cargaResponsable[responsable] = (cargaResponsable[responsable] ?? 0) + tarea.duracion;
      }
    }

    return {
      'duracionTotalHoras': duracionTotalHoras,
      'promedioTareasPorDia': promedioTareasPorDia,
      'distribucionPorDificultad': distribucionDificultad,
      'cargaPorResponsable': cargaResponsable,
      'diasDisponibles': diasDisponibles,
      'tareasAlta': distribucionDificultad['alta'] ?? 0,
      'tareasMedia': distribucionDificultad['media'] ?? 0,
      'tareasBaja': distribucionDificultad['baja'] ?? 0,
    };
  }

  /// Analiza si las tareas caben en el tiempo disponible
  bool verificarFactibilidad({
    required List<Tarea> tareasPendientes,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) {
    final diasDisponibles = fechaFin.difference(fechaInicio).inDays + 1;
    const minutosLaboralesPorDia = 480; // 8 horas
    final capacidadTotal = diasDisponibles * minutosLaboralesPorDia;

    final duracionTotal = tareasPendientes.fold<int>(
      0,
      (sum, tarea) => sum + tarea.duracion,
    );

    return duracionTotal <= capacidadTotal;
  }

  /// Sugiere una fecha fin óptima basada en las tareas pendientes
  DateTime sugerirFechaFinOptima({
    required List<Tarea> tareasPendientes,
    required DateTime fechaInicio,
  }) {
    if (tareasPendientes.isEmpty) {
      return fechaInicio.add(const Duration(days: 7));
    }

    final duracionTotal = tareasPendientes.fold<int>(
      0,
      (sum, tarea) => sum + tarea.duracion,
    );

    const minutosLaboralesPorDia = 480; // 8 horas
    final diasNecesarios = (duracionTotal / minutosLaboralesPorDia).ceil();

    // Agregar 20% de buffer para imprevistos
    final diasConBuffer = (diasNecesarios * 1.2).ceil();

    DateTime fechaSugerida = fechaInicio;
    int diasAgregados = 0;

    while (diasAgregados < diasConBuffer) {
      fechaSugerida = fechaSugerida.add(const Duration(days: 1));
      // Solo contar días laborales
      if (fechaSugerida.weekday <= 5) {
        diasAgregados++;
      }
    }

    return fechaSugerida;
  }
}

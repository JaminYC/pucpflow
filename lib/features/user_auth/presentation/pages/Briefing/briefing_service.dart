import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'briefing_models.dart';
import '../Proyectos/tarea_model.dart';
import '../calendar_events_page.dart';
import '../Login/google_calendar_service.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

/// Servicio principal para generar y gestionar briefings diarios
class BriefingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  /// Genera el briefing completo para un día específico
  Future<BriefingDiario> generarBriefing({
    required String userId,
    DateTime? fecha,
    bool incluirEventosGoogle = true,
  }) async {
    final fechaObjetivo = fecha ?? DateTime.now();
    final fechaSinHora = DateTime(
      fechaObjetivo.year,
      fechaObjetivo.month,
      fechaObjetivo.day,
    );

    // Obtener nombre del usuario
    final userName = await _obtenerNombreUsuario(userId);

    // Obtener todas las tareas del día
    final tareas = await _obtenerTareasDelDia(userId, fechaSinHora);

    // Obtener eventos de Google Calendar si está habilitado
    List<CalendarEvent> eventos = [];
    if (incluirEventosGoogle) {
      eventos = await _obtenerEventosGoogle(fechaSinHora);
    }

    // Separar tareas por prioridad
    final tareasPrioritarias = <TareaBriefing>[];
    final tareasNormales = <TareaBriefing>[];

    for (var tarea in tareas) {
      if (tarea.prioridad >= 3) {
        tareasPrioritarias.add(tarea);
      } else {
        tareasNormales.add(tarea);
      }
    }

    // Ordenar tareas por hora
    tareasPrioritarias.sort(_compararTareasPorHora);
    tareasNormales.sort(_compararTareasPorHora);

    // Calcular métricas
    final metrics = await _calcularMetricas(
      userId: userId,
      tareasHoy: tareas,
      fecha: fechaSinHora,
    );

    // Detectar conflictos de horario
    final conflictos = _detectarConflictos([...tareasPrioritarias, ...tareasNormales]);

    // Generar insights básicos (sin IA por ahora)
    final insights = _generarInsightsBasicos(
      metrics: metrics,
      conflictos: conflictos,
      tareas: tareas,
    );

    return BriefingDiario(
      fecha: fechaSinHora,
      saludo: BriefingDiario.generarSaludo(userName, fechaObjetivo),
      metrics: metrics,
      tareasPrioritarias: tareasPrioritarias,
      tareasNormales: tareasNormales,
      eventos: eventos,
      insights: insights,
      conflictos: conflictos,
    );
  }

  /// Obtiene el nombre del usuario desde Firestore
  Future<String> _obtenerNombreUsuario(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['name'] ?? data?['displayName'] ?? 'Usuario';
      }
    } catch (e) {
      debugPrint('Error obteniendo nombre de usuario: $e');
    }
    return 'Usuario';
  }

  /// Obtiene todas las tareas del día desde todos los proyectos del usuario
  Future<List<TareaBriefing>> _obtenerTareasDelDia(
    String userId,
    DateTime fecha,
  ) async {
    final List<TareaBriefing> todasLasTareas = [];

    debugPrint('🎯 BRIEFING: Obteniendo tareas para userId: $userId');
    debugPrint('🎯 BRIEFING: Fecha objetivo: $fecha');

    try {
      // Obtener proyectos donde el usuario es propietario O participante
      // Firestore no soporta OR directo, así que hacemos dos consultas
      final proyectosSnapshot1 = await _firestore
          .collection('proyectos')
          .where('propietario', isEqualTo: userId)
          .get();

      final proyectosSnapshot2 = await _firestore
          .collection('proyectos')
          .where('participantes', arrayContains: userId)
          .get();

      // Combinar resultados eliminando duplicados
      final Map<String, QueryDocumentSnapshot> proyectosMap = {};
      for (var doc in proyectosSnapshot1.docs) {
        proyectosMap[doc.id] = doc;
      }
      for (var doc in proyectosSnapshot2.docs) {
        proyectosMap[doc.id] = doc;
      }

      final proyectosDocs = proyectosMap.values.toList();

      debugPrint('📂 Proyectos encontrados: ${proyectosDocs.length}');

      // Para cada proyecto, obtener sus tareas
      for (var proyectoDoc in proyectosDocs) {
        final proyectoId = proyectoDoc.id;
        final proyectoData = proyectoDoc.data() as Map<String, dynamic>?;
        final proyectoNombre = proyectoData?['nombre'] ?? 'Sin nombre';

        debugPrint('📁 Proyecto: $proyectoNombre (ID: $proyectoId)');

        // Leer tareas de la subcolección
        final tareasSnapshot = await _firestore.collection("proyectos").doc(proyectoId).collection("tareas").get();
        final tareasArray = tareasSnapshot.docs.map((d) => d.data()).toList();

        debugPrint('   📊 TOTAL tareas en proyecto: ${tareasArray.length}');

        // Filtrar tareas NO completadas
        final tareasNoCompletadas = tareasArray.where((tareaData) {
          final completado = tareaData['completado'] ?? false;
          return !completado;
        }).toList();

        debugPrint('   📝 Tareas NO completadas: ${tareasNoCompletadas.length}');

        // Procesar cada tarea no completada
        int tareaIndex = 0;
        for (var tareaData in tareasNoCompletadas) {
          final tarea = Tarea.fromJson(tareaData);
          final tareaId = '${proyectoId}_tarea_$tareaIndex'; // Generar ID único

          // Filtrar solo tareas del día objetivo
          if (_esTareaDelDia(tarea, fecha)) {
            // Verificar si tiene dependencias pendientes
            final tieneDependencias = await _tieneDependenciasPendientes(
              proyectoId: proyectoId,
              tareasPrevias: tarea.tareasPrevias,
            );

            // Determinar motivo de prioridad
            final motivo = _determinarMotivoPrioridad(tarea, fecha);

            // Crear TareaBriefing enriquecida
            final tareaBriefing = TareaBriefing.fromTarea(
              tarea: tarea,
              tareaId: tareaId,
              proyectoId: proyectoId,
              proyectoNombre: proyectoNombre,
              tieneDependenciasPendientes: tieneDependencias,
              motivoPrioridad: motivo,
            );

            todasLasTareas.add(tareaBriefing);
          }

          tareaIndex++;
        }
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo tareas del día: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }

    debugPrint('✅ Total tareas del día encontradas: ${todasLasTareas.length}');
    return todasLasTareas;
  }

  /// Verifica si una tarea pertenece al día especificado
  bool _esTareaDelDia(Tarea tarea, DateTime fecha) {
    // Priorizar fechaProgramada, luego fechaLimite, luego fecha (legacy)
    DateTime? fechaRelevante = tarea.fechaProgramada ?? tarea.fechaLimite ?? tarea.fecha;

    debugPrint('🔍 Verificando tarea: ${tarea.titulo}');
    debugPrint('   fechaProgramada: ${tarea.fechaProgramada}');
    debugPrint('   fechaLimite: ${tarea.fechaLimite}');
    debugPrint('   fecha (legacy): ${tarea.fecha}');
    debugPrint('   fechaRelevante: $fechaRelevante');
    debugPrint('   Fecha objetivo briefing: $fecha');

    if (fechaRelevante == null) {
      // Si no tiene ninguna fecha, considerarla para hoy si no está completada
      final hoy = DateTime.now();
      final esHoy = fecha.year == hoy.year &&
          fecha.month == hoy.month &&
          fecha.day == hoy.day;
      debugPrint('   ❓ Sin fecha → es hoy? $esHoy');
      return esHoy;
    }

    final esDelDia = fechaRelevante.year == fecha.year &&
        fechaRelevante.month == fecha.month &&
        fechaRelevante.day == fecha.day;

    debugPrint('   ${esDelDia ? "✅" : "❌"} Es del día? $esDelDia');

    return esDelDia;
  }

  /// Verifica si una tarea tiene dependencias pendientes
  Future<bool> _tieneDependenciasPendientes({
    required String proyectoId,
    required List<String> tareasPrevias,
  }) async {
    if (tareasPrevias.isEmpty) return false;

    try {
      for (var tareaId in tareasPrevias) {
        final tareaDoc = await _firestore
            .collection('proyectos')
            .doc(proyectoId)
            .collection('tareas')
            .doc(tareaId)
            .get();

        if (tareaDoc.exists) {
          final data = tareaDoc.data();
          final completado = data?['completado'] ?? false;
          if (!completado) {
            return true; // Hay al menos una dependencia pendiente
          }
        }
      }
    } catch (e) {
      debugPrint('Error verificando dependencias: $e');
    }

    return false;
  }

  /// Determina el motivo por el cual una tarea es prioritaria
  String _determinarMotivoPrioridad(Tarea tarea, DateTime fechaHoy) {
    final motivos = <String>[];

    // Prioridad alta explícita
    if (tarea.prioridad == 3) {
      motivos.add('Prioridad alta');
    }

    // Tiene hora programada cercana
    if (tarea.fechaProgramada != null) {
      final ahora = DateTime.now();
      final diferencia = tarea.fechaProgramada!.difference(ahora);

      if (diferencia.inHours <= 2 && diferencia.inMinutes > 0) {
        motivos.add('Inicio en ${diferencia.inMinutes} min');
      } else if (diferencia.inHours <= 0 && diferencia.inMinutes <= 0 && diferencia.inMinutes > -60) {
        motivos.add('¡Debe iniciar ahora!');
      }
    }

    // Deadline cercano (menos de 24 horas)
    if (tarea.fechaLimite != null) {
      final ahora = DateTime.now();
      final diferencia = tarea.fechaLimite!.difference(ahora);

      if (diferencia.inHours <= 24 && diferencia.inHours > 0) {
        motivos.add('Deadline en ${diferencia.inHours}h');
      } else if (diferencia.inHours <= 0) {
        motivos.add('⚠️ Deadline vencido');
      }
    }

    // Es bloqueante para otras tareas
    if (tarea.tareasPrevias.isNotEmpty) {
      motivos.add('Bloqueante para ${tarea.tareasPrevias.length} tareas');
    }

    // Fase crítica de PMI
    if (tarea.fasePMI != null) {
      if (tarea.fasePMI == 'Cierre' || tarea.fasePMI == 'Monitoreo') {
        motivos.add('Fase ${tarea.fasePMI}');
      }
    }

    return motivos.isEmpty ? '' : motivos.join(' • ');
  }

  /// Obtiene eventos de Google Calendar del día
  Future<List<CalendarEvent>> _obtenerEventosGoogle(DateTime fecha) async {
    try {
      final calendarApi = await _calendarService.signInAndGetCalendarApi(
        silentOnly: true,
      );

      if (calendarApi != null) {
        final inicioDelDia = DateTime(fecha.year, fecha.month, fecha.day);
        final finDelDia = inicioDelDia.add(const Duration(days: 1));

        final events = await calendarApi.events.list(
          "primary",
          timeMin: inicioDelDia.toUtc(),
          timeMax: finDelDia.toUtc(),
          maxResults: 50,
          singleEvents: true,
          orderBy: 'startTime',
        );

        return (events.items ?? []).map((event) {
          final eventDateTime = event.start?.dateTime ?? event.start?.date;
          return CalendarEvent(
            titulo: event.summary ?? "(Sin título)",
            fecha: eventDateTime,
            tipo: 'google',
            descripcion: event.description,
            googleEvent: event,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error obteniendo eventos de Google Calendar: $e');
    }

    return [];
  }

  /// Calcula las métricas del briefing
  Future<BriefingMetrics> _calcularMetricas({
    required String userId,
    required List<TareaBriefing> tareasHoy,
    required DateTime fecha,
  }) async {
    // Total de tareas de hoy
    final totalTareas = tareasHoy.length;

    // Tareas prioritarias
    final tareasPrioritarias = tareasHoy.where((t) => t.prioridad >= 3).length;

    // Calcular tiempo total estimado
    final minutosTotal = tareasHoy.fold<int>(
      0,
      (sum, tarea) => sum + tarea.duracion,
    );
    final horasEstimadas = minutosTotal ~/ 60;
    final minutosEstimados = minutosTotal % 60;

    // Calcular carga del día (basado en 8 horas = 480 minutos)
    final cargaDelDia = (minutosTotal / 480.0).clamp(0.0, 2.0);

    // Obtener tareas completadas ayer
    final tareasAyer = await _obtenerTareasCompletadasAyer(userId, fecha);

    // Calcular racha actual
    final racha = await _calcularRacha(userId, fecha);

    return BriefingMetrics(
      totalTareas: totalTareas,
      tareasCompletadasAyer: tareasAyer,
      horasEstimadas: horasEstimadas,
      minutosEstimados: minutosEstimados,
      tareasPrioritarias: tareasPrioritarias,
      rachaActual: racha,
      cargaDelDia: cargaDelDia,
    );
  }

  /// Obtiene cantidad de tareas completadas ayer
  Future<int> _obtenerTareasCompletadasAyer(String userId, DateTime fecha) async {
    final ayer = fecha.subtract(const Duration(days: 1));
    final inicioAyer = DateTime(ayer.year, ayer.month, ayer.day);
    final finAyer = inicioAyer.add(const Duration(days: 1));

    try {
      final proyectosSnapshot = await _firestore
          .collection('proyectos')
          .where('uid', isEqualTo: userId)
          .get();

      int count = 0;
      for (var proyectoDoc in proyectosSnapshot.docs) {
        final tareasSnapshot = await _firestore
            .collection('proyectos')
            .doc(proyectoDoc.id)
            .collection('tareas')
            .where('completado', isEqualTo: true)
            .get();

        // Filtrar por fecha de completitud (si existe ese campo)
        for (var tareaDoc in tareasSnapshot.docs) {
          final data = tareaDoc.data();
          final fechaTarea = data['fecha'];
          if (fechaTarea != null) {
            final fechaDateTime = DateTime.parse(fechaTarea);
            if (fechaDateTime.isAfter(inicioAyer) &&
                fechaDateTime.isBefore(finAyer)) {
              count++;
            }
          }
        }
      }

      return count;
    } catch (e) {
      debugPrint('Error obteniendo tareas de ayer: $e');
      return 0;
    }
  }

  /// Calcula la racha actual de días productivos
  Future<int> _calcularRacha(String userId, DateTime fecha) async {
    // TODO: Implementar cálculo de racha basado en historial
    // Por ahora retornamos 0
    return 0;
  }

  /// Compara dos tareas para ordenarlas por hora
  int _compararTareasPorHora(TareaBriefing a, TareaBriefing b) {
    // Si ambas tienen hora, ordenar por hora
    if (a.horaInicio != null && b.horaInicio != null) {
      return a.horaInicio!.compareTo(b.horaInicio!);
    }

    // Si solo una tiene hora, ponerla primero
    if (a.horaInicio != null) return -1;
    if (b.horaInicio != null) return 1;

    // Si ninguna tiene hora, ordenar por prioridad
    return b.prioridad.compareTo(a.prioridad);
  }

  /// Detecta conflictos de horario entre tareas
  List<ConflictoHorario> _detectarConflictos(List<TareaBriefing> tareas) {
    final conflictos = <ConflictoHorario>[];

    // Solo revisar tareas con hora programada
    final tareasConHora = tareas.where((t) => t.horaInicio != null).toList();
    if (tareasConHora.length < 2) return conflictos;

    // Ordenar por hora de inicio
    tareasConHora.sort((a, b) => a.horaInicio!.compareTo(b.horaInicio!));

    // Revisar solapamientos
    for (int i = 0; i < tareasConHora.length - 1; i++) {
      final tarea1 = tareasConHora[i];
      final finTarea1 = tarea1.horaInicio!.add(Duration(minutes: tarea1.duracion));

      for (int j = i + 1; j < tareasConHora.length; j++) {
        final tarea2 = tareasConHora[j];

        // Si la tarea 2 empieza antes de que termine la tarea 1
        if (tarea2.horaInicio!.isBefore(finTarea1)) {
          conflictos.add(ConflictoHorario(
            tarea1: tarea1,
            tarea2: tarea2,
            descripcion: ConflictoHorario.generarDescripcion(tarea1, tarea2),
          ));
        }
      }
    }

    return conflictos;
  }

  /// Genera insights básicos sin IA
  List<String> _generarInsightsBasicos({
    required BriefingMetrics metrics,
    required List<ConflictoHorario> conflictos,
    required List<TareaBriefing> tareas,
  }) {
    final insights = <String>[];

    // Insight sobre carga del día
    if (metrics.cargaDelDia > 1.0) {
      insights.add(
        '⚠️ Sobrecarga detectada: Tienes ${metrics.tiempoFormateado} de trabajo '
        'estimado. Considera redistribuir tareas.',
      );
    } else if (metrics.cargaDelDia > 0.75) {
      insights.add(
        '🔥 Día intenso: ${metrics.tiempoFormateado} de trabajo. '
        'Recuerda tomar descansos.',
      );
    } else if (metrics.cargaDelDia <= 0.3 && metrics.totalTareas > 0) {
      insights.add(
        '😊 Carga ligera hoy. Buen momento para tareas de largo plazo o aprendizaje.',
      );
    }

    // Insight sobre conflictos
    if (conflictos.isNotEmpty) {
      insights.add(
        '⏰ ${conflictos.length} conflicto(s) de horario detectado(s). '
        'Revisa tu agenda.',
      );
    }

    // Insight sobre racha
    if (metrics.rachaActual >= 5) {
      insights.add(
        '🔥 ¡${metrics.rachaActual} días de racha! Excelente consistencia.',
      );
    }

    // Insight sobre tareas bloqueadas
    final tareasConDependencias = tareas.where((t) => t.tieneDependenciasPendientes).length;
    if (tareasConDependencias > 0) {
      insights.add(
        '🔒 ${tareasConDependencias} tarea(s) bloqueada(s) por dependencias. '
        'Completa las previas primero.',
      );
    }

    // Insight sobre ayer
    if (metrics.tareasCompletadasAyer > 0) {
      final porcentaje = metrics.totalTareas > 0
          ? (metrics.tareasCompletadasAyer / metrics.totalTareas * 100).round()
          : 0;
      if (porcentaje >= 80) {
        insights.add(
          '✨ Ayer completaste ${metrics.tareasCompletadasAyer} tareas. ¡Gran trabajo!',
        );
      }
    }

    return insights;
  }

  /// Guarda la configuración del briefing en Firestore
  Future<void> guardarConfiguracion(String userId, BriefingConfig config) async {
    try {
      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('configuracion')
          .doc('briefing')
          .set(config.toJson());
    } catch (e) {
      debugPrint('Error guardando configuración de briefing: $e');
      rethrow;
    }
  }

  /// Obtiene la configuración del briefing desde Firestore
  Future<BriefingConfig> obtenerConfiguracion(String userId) async {
    try {
      final doc = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('configuracion')
          .doc('briefing')
          .get();

      if (doc.exists && doc.data() != null) {
        return BriefingConfig.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error obteniendo configuración de briefing: $e');
    }

    // Retornar configuración por defecto
    return BriefingConfig();
  }
}

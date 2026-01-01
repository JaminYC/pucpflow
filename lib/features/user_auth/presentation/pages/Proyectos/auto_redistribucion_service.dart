import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/redistribucion_tareas_service.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Login/google_calendar_service.dart';
import 'package:pucpflow/features/user_auth/tarea_service.dart';

/// Servicio para monitoreo y redistribución automática de tareas incompletas
class AutoRedistribucionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RedistribucionTareasService _redistribucionService = RedistribucionTareasService();
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  final TareaService _tareaService = TareaService();

  /// Verifica y redistribuye tareas que pasaron su fecha programada sin completarse
  Future<Map<String, dynamic>> verificarYRedistribuirTareasPendientes({
    required String proyectoId,
    required String userId,
  }) async {
    try {
      // Obtener el proyecto
      final proyectoDoc = await _firestore.collection("proyectos").doc(proyectoId).get();
      if (!proyectoDoc.exists) {
        return {
          'success': false,
          'error': 'Proyecto no encontrado',
        };
      }

      final proyecto = Proyecto.fromJson(proyectoDoc.data()!);
      final tareas = await _tareaService.obtenerTareasDelProyecto(proyectoId);

      // Filtrar tareas que están vencidas (fecha programada pasó y no están completas)
      final DateTime ahora = DateTime.now();
      final tareasVencidas = tareas.where((t) {
        if (t.completado) return false;

        // Verificar si la fecha programada ya pasó
        if (t.fechaProgramada != null && t.fechaProgramada!.isBefore(ahora)) {
          return true;
        }

        // O si la fecha límite ya pasó
        if (t.fechaLimite != null && t.fechaLimite!.isBefore(ahora)) {
          return true;
        }

        return false;
      }).toList();

      if (tareasVencidas.isEmpty) {
        return {
          'success': true,
          'tareasRedistribuidas': 0,
          'mensaje': 'No hay tareas vencidas para redistribuir',
        };
      }

      // Intentar conectar con Google Calendar
      final calendarApi = await _calendarService.signInAndGetCalendarApi(silentOnly: true);

      // Redistribuir las tareas vencidas
      final resultado = await _redistribucionService.redistribuirTareas(
        proyecto: proyecto,
        tareas: tareas,
        fechaInicioPersonalizada: DateTime.now(),
        fechaFinPersonalizada: proyecto.fechaFin,
        calendarApi: calendarApi,
        responsableUid: userId,
      );

      // Actualizar las tareas en Firestore
      await _actualizarTareasEnFirestore(proyectoId, resultado.tareasActualizadas);

      // Si tenemos Google Calendar, sincronizar los eventos actualizados
      if (calendarApi != null) {
        await _sincronizarConGoogleCalendar(
          calendarApi,
          resultado.tareasActualizadas,
          userId,
        );
      }

      return {
        'success': true,
        'tareasRedistribuidas': tareasVencidas.length,
        'tareasActualizadas': resultado.tareasActualizadas.length,
        'estadisticas': resultado.estadisticas,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al redistribuir tareas: $e',
      };
    }
  }

  /// Redistribuye TODAS las tareas pendientes de un proyecto (manual)
  Future<Map<String, dynamic>> redistribuirTodasLasTareasPendientes({
    required String proyectoId,
    required String userId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      // Obtener el proyecto
      final proyectoDoc = await _firestore.collection("proyectos").doc(proyectoId).get();
      if (!proyectoDoc.exists) {
        return {
          'success': false,
          'error': 'Proyecto no encontrado',
        };
      }

      final proyecto = Proyecto.fromJson(proyectoDoc.data()!);
      final tareas = await _tareaService.obtenerTareasDelProyecto(proyectoId);

      // Intentar conectar con Google Calendar
      final calendarApi = await _calendarService.signInAndGetCalendarApi(silentOnly: true);

      // Redistribuir TODAS las tareas pendientes
      final resultado = await _redistribucionService.redistribuirTareas(
        proyecto: proyecto,
        tareas: tareas,
        fechaInicioPersonalizada: fechaInicio ?? DateTime.now(),
        fechaFinPersonalizada: fechaFin ?? proyecto.fechaFin,
        calendarApi: calendarApi,
        responsableUid: userId,
      );

      // Actualizar las tareas en Firestore
      await _actualizarTareasEnFirestore(proyectoId, resultado.tareasActualizadas);

      // Si tenemos Google Calendar, sincronizar los eventos actualizados
      if (calendarApi != null) {
        await _sincronizarConGoogleCalendar(
          calendarApi,
          resultado.tareasActualizadas,
          userId,
        );
      }

      return {
        'success': true,
        'tareasRedistribuidas': resultado.tareasRedistribuidas,
        'tareasCompletadas': resultado.tareasCompletadas,
        'tareasPendientes': resultado.tareasPendientes,
        'estadisticas': resultado.estadisticas,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al redistribuir tareas: $e',
      };
    }
  }

  /// Actualiza las tareas en Firestore
  Future<void> _actualizarTareasEnFirestore(
    String proyectoId,
    List<Tarea> tareasActualizadas,
  ) async {
    final tareasJson = tareasActualizadas.map((t) => t.toJson()).toList();
    await _firestore.collection("proyectos").doc(proyectoId).update({
      "tareas": tareasJson,
    });
  }

  /// Sincroniza las tareas con Google Calendar
  Future<void> _sincronizarConGoogleCalendar(
    dynamic calendarApi,
    List<Tarea> tareas,
    String userId,
  ) async {
    for (var tarea in tareas) {
      if (tarea.completado) continue; // No sincronizar tareas completadas

      try {
        if (tarea.googleCalendarEventId != null) {
          // Actualizar evento existente
          await _calendarService.actualizarEventoEnCalendario(
            calendarApi,
            tarea.googleCalendarEventId!,
            tarea,
            userId,
          );
        } else if (tarea.fechaProgramada != null || tarea.fechaLimite != null) {
          // Crear nuevo evento
          final eventId = await _calendarService.agendarEventoEnCalendario(
            calendarApi,
            tarea,
            userId,
          );

          if (eventId != null) {
            tarea.googleCalendarEventId = eventId;
          }
        }
      } catch (e) {
        print("⚠️ Error al sincronizar tarea '${tarea.titulo}' con Google Calendar: $e");
        // Continuar con la siguiente tarea
      }
    }
  }

  /// Obtiene estadísticas de tareas vencidas para un usuario
  Future<Map<String, dynamic>> obtenerEstadisticasTareasVencidas(String userId) async {
    try {
      final proyectosSnapshot = await _firestore.collection("proyectos").get();

      int totalTareasVencidas = 0;
      int totalTareasPendientes = 0;
      List<Map<String, dynamic>> tareasVencidasDetalle = [];

      for (var proyectoDoc in proyectosSnapshot.docs) {
        final proyecto = Proyecto.fromJson(proyectoDoc.data());
        final tareas = await _tareaService.obtenerTareasDelProyecto(proyectoDoc.id);

        for (var tarea in tareas) {
          // Solo considerar tareas del usuario
          if (!tarea.responsables.contains(userId)) continue;

          if (!tarea.completado) {
            totalTareasPendientes++;

            final DateTime ahora = DateTime.now();
            bool vencida = false;

            if (tarea.fechaProgramada != null && tarea.fechaProgramada!.isBefore(ahora)) {
              vencida = true;
            } else if (tarea.fechaLimite != null && tarea.fechaLimite!.isBefore(ahora)) {
              vencida = true;
            }

            if (vencida) {
              totalTareasVencidas++;
              tareasVencidasDetalle.add({
                'titulo': tarea.titulo,
                'proyecto': proyecto.nombre,
                'fechaProgramada': tarea.fechaProgramada?.toIso8601String(),
                'fechaLimite': tarea.fechaLimite?.toIso8601String(),
                'prioridad': tarea.prioridad,
              });
            }
          }
        }
      }

      return {
        'totalTareasVencidas': totalTareasVencidas,
        'totalTareasPendientes': totalTareasPendientes,
        'tareasVencidasDetalle': tareasVencidasDetalle,
        'porcentajeVencidas': totalTareasPendientes > 0
            ? ((totalTareasVencidas / totalTareasPendientes) * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      return {
        'error': 'Error al obtener estadísticas: $e',
      };
    }
  }
}

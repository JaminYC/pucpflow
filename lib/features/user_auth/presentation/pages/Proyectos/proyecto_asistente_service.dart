import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';

/// Servicio para asistente conversacional de proyectos
/// Prepara contexto completo y maneja comunicación con IA
class ProyectoAsistenteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Obtener contexto completo de un proyecto específico
  Future<Map<String, dynamic>> obtenerContextoProyecto(String proyectoId) async {
    try {
      print('📊 [Asistente] Obteniendo contexto del proyecto $proyectoId');

      // 1. Obtener información del proyecto
      final proyectoDoc = await _firestore.collection('proyectos').doc(proyectoId).get();
      if (!proyectoDoc.exists) {
        throw Exception('Proyecto no encontrado');
      }

      final proyecto = Proyecto.fromFirestore(proyectoDoc);
      print('✅ [Asistente] Proyecto obtenido: ${proyecto.nombre}');

      // 2. Obtener todas las tareas del proyecto
      // Intentar primero de la subcolección (tareas nuevas)
      final tareasSnapshot = await _firestore
          .collection('proyectos')
          .doc(proyectoId)
          .collection('tareas')
          .get();

      print('📋 [Asistente] Documentos en subcolección: ${tareasSnapshot.docs.length}');

      final tareas = <Tarea>[];

      // Si no hay tareas en la subcolección, buscar en el campo del documento
      if (tareasSnapshot.docs.isEmpty) {
        print('📋 [Asistente] Buscando tareas en campo del documento...');
        final tareasArray = proyectoDoc.data()?['tareas'] as List?;
        if (tareasArray != null && tareasArray.isNotEmpty) {
          print('📋 [Asistente] Tareas encontradas en campo: ${tareasArray.length}');
          for (var tareaData in tareasArray) {
            try {
              final data = Map<String, dynamic>.from(tareaData as Map);
              print('📄 [Asistente] Procesando tarea: ${data['titulo'] ?? 'sin título'}');
              final tarea = Tarea.fromJson(data);
              tareas.add(tarea);
            } catch (e) {
              print('⚠️ [Asistente] Error procesando tarea: $e');
            }
          }
        }
      } else {
        // Procesar tareas de la subcolección
        for (var doc in tareasSnapshot.docs) {
          try {
            final data = doc.data();
            print('📄 [Asistente] Procesando tarea: ${data['titulo'] ?? 'sin título'}');
            final tarea = Tarea.fromJson(data);
            tareas.add(tarea);
          } catch (e) {
            print('⚠️ [Asistente] Error procesando tarea ${doc.id}: $e');
          }
        }
      }
      print('✅ [Asistente] Tareas procesadas exitosamente: ${tareas.length}');

      // 3. Obtener información de participantes
      final participantes = await _obtenerParticipantes(proyectoId);
      print('✅ [Asistente] Participantes obtenidos: ${participantes.length}');

      // 4. Calcular estadísticas
      final stats = _calcularEstadisticas(tareas, participantes);
      print('✅ [Asistente] Estadísticas calculadas: ${stats['progresoPercent']}% progreso');

      // 5. Detectar problemas
      final problemas = _detectarProblemas(tareas, proyecto);
      print('✅ [Asistente] Problemas detectados: ${problemas.length}');

      // 6. Preparar contexto textual
      final contextoTexto = _generarContextoTexto(proyecto, tareas, participantes, stats, problemas);
      print('✅ [Asistente] Contexto generado: ${contextoTexto.length} caracteres');
      print('📄 [Asistente] Primeros 500 caracteres del contexto:\n${contextoTexto.substring(0, contextoTexto.length > 500 ? 500 : contextoTexto.length)}');

      return {
        'proyecto': proyecto,
        'tareas': tareas,
        'participantes': participantes,
        'estadisticas': stats,
        'problemas': problemas,
        'contextoTexto': contextoTexto,
      };
    } catch (e, stackTrace) {
      print('❌ [Asistente] Error obteniendo contexto: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Obtener información de participantes
  Future<List<Map<String, dynamic>>> _obtenerParticipantes(String proyectoId) async {
    try {
      final proyectoDoc = await _firestore.collection('proyectos').doc(proyectoId).get();
      final participantesIds = List<String>.from(proyectoDoc.data()?['participantes'] ?? []);

      List<Map<String, dynamic>> participantes = [];

      for (String userId in participantesIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          participantes.add({
            'uid': userId,
            'nombre': userDoc.data()?['nombre'] ?? 'Usuario',
            'email': userDoc.data()?['email'] ?? '',
            'habilidades': userDoc.data()?['habilidades'] ?? [],
          });
        }
      }

      return participantes;
    } catch (e) {
      print('⚠️ Error obteniendo participantes: $e');
      return [];
    }
  }

  /// Calcular estadísticas del proyecto
  Map<String, dynamic> _calcularEstadisticas(List<Tarea> tareas, List<Map<String, dynamic>> participantes) {
    final totalTareas = tareas.length;
    final completadas = tareas.where((t) => t.completado).length;
    final pendientes = tareas.where((t) => !t.completado).length;
    final enProgreso = tareas.where((t) => !t.completado && t.responsables.isNotEmpty).length;

    // Tareas por prioridad
    final prioridad1 = tareas.where((t) => t.prioridad == 1 && !t.completado).length;
    final prioridad2 = tareas.where((t) => t.prioridad == 2 && !t.completado).length;
    final prioridad3 = tareas.where((t) => t.prioridad == 3 && !t.completado).length;

    // Tareas por responsable
    Map<String, int> tareasPorResponsable = {};
    for (var tarea in tareas.where((t) => !t.completado)) {
      for (var responsableId in tarea.responsables) {
        tareasPorResponsable[responsableId] = (tareasPorResponsable[responsableId] ?? 0) + 1;
      }
    }

    // Tareas atrasadas
    final ahora = DateTime.now();
    final atrasadas = tareas.where((t) {
      if (t.completado) return false;
      if (t.fechaLimite == null) return false;
      return t.fechaLimite!.isBefore(ahora);
    }).length;

    // Duración total estimada
    final duracionTotal = tareas.fold<int>(0, (sum, t) => sum + t.duracion);
    final duracionPendiente = tareas.where((t) => !t.completado).fold<int>(0, (sum, t) => sum + t.duracion);

    // Progreso porcentual
    final progresoPercent = totalTareas > 0 ? (completadas / totalTareas * 100).toStringAsFixed(1) : '0';

    return {
      'totalTareas': totalTareas,
      'completadas': completadas,
      'pendientes': pendientes,
      'enProgreso': enProgreso,
      'atrasadas': atrasadas,
      'prioridad1': prioridad1,
      'prioridad2': prioridad2,
      'prioridad3': prioridad3,
      'tareasPorResponsable': tareasPorResponsable,
      'duracionTotal': duracionTotal,
      'duracionPendiente': duracionPendiente,
      'progresoPercent': progresoPercent,
    };
  }

  /// Detectar problemas en el proyecto
  List<String> _detectarProblemas(List<Tarea> tareas, Proyecto proyecto) {
    List<String> problemas = [];

    // 1. Tareas sin responsable
    final sinResponsable = tareas.where((t) => !t.completado && t.responsables.isEmpty).length;
    if (sinResponsable > 0) {
      problemas.add('⚠️ $sinResponsable tarea(s) sin responsable asignado');
    }

    // 2. Tareas atrasadas
    final ahora = DateTime.now();
    final atrasadas = tareas.where((t) {
      if (t.completado) return false;
      if (t.fechaLimite == null) return false;
      return t.fechaLimite!.isBefore(ahora);
    }).toList();

    if (atrasadas.isNotEmpty) {
      problemas.add('🚨 ${atrasadas.length} tarea(s) atrasada(s)');
    }

    // 3. Tareas de alta prioridad pendientes
    final altaPrioridadPendiente = tareas.where((t) => !t.completado && t.prioridad == 1).length;
    if (altaPrioridadPendiente > 0) {
      problemas.add('🔴 $altaPrioridadPendiente tarea(s) de alta prioridad pendiente(s)');
    }

    // 4. Sobrecarga de responsables
    Map<String, int> cargaPorResponsable = {};
    for (var tarea in tareas.where((t) => !t.completado)) {
      for (var responsableId in tarea.responsables) {
        cargaPorResponsable[responsableId] = (cargaPorResponsable[responsableId] ?? 0) + tarea.duracion;
      }
    }

    cargaPorResponsable.forEach((responsableId, minutos) {
      if (minutos > 2400) { // Más de 40 horas (5 días de 8h)
        problemas.add('⚠️ Responsable sobrecargado: ${(minutos / 60).toStringAsFixed(1)} horas pendientes');
      }
    });

    // 5. Proyecto sin fecha límite
    if (proyecto.fechaFin == null) {
      problemas.add('📅 Proyecto sin fecha límite definida');
    }

    return problemas;
  }

  /// Generar contexto textual para el asistente
  String _generarContextoTexto(
    Proyecto proyecto,
    List<Tarea> tareas,
    List<Map<String, dynamic>> participantes,
    Map<String, dynamic> stats,
    List<String> problemas,
  ) {
    final buffer = StringBuffer();

    // Información del proyecto
    buffer.writeln('=== INFORMACIÓN DEL PROYECTO ===');
    buffer.writeln('Nombre: ${proyecto.nombre}');
    buffer.writeln('Descripción: ${proyecto.descripcion}');
    buffer.writeln('Categoría: ${proyecto.categoria ?? "No especificada"}');
    if (proyecto.fechaInicio != null) {
      buffer.writeln('Fecha Inicio: ${proyecto.fechaInicio}');
    }
    if (proyecto.fechaFin != null) {
      buffer.writeln('Fecha Fin: ${proyecto.fechaFin}');
    }
    if (proyecto.objetivo != null) {
      buffer.writeln('Objetivo: ${proyecto.objetivo}');
    }
    buffer.writeln('');

    // Estadísticas
    buffer.writeln('=== ESTADÍSTICAS ===');
    buffer.writeln('Progreso: ${stats['progresoPercent']}%');
    buffer.writeln('Total de tareas: ${stats['totalTareas']}');
    buffer.writeln('Completadas: ${stats['completadas']}');
    buffer.writeln('Pendientes: ${stats['pendientes']}');
    buffer.writeln('Atrasadas: ${stats['atrasadas']}');
    buffer.writeln('Alta prioridad: ${stats['prioridad1']}');
    buffer.writeln('Media prioridad: ${stats['prioridad2']}');
    buffer.writeln('Baja prioridad: ${stats['prioridad3']}');
    buffer.writeln('Duración total estimada: ${(stats['duracionTotal'] / 60).toStringAsFixed(1)} horas');
    buffer.writeln('Duración pendiente: ${(stats['duracionPendiente'] / 60).toStringAsFixed(1)} horas');
    buffer.writeln('');

    // Participantes
    buffer.writeln('=== PARTICIPANTES (${participantes.length}) ===');
    for (var participante in participantes) {
      final tareas = stats['tareasPorResponsable'][participante['uid']] ?? 0;
      buffer.writeln('- ${participante['nombre']}: $tareas tarea(s) pendiente(s)');
    }
    buffer.writeln('');

    // Problemas detectados
    if (problemas.isNotEmpty) {
      buffer.writeln('=== PROBLEMAS DETECTADOS ===');
      for (var problema in problemas) {
        buffer.writeln(problema);
      }
      buffer.writeln('');
    }

    // Listado de tareas pendientes
    final tareasPendientes = tareas.where((t) => !t.completado).toList();
    if (tareasPendientes.isNotEmpty) {
      buffer.writeln('=== TAREAS PENDIENTES (${tareasPendientes.length}) ===');
      for (var tarea in tareasPendientes.take(20)) { // Máximo 20 tareas para no saturar
        buffer.writeln('- ${tarea.titulo}');
        buffer.writeln('  Prioridad: ${tarea.prioridad}, Duración: ${tarea.duracion}min');
        if (tarea.responsables.isNotEmpty) {
          final nombres = tarea.responsables.map((id) {
            final p = participantes.firstWhere((p) => p['uid'] == id, orElse: () => {'nombre': 'Desconocido'});
            return p['nombre'];
          }).join(', ');
          buffer.writeln('  Responsables: $nombres');
        }
        if (tarea.fechaLimite != null) {
          buffer.writeln('  Fecha límite: ${tarea.fechaLimite}');
        }
        buffer.writeln('');
      }
    }

    return buffer.toString();
  }

  /// Consultar al asistente con contexto del proyecto
  Future<String> consultarAsistente(String pregunta, String contexto) async {
    try {
      print('🤖 [Asistente] Enviando consulta a IA...');

      final callable = _functions.httpsCallable('adanProyectoConsulta');
      final result = await callable.call({
        'pregunta': pregunta,
        'contexto': contexto,
      });

      final respuesta = result.data['respuesta'] as String? ?? 'Lo siento, no pude procesar tu pregunta.';
      print('✅ [Asistente] Respuesta recibida');

      return respuesta;
    } catch (e) {
      print('❌ [Asistente] Error consultando IA: $e');
      throw Exception('Error consultando al asistente: $e');
    }
  }
}

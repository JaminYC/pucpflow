import 'package:cloud_firestore/cloud_firestore.dart';
import 'tarea_model.dart';

/// Servicio para asignación inteligente de tareas basada en habilidades
class AsignacionInteligenteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sugiere los mejores usuarios para una tarea basándose en sus habilidades
  ///
  /// Retorna una lista de Map con:
  /// - uid: ID del usuario
  /// - nombre: Nombre del usuario
  /// - matchScore: Puntuación de compatibilidad (0-100)
  /// - habilidadesCoincidentes: Lista de habilidades que coinciden
  /// - nivelPromedio: Nivel promedio en las habilidades requeridas
  Future<List<Map<String, dynamic>>> sugerirAsignaciones({
    required Tarea tarea,
    required List<String> participantesIds,
  }) async {
    if (tarea.habilidadesRequeridas.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> sugerencias = [];

    for (String uid in participantesIds) {
      try {
        final userDoc = await _firestore.collection('users').doc(uid).get();

        if (!userDoc.exists) continue;

        final userData = userDoc.data()!;
        final nombre = userData['nombre'] ?? 'Usuario';
        final habilidadesUsuario = Map<String, int>.from(userData['habilidades'] ?? {});

        // Calcular compatibilidad
        final resultado = _calcularCompatibilidad(
          habilidadesRequeridas: tarea.habilidadesRequeridas,
          habilidadesUsuario: habilidadesUsuario,
        );

        if (resultado['matchScore'] > 0) {
          sugerencias.add({
            'uid': uid,
            'nombre': nombre,
            'matchScore': resultado['matchScore'],
            'habilidadesCoincidentes': resultado['habilidadesCoincidentes'],
            'nivelPromedio': resultado['nivelPromedio'],
            'totalHabilidadesRequeridas': tarea.habilidadesRequeridas.length,
          });
        }
      } catch (e) {
        print('Error obteniendo usuario $uid: $e');
      }
    }

    // Ordenar por matchScore descendente
    sugerencias.sort((a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int));

    return sugerencias;
  }

  /// Calcula la compatibilidad entre habilidades requeridas y habilidades del usuario
  Map<String, dynamic> _calcularCompatibilidad({
    required List<String> habilidadesRequeridas,
    required Map<String, int> habilidadesUsuario,
  }) {
    List<String> habilidadesCoincidentes = [];
    int sumaNiveles = 0;
    int coincidencias = 0;

    for (String habilidadRequerida in habilidadesRequeridas) {
      // Buscar coincidencia exacta o parcial (case-insensitive)
      final habilidadKey = habilidadesUsuario.keys.firstWhere(
        (key) => _similitudHabilidades(key, habilidadRequerida) >= 0.8,
        orElse: () => '',
      );

      if (habilidadKey.isNotEmpty) {
        final nivel = habilidadesUsuario[habilidadKey]!;
        habilidadesCoincidentes.add(habilidadKey);
        sumaNiveles += nivel;
        coincidencias++;
      }
    }

    // Calcular métricas
    final nivelPromedio = coincidencias > 0 ? sumaNiveles / coincidencias : 0.0;
    final porcentajeCoincidencia = (coincidencias / habilidadesRequeridas.length) * 100;

    // Score final: combinación de % coincidencia y nivel promedio
    // Fórmula: (% coincidencia * 0.7) + (nivel promedio * 20 * 0.3)
    // Esto da mayor peso a tener las habilidades que al nivel
    final matchScore = (porcentajeCoincidencia * 0.7 + (nivelPromedio / 5 * 100) * 0.3).round();

    return {
      'matchScore': matchScore,
      'habilidadesCoincidentes': habilidadesCoincidentes,
      'nivelPromedio': nivelPromedio,
      'coincidencias': coincidencias,
    };
  }

  /// Calcula similitud entre dos strings de habilidades
  /// Retorna un valor entre 0 y 1
  double _similitudHabilidades(String hab1, String hab2) {
    final h1 = hab1.toLowerCase().trim();
    final h2 = hab2.toLowerCase().trim();

    // Coincidencia exacta
    if (h1 == h2) return 1.0;

    // Uno contiene al otro
    if (h1.contains(h2) || h2.contains(h1)) {
      return 0.9;
    }

    // Similitud de Jaccard (palabras en común)
    final palabras1 = h1.split(' ').toSet();
    final palabras2 = h2.split(' ').toSet();
    final interseccion = palabras1.intersection(palabras2).length;
    final union = palabras1.union(palabras2).length;

    return union > 0 ? interseccion / union : 0.0;
  }

  /// Asigna automáticamente una tarea al mejor candidato
  Future<Map<String, dynamic>?> asignarAutomaticamente({
    required String proyectoId,
    required Tarea tarea,
    required List<String> participantesIds,
    required List<Tarea> todasLasTareas,
  }) async {
    final sugerencias = await sugerirAsignaciones(
      tarea: tarea,
      participantesIds: participantesIds,
    );

    if (sugerencias.isEmpty) {
      return null;
    }

    // Tomar el mejor candidato
    final mejorCandidato = sugerencias.first;

    // Asignar la tarea
    final tareaActualizada = Tarea(
      titulo: tarea.titulo,
      fecha: tarea.fecha,
      duracion: tarea.duracion,
      prioridad: tarea.prioridad,
      completado: tarea.completado,
      colorId: tarea.colorId,
      responsables: [mejorCandidato['uid']],
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

    // Actualizar en Firestore
    final tareasActualizadas = todasLasTareas.map((t) {
      if (t.titulo == tarea.titulo) {
        return tareaActualizada;
      }
      return t;
    }).toList();

    await _firestore.collection('proyectos').doc(proyectoId).update({
      'tareas': tareasActualizadas.map((t) => t.toJson()).toList(),
    });

    return mejorCandidato;
  }

  /// Asigna automáticamente todas las tareas sin asignar del proyecto
  /// Asigna TODOS los candidatos con score >= umbralMinimo (por defecto 60)
  /// SIEMPRE incluye al propietario del proyecto
  Future<Map<String, dynamic>> asignarTodasAutomaticamente({
    required String proyectoId,
    required List<Tarea> tareas,
    required List<String> participantesIds,
    String? propietarioId, // ✅ UID del creador del proyecto
    int umbralMinimo = 60, // Score mínimo para ser asignado
  }) async {
    int asignadas = 0;
    int sinCandidatos = 0;
    List<Map<String, dynamic>> resultados = [];

    List<Tarea> tareasActualizadas = List.from(tareas);

    // Carga acumulada por participante (en minutos) para balanceo
    final cargaPorUid = <String, int>{
      for (final uid in participantesIds) uid: 0,
    };

    // Pre-cargar carga actual desde tareas existentes
    for (final t in tareas) {
      if (t.completado) continue;
      for (final uid in t.responsables) {
        cargaPorUid[uid] = (cargaPorUid[uid] ?? 0) + t.duracion;
      }
    }

    for (int i = 0; i < tareasActualizadas.length; i++) {
      final tarea = tareasActualizadas[i];

      // Solo asignar tareas sin responsables
      if (tarea.responsables.isNotEmpty) continue;

      List<String> uidsAsignados = [];

      if (tarea.habilidadesRequeridas.isNotEmpty) {
        // --- Con habilidades: usar scoring de compatibilidad ---
        final sugerencias = await sugerirAsignaciones(
          tarea: tarea,
          participantesIds: participantesIds,
        );

        final candidatosValidos = sugerencias
            .where((s) => (s['matchScore'] as int) >= umbralMinimo)
            .toList();

        uidsAsignados = candidatosValidos.map((c) => c['uid'] as String).toList();

        if (propietarioId != null && !uidsAsignados.contains(propietarioId)) {
          uidsAsignados.insert(0, propietarioId);
        }
      } else {
        // --- Sin habilidades: asignar al participante con menor carga ---
        if (participantesIds.isEmpty) {
          sinCandidatos++;
          continue;
        }

        final uidMenorCarga = participantesIds.reduce((a, b) =>
            (cargaPorUid[a] ?? 0) <= (cargaPorUid[b] ?? 0) ? a : b);
        uidsAsignados = [uidMenorCarga];
      }

      if (uidsAsignados.isEmpty) {
        sinCandidatos++;
        continue;
      }

      // Actualizar carga acumulada del asignado principal
      cargaPorUid[uidsAsignados.first] =
          (cargaPorUid[uidsAsignados.first] ?? 0) + tarea.duracion;

      final tareaActualizada = Tarea(
        titulo: tarea.titulo,
        fecha: tarea.fecha,
        duracion: tarea.duracion,
        prioridad: tarea.prioridad,
        completado: tarea.completado,
        colorId: tarea.colorId,
        responsables: uidsAsignados,
        tipoTarea: 'Asignada',
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

      tareasActualizadas[i] = tareaActualizada;
      asignadas++;

      resultados.add({
        'tarea': tarea.titulo,
        'asignado': uidsAsignados.join(', '),
        'matchScore': tarea.habilidadesRequeridas.isNotEmpty ? umbralMinimo : 100,
        'totalAsignados': uidsAsignados.length,
      });
    }

    // Guardar en la SUBCOLECCIÓN real (fuente de verdad)
    if (asignadas > 0) {
      final batch = _firestore.batch();
      for (final tarea in tareasActualizadas) {
        // Buscar el doc existente en la subcolección por título
        final query = await _firestore
            .collection('proyectos')
            .doc(proyectoId)
            .collection('tareas')
            .where('titulo', isEqualTo: tarea.titulo)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          batch.update(query.docs.first.reference, {
            'responsables': tarea.responsables,
            'tipoTarea': tarea.tipoTarea,
          });
        }
      }
      await batch.commit();
    }

    return {
      'asignadas': asignadas,
      'sinCandidatos': sinCandidatos,
      'resultados': resultados,
    };
  }

  /// Obtiene estadísticas de compatibilidad de un usuario con las tareas del proyecto
  Future<Map<String, dynamic>> obtenerEstadisticasUsuario({
    required String uid,
    required List<Tarea> tareas,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        return {'error': 'Usuario no encontrado'};
      }

      final habilidadesUsuario = Map<String, int>.from(userDoc.data()!['habilidades'] ?? {});

      int tareasCompatibles = 0;
      int tareasAsignadas = 0;
      List<int> scores = [];

      for (var tarea in tareas) {
        if (tarea.responsables.contains(uid)) {
          tareasAsignadas++;
        }

        if (tarea.habilidadesRequeridas.isNotEmpty) {
          final resultado = _calcularCompatibilidad(
            habilidadesRequeridas: tarea.habilidadesRequeridas,
            habilidadesUsuario: habilidadesUsuario,
          );

          if (resultado['matchScore'] > 50) {
            tareasCompatibles++;
            scores.add(resultado['matchScore']);
          }
        }
      }

      final scorePromedio = scores.isNotEmpty
          ? scores.reduce((a, b) => a + b) / scores.length
          : 0.0;

      return {
        'tareasAsignadas': tareasAsignadas,
        'tareasCompatibles': tareasCompatibles,
        'scorePromedio': scorePromedio.round(),
        'totalHabilidades': habilidadesUsuario.length,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script de migración para corregir áreas duplicadas en proyectos existentes
///
/// PROBLEMA: Los proyectos personales tienen múltiples tareas con el mismo nombre
/// de área (ej: "Explorador Principiante"), causando errores en DropdownButton
///
/// SOLUCIÓN: Agrupar tareas por fase y asignar áreas únicas como "Fase 1", "Fase 2", etc.
class FixDuplicateAreas {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrar todos los proyectos del usuario actual
  Future<Map<String, dynamic>> fixAllUserProjects() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'error': 'Usuario no autenticado'};
    }

    try {
      print('🔧 Iniciando migración de proyectos...');

      // Obtener todos los proyectos del usuario
      final proyectosSnapshot = await _firestore
          .collection('proyectos')
          .where('participantes', arrayContains: user.uid)
          .get();

      int proyectosCorregidos = 0;
      int tareasCorregidas = 0;
      final List<String> proyectosConErrores = [];

      for (var proyectoDoc in proyectosSnapshot.docs) {
        try {
          final result = await _fixProyecto(proyectoDoc.id, proyectoDoc.data());
          if (result['fixed'] == true) {
            proyectosCorregidos++;
            tareasCorregidas += (result['tareasCorregidas'] as int? ?? 0);
          }
        } catch (e) {
          print('❌ Error corrigiendo proyecto ${proyectoDoc.id}: $e');
          proyectosConErrores.add(proyectoDoc.id);
        }
      }

      print('✅ Migración completada:');
      print('   📁 Proyectos corregidos: $proyectosCorregidos');
      print('   📝 Tareas corregidas: $tareasCorregidas');
      if (proyectosConErrores.isNotEmpty) {
        print('   ⚠️ Proyectos con errores: ${proyectosConErrores.length}');
      }

      return {
        'success': true,
        'proyectosCorregidos': proyectosCorregidos,
        'tareasCorregidas': tareasCorregidas,
        'proyectosConErrores': proyectosConErrores,
      };
    } catch (e) {
      print('❌ Error en migración: $e');
      return {
        'error': 'Error en migración',
        'message': e.toString(),
      };
    }
  }

  /// Corregir un proyecto específico
  Future<Map<String, dynamic>> _fixProyecto(String proyectoId, Map<String, dynamic> proyectoData) async {
    print('🔍 Analizando proyecto: $proyectoId');

    // Obtener todas las tareas del proyecto
    final tareasSnapshot = await _firestore
        .collection('proyectos')
        .doc(proyectoId)
        .collection('tareas')
        .get();

    if (tareasSnapshot.docs.isEmpty) {
      print('   ⚠️ Proyecto sin tareas, saltando...');
      return {'fixed': false};
    }

    // Agrupar tareas por área actual y detectar duplicados
    final Map<String, List<DocumentSnapshot>> tareasPorArea = {};
    for (var tareaDoc in tareasSnapshot.docs) {
      final area = tareaDoc.data()?['area'] as String? ?? 'General';
      tareasPorArea.putIfAbsent(area, () => []);
      tareasPorArea[area]!.add(tareaDoc);
    }

    // Verificar si hay áreas con múltiples tareas (potencial duplicado)
    final areasDuplicadas = tareasPorArea.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => entry.key)
        .toList();

    if (areasDuplicadas.isEmpty) {
      print('   ✓ Proyecto sin duplicados, saltando...');
      return {'fixed': false};
    }

    print('   ⚠️ Encontradas ${areasDuplicadas.length} áreas con múltiples tareas:');
    for (var area in areasDuplicadas) {
      print('      - "$area": ${tareasPorArea[area]!.length} tareas');
    }

    // Estrategia de corrección: Agrupar por fasePMI o tipoTarea
    int tareasCorregidas = 0;
    final Map<String, int> faseCounter = {};

    for (var tareaDoc in tareasSnapshot.docs) {
      final tareaData = tareaDoc.data()!;
      final areaActual = tareaData['area'] as String? ?? 'General';

      // Solo corregir si el área tiene duplicados
      if (!areasDuplicadas.contains(areaActual)) {
        continue;
      }

      // Intentar usar fasePMI o tipoTarea para determinar la fase
      final fasePMI = tareaData['fasePMI'] as String?;
      final tipoTarea = tareaData['tipoTarea'] as String?;
      final faseKey = fasePMI ?? tipoTarea ?? 'General';

      // Asignar número de fase
      if (!faseCounter.containsKey(faseKey)) {
        faseCounter[faseKey] = faseCounter.length + 1;
      }

      final nuevaArea = 'Fase ${faseCounter[faseKey]}';

      // Actualizar la tarea
      await tareaDoc.reference.update({
        'area': nuevaArea,
      });

      tareasCorregidas++;
    }

    print('   ✅ Corregidas $tareasCorregidas tareas');

    return {
      'fixed': true,
      'tareasCorregidas': tareasCorregidas,
    };
  }

  /// Migrar un proyecto específico por ID
  Future<Map<String, dynamic>> fixProyectoById(String proyectoId) async {
    try {
      final proyectoDoc = await _firestore.collection('proyectos').doc(proyectoId).get();

      if (!proyectoDoc.exists) {
        return {'error': 'Proyecto no encontrado'};
      }

      final result = await _fixProyecto(proyectoId, proyectoDoc.data()!);

      return {
        'success': true,
        'fixed': result['fixed'],
        'tareasCorregidas': result['tareasCorregidas'] ?? 0,
      };
    } catch (e) {
      return {
        'error': 'Error corrigiendo proyecto',
        'message': e.toString(),
      };
    }
  }
}

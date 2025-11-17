import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pmi_fase_model.dart';
import 'pmi_documento_model.dart';
import 'proyecto_model.dart';

/// Servicio para gestión de proyectos con metodología PMI
class PMIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========================================
  // 🚀 INICIALIZAR PROYECTO PMI
  // ========================================

  /// Convierte un proyecto existente en proyecto PMI
  /// Crea las 5 fases PMI por defecto
  Future<bool> convertirAProyectoPMI(String proyectoId) async {
    try {
      final batch = _firestore.batch();

      // 1. Actualizar proyecto para marcarlo como PMI
      final proyectoRef = _firestore.collection('proyectos').doc(proyectoId);
      batch.update(proyectoRef, {
        'esPMI': true,
        'fasePMIActual': 'Iniciación',
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      // 2. Crear las 5 fases PMI predefinidas
      final fasesDefault = PMIFase.getFasesDefault();
      for (var fase in fasesDefault) {
        final faseRef = proyectoRef.collection('fases_pmi').doc(fase.id);
        batch.set(faseRef, fase.toJson());
      }

      await batch.commit();
      print('✅ Proyecto convertido a PMI con ${fasesDefault.length} fases');
      return true;
    } catch (e) {
      print('❌ Error convirtiendo proyecto a PMI: $e');
      return false;
    }
  }

  /// Crea un nuevo proyecto PMI desde cero
  Future<String?> crearProyectoPMI({
    required String nombre,
    required String descripcion,
    required DateTime fechaInicio,
    DateTime? fechaFin,
    String? objetivo,
    String? alcance,
    double? presupuesto,
    List<String>? documentosIniciales,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // 1. Crear proyecto base
      final proyectoRef = _firestore.collection('proyectos').doc();

      final proyecto = Proyecto(
        id: proyectoRef.id,
        nombre: nombre,
        descripcion: descripcion,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        fechaCreacion: DateTime.now(),
        propietario: user.uid,
        participantes: [user.uid],
        esPMI: true,
        fasePMIActual: 'Iniciación',
        objetivo: objetivo,
        alcance: alcance,
        presupuesto: presupuesto,
        costoActual: 0.0,
        documentosIniciales: documentosIniciales,
      );

      await proyectoRef.set(proyecto.toJson());

      // 2. Crear las 5 fases PMI
      final fasesDefault = PMIFase.getFasesDefault();
      final batch = _firestore.batch();

      for (var fase in fasesDefault) {
        final faseRef = proyectoRef.collection('fases_pmi').doc(fase.id);
        batch.set(faseRef, fase.toJson());
      }

      await batch.commit();

      print('✅ Proyecto PMI creado: ${proyectoRef.id}');
      return proyectoRef.id;
    } catch (e) {
      print('❌ Error creando proyecto PMI: $e');
      return null;
    }
  }

  // ========================================
  // 📋 GESTIÓN DE FASES
  // ========================================

  /// Obtiene todas las fases de un proyecto PMI
  Future<List<PMIFase>> obtenerFases(String proyectoId) async {
    try {
      final snapshot = await _firestore
          .collection('proyectos')
          .doc(proyectoId)
          .collection('fases_pmi')
          .orderBy('orden')
          .get();

      return snapshot.docs.map((doc) => PMIFase.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error obteniendo fases: $e');
      return [];
    }
  }

  /// Stream de fases en tiempo real
  Stream<List<PMIFase>> watchFases(String proyectoId) {
    return _firestore
        .collection('proyectos')
        .doc(proyectoId)
        .collection('fases_pmi')
        .orderBy('orden')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PMIFase.fromFirestore(doc)).toList());
  }

  /// Actualiza una fase
  Future<bool> actualizarFase(
      String proyectoId, String faseId, Map<String, dynamic> datos) async {
    try {
      await _firestore
          .collection('proyectos')
          .doc(proyectoId)
          .collection('fases_pmi')
          .doc(faseId)
          .update(datos);

      return true;
    } catch (e) {
      print('❌ Error actualizando fase: $e');
      return false;
    }
  }

  /// Marca una fase como completada y avanza a la siguiente
  Future<bool> completarFase(String proyectoId, String faseId) async {
    try {
      final batch = _firestore.batch();

      // 1. Marcar fase actual como completada
      final faseRef = _firestore
          .collection('proyectos')
          .doc(proyectoId)
          .collection('fases_pmi')
          .doc(faseId);

      batch.update(faseRef, {
        'estado': 'completed',
        'fechaFin': FieldValue.serverTimestamp(),
      });

      // 2. Obtener siguiente fase
      final fases = await obtenerFases(proyectoId);
      final faseActual = fases.firstWhere((f) => f.id == faseId);
      final siguienteFase =
          fases.where((f) => f.orden == faseActual.orden + 1).firstOrNull;

      if (siguienteFase != null) {
        // 3. Marcar siguiente fase como en progreso
        final siguienteRef = _firestore
            .collection('proyectos')
            .doc(proyectoId)
            .collection('fases_pmi')
            .doc(siguienteFase.id);

        batch.update(siguienteRef, {
          'estado': 'in_progress',
          'fechaInicio': FieldValue.serverTimestamp(),
        });

        // 4. Actualizar proyecto
        batch.update(_firestore.collection('proyectos').doc(proyectoId), {
          'fasePMIActual': siguienteFase.nombre,
        });
      } else {
        // Si no hay siguiente fase, marcar proyecto como completado
        batch.update(_firestore.collection('proyectos').doc(proyectoId), {
          'estado': 'Finalizado',
          'fasePMIActual': 'Cierre',
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('❌ Error completando fase: $e');
      return false;
    }
  }

  /// Calcula el progreso de una fase basado en sus tareas
  Future<void> recalcularProgresoFase(String proyectoId, String faseId) async {
    try {
      final fase = await _firestore
          .collection('proyectos')
          .doc(proyectoId)
          .collection('fases_pmi')
          .doc(faseId)
          .get();

      if (!fase.exists) return;

      final faseData = PMIFase.fromFirestore(fase);
      final totalTareas = faseData.tareasIds.length;

      if (totalTareas == 0) {
        await actualizarFase(proyectoId, faseId, {
          'totalTareas': 0,
          'tareasCompletadas': 0,
          'progreso': 0.0,
        });
        return;
      }

      // TODO: Cuando migremos tareas a subcollection, contar las completadas
      // Por ahora, asumimos progreso manual

      final progreso = totalTareas > 0
          ? (faseData.tareasCompletadas / totalTareas)
          : 0.0;

      await actualizarFase(proyectoId, faseId, {
        'totalTareas': totalTareas,
        'progreso': progreso,
      });
    } catch (e) {
      print('❌ Error recalculando progreso: $e');
    }
  }

  // ========================================
  // 📄 GESTIÓN DE DOCUMENTOS PMI
  // ========================================

  /// Crea un nuevo documento PMI
  Future<String?> crearDocumento({
    required String proyectoId,
    required String nombre,
    required String tipo,
    required String faseId,
    String? descripcion,
    String? urlArchivo,
    String? contenido,
    List<String>? etiquetas,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final docRef = _firestore
          .collection('proyectos')
          .doc(proyectoId)
          .collection('documentos_pmi')
          .doc();

      final documento = PMIDocumento(
        id: docRef.id,
        nombre: nombre,
        tipo: tipo,
        descripcion: descripcion,
        urlArchivo: urlArchivo,
        contenido: contenido,
        faseId: faseId,
        creadoPor: user.uid,
        fechaCreacion: DateTime.now(),
        etiquetas: etiquetas ?? [],
      );

      await docRef.set(documento.toJson());

      // Agregar documento a la fase
      await _firestore
          .collection('proyectos')
          .doc(proyectoId)
          .collection('fases_pmi')
          .doc(faseId)
          .update({
        'documentosIds': FieldValue.arrayUnion([docRef.id])
      });

      print('✅ Documento creado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creando documento: $e');
      return null;
    }
  }

  /// Obtiene todos los documentos de un proyecto
  Future<List<PMIDocumento>> obtenerDocumentos(String proyectoId) async {
    try {
      final snapshot = await _firestore
          .collection('proyectos')
          .doc(proyectoId)
          .collection('documentos_pmi')
          .orderBy('fechaCreacion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PMIDocumento.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo documentos: $e');
      return [];
    }
  }

  /// Obtiene documentos de una fase específica
  Future<List<PMIDocumento>> obtenerDocumentosPorFase(
      String proyectoId, String faseId) async {
    try {
      final snapshot = await _firestore
          .collection('proyectos')
          .doc(proyectoId)
          .collection('documentos_pmi')
          .where('faseId', isEqualTo: faseId)
          .orderBy('fechaCreacion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PMIDocumento.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo documentos por fase: $e');
      return [];
    }
  }

  /// Stream de documentos en tiempo real
  Stream<List<PMIDocumento>> watchDocumentos(String proyectoId) {
    return _firestore
        .collection('proyectos')
        .doc(proyectoId)
        .collection('documentos_pmi')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PMIDocumento.fromFirestore(doc))
            .toList());
  }

  /// Actualiza un documento
  Future<bool> actualizarDocumento(
      String proyectoId, String docId, Map<String, dynamic> datos) async {
    try {
      await _firestore
          .collection('proyectos')
          .doc(proyectoId)
          .collection('documentos_pmi')
          .doc(docId)
          .update({
        ...datos,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('❌ Error actualizando documento: $e');
      return false;
    }
  }

  /// Elimina un documento
  Future<bool> eliminarDocumento(String proyectoId, String docId) async {
    try {
      // Obtener documento para saber su faseId
      final docSnap = await _firestore
          .collection('proyectos')
          .doc(proyectoId)
          .collection('documentos_pmi')
          .doc(docId)
          .get();

      if (docSnap.exists) {
        final doc = PMIDocumento.fromFirestore(docSnap);

        // Eliminar de la fase
        await _firestore
            .collection('proyectos')
            .doc(proyectoId)
            .collection('fases_pmi')
            .doc(doc.faseId)
            .update({
          'documentosIds': FieldValue.arrayRemove([docId])
        });
      }

      // Eliminar documento
      await _firestore
          .collection('proyectos')
          .doc(proyectoId)
          .collection('documentos_pmi')
          .doc(docId)
          .delete();

      return true;
    } catch (e) {
      print('❌ Error eliminando documento: $e');
      return false;
    }
  }

  // ========================================
  // 📊 ESTADÍSTICAS Y MÉTRICAS
  // ========================================

  /// Calcula el progreso general del proyecto PMI
  Future<double> calcularProgresoGeneral(String proyectoId) async {
    try {
      final fases = await obtenerFases(proyectoId);
      if (fases.isEmpty) return 0.0;

      final progresoTotal =
          fases.fold<double>(0.0, (sum, fase) => sum + fase.progreso);
      return progresoTotal / fases.length;
    } catch (e) {
      print('❌ Error calculando progreso: $e');
      return 0.0;
    }
  }

  /// Obtiene métricas del proyecto
  Future<Map<String, dynamic>> obtenerMetricas(String proyectoId) async {
    try {
      final proyecto = await _firestore
          .collection('proyectos')
          .doc(proyectoId)
          .get();

      final proyectoData = Proyecto.fromFirestore(proyecto);
      final fases = await obtenerFases(proyectoId);
      final documentos = await obtenerDocumentos(proyectoId);

      final fasesCompletadas =
          fases.where((f) => f.estado == 'completed').length;
      final progresoGeneral = await calcularProgresoGeneral(proyectoId);

      return {
        'progresoGeneral': progresoGeneral,
        'fasesCompletadas': fasesCompletadas,
        'totalFases': fases.length,
        'documentosGenerados': documentos.length,
        'presupuesto': proyectoData.presupuesto ?? 0.0,
        'costoActual': proyectoData.costoActual ?? 0.0,
        'variacionCosto': proyectoData.presupuesto != null && proyectoData.presupuesto! > 0
            ? ((proyectoData.costoActual ?? 0.0) - proyectoData.presupuesto!) /
                proyectoData.presupuesto! *
                100
            : 0.0,
        'fasePMIActual': proyectoData.fasePMIActual ?? 'Iniciación',
      };
    } catch (e) {
      print('❌ Error obteniendo métricas: $e');
      return {};
    }
  }
}

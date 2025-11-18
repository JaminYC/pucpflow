import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/skill_model.dart';

class AdminSkillsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  // ========================================
  // 📊 OBTENER SUGERENCIAS
  // ========================================

  /// Obtiene todas las sugerencias pendientes
  Future<List<SkillSuggestion>> getPendingSuggestions() async {
    try {
      final snapshot = await _firestore
          .collection('skill_suggestions')
          .where('status', isEqualTo: 'pending')
          .orderBy('frequency', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SkillSuggestion.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo sugerencias pendientes: $e');
      return [];
    }
  }

  /// Obtiene todas las sugerencias (pending, approved, rejected, merged)
  Future<List<SkillSuggestion>> getAllSuggestions() async {
    try {
      final snapshot = await _firestore
          .collection('skill_suggestions')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SkillSuggestion.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo todas las sugerencias: $e');
      return [];
    }
  }

  /// Stream de sugerencias pendientes (tiempo real)
  Stream<List<SkillSuggestion>> watchPendingSuggestions() {
    return _firestore
        .collection('skill_suggestions')
        .where('status', isEqualTo: 'pending')
        .orderBy('frequency', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SkillSuggestion.fromFirestore(doc))
            .toList());
  }

  /// Obtiene sugerencias por status
  /// NOTA: Obtiene todas las sugerencias y filtra en el cliente para evitar índices compuestos
  Future<List<SkillSuggestion>> getSuggestionsByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection('skill_suggestions')
          .get();

      // Filtrar y ordenar en el cliente
      final suggestions = snapshot.docs
          .map((doc) => SkillSuggestion.fromFirestore(doc))
          .where((suggestion) => suggestion.status == status)
          .toList();

      // Ordenar por fecha de creación (más recientes primero)
      suggestions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return suggestions;
    } catch (e) {
      print('❌ Error obteniendo sugerencias por status: $e');
      return [];
    }
  }

  // ========================================
  // ✅ APROBAR SUGERENCIA
  // ========================================

  /// Aprueba una sugerencia como nueva skill estándar
  Future<Map<String, dynamic>?> approveSuggestion({
    required String suggestionId,
    required String sector,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      print('✅ Aprobando sugerencia: $suggestionId');

      final callable = _functions.httpsCallable(
        'gestionarSugerenciaSkill',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60),
        ),
      );

      final result = await callable.call({
        'adminId': user.uid,
        'suggestionId': suggestionId,
        'action': 'approve',
        'sector': sector,
        'description': description,
      });

      if (result.data['error'] != null) {
        throw Exception(result.data['error']);
      }

      print('✅ Sugerencia aprobada: ${result.data['message']}');
      return result.data;
    } catch (e) {
      print('❌ Error aprobando sugerencia: $e');
      return null;
    }
  }

  // ========================================
  // 🔀 FUSIONAR SUGERENCIA
  // ========================================

  /// Fusiona una sugerencia con una skill estándar existente
  Future<Map<String, dynamic>?> mergeSuggestion({
    required String suggestionId,
    required String mergeWithSkillId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      print('🔀 Fusionando sugerencia: $suggestionId con skill: $mergeWithSkillId');

      final callable = _functions.httpsCallable(
        'gestionarSugerenciaSkill',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60),
        ),
      );

      final result = await callable.call({
        'adminId': user.uid,
        'suggestionId': suggestionId,
        'action': 'merge',
        'mergeWithSkillId': mergeWithSkillId,
      });

      if (result.data['error'] != null) {
        throw Exception(result.data['error']);
      }

      print('✅ Sugerencia fusionada: ${result.data['message']}');
      return result.data;
    } catch (e) {
      print('❌ Error fusionando sugerencia: $e');
      return null;
    }
  }

  // ========================================
  // ❌ RECHAZAR SUGERENCIA
  // ========================================

  /// Rechaza una sugerencia
  Future<Map<String, dynamic>?> rejectSuggestion({
    required String suggestionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      print('❌ Rechazando sugerencia: $suggestionId');

      final callable = _functions.httpsCallable(
        'gestionarSugerenciaSkill',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60),
        ),
      );

      final result = await callable.call({
        'adminId': user.uid,
        'suggestionId': suggestionId,
        'action': 'reject',
      });

      if (result.data['error'] != null) {
        throw Exception(result.data['error']);
      }

      print('✅ Sugerencia rechazada: ${result.data['message']}');
      return result.data;
    } catch (e) {
      print('❌ Error rechazando sugerencia: $e');
      return null;
    }
  }

  // ========================================
  // 📈 ESTADÍSTICAS
  // ========================================

  /// Obtiene estadísticas de sugerencias
  Future<Map<String, int>> getSuggestionsStats() async {
    try {
      final snapshot = await _firestore.collection('skill_suggestions').get();

      final Map<String, int> stats = {
        'total': snapshot.docs.length,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'merged': 0,
      };

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] as String? ?? 'pending';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {};
    }
  }

  /// Obtiene las sugerencias más frecuentes
  Future<List<SkillSuggestion>> getTopSuggestions({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('skill_suggestions')
          .where('status', isEqualTo: 'pending')
          .orderBy('frequency', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SkillSuggestion.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo top sugerencias: $e');
      return [];
    }
  }
}

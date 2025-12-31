import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriaMigration {
  static const String _flagPrefix = 'categoria_migration_v3_done_';
  static const String _defaultCategoria = 'Laboral';
  static const String _defaultVision = '';
  static const String _personalCategoria = 'Personal';
  static const String _legacyCategoria = 'Vida';
  static const int _batchSize = 450;

  static Future<void> runIfNeeded({required String uid}) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_flagPrefix$uid';
    if (prefs.getBool(key) == true) return;

    try {
      await _run(uid);
      await prefs.setBool(key, true);
    } catch (e) {
      print('CategoriaMigration failed: $e');
    }
  }

  static Future<void> _run(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('proyectos')
        .where('participantes', arrayContains: uid)
        .get();

    var batch = firestore.batch();
    var count = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final categoria = data['categoria'];
      final vision = data['vision'];
      String? nuevaCategoria;
      String? nuevaVision;
      if (categoria == null || (categoria is String && categoria.trim().isEmpty)) {
        nuevaCategoria = _defaultCategoria;
      } else if (categoria is String &&
          categoria.trim().toLowerCase() == _legacyCategoria.toLowerCase()) {
        nuevaCategoria = _personalCategoria;
      }

      if (vision == null || (vision is String && vision.trim().isEmpty)) {
        nuevaVision = _defaultVision;
      }

      final updates = <String, dynamic>{};
      if (nuevaCategoria != null) {
        updates['categoria'] = nuevaCategoria;
      }
      if (nuevaVision != null) {
        updates['vision'] = nuevaVision;
      }

      if (updates.isEmpty) continue;

      batch.update(doc.reference, updates);
      count++;
      if (count % _batchSize == 0) {
        await batch.commit();
        batch = firestore.batch();
      }
    }

    if (count == 0) return;

    if (count % _batchSize != 0) {
      await batch.commit();
    }
  }
}

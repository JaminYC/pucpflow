import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../models/skill_model.dart';
import '../models/cv_profile_model.dart';

class SkillsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Configuración de Cloud Functions
  // IMPORTANTE: Cambia la región si tus functions están desplegadas en otra región
  // Opciones comunes: 'us-central1', 'southamerica-east1', 'europe-west1'
  late final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1', // 👈 Cambia esto a tu región si es necesario
  );

  // Constructor para configurar emulador (solo para desarrollo local)
  SkillsService({bool useEmulator = false}) {
    if (useEmulator) {
      _functions.useFunctionsEmulator('localhost', 5001);
      print('🔧 Usando emulador de Cloud Functions en localhost:5001');
    }
  }

  // ========================================
  // 📄 EXTRACCIÓN DE CV
  // ========================================

  /// Permite al usuario seleccionar un archivo PDF
  Future<File?> pickPDFFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Importante para web
      );

      if (result != null) {
        if (result.files.single.bytes != null) {
          // Web: usar bytes
          return null; // Retornar null y usar bytes directamente
        } else if (result.files.single.path != null) {
          // Móvil/Desktop: usar path
          return File(result.files.single.path!);
        }
      }
      return null;
    } catch (e) {
      print('❌ Error seleccionando PDF: $e');
      return null;
    }
  }

  /// Convierte archivo PDF a base64
  Future<String?> pdfToBase64(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('❌ Error convirtiendo PDF a base64: $e');
      return null;
    }
  }

  /// Convierte bytes (web) a base64
  String bytesToBase64(List<int> bytes) {
    return base64Encode(bytes);
  }

  /// Extrae información del CV usando Cloud Function + OpenAI
  /// Retorna: {profile: CVProfileModel, skills: List<MappedSkill>}
  Future<Map<String, dynamic>?> extractCVProfile(String cvBase64) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      print('📄 Llamando a Cloud Function extraerCV...');

      // Timeout aumentado porque OpenAI puede tardar varios minutos
      final callable = _functions.httpsCallable(
        'extraerCV',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 300), // 5 minutos
        ),
      );

      final result = await callable.call({
        'cvBase64': cvBase64,
        'userId': user.uid,
      });

      final data = result.data;

      if (data['error'] != null) {
        throw Exception(data['error']);
      }

      // Parsear perfil
      final profileData = data['profile'] as Map<String, dynamic>;
      final profile = CVProfileModel.fromMap(profileData);

      // Parsear skills mapeadas
      final skillsData = data['skills'] as Map<String, dynamic>;
      final List<MappedSkill> mappedSkills = [];

      // Skills encontradas en BD
      if (skillsData['found'] != null) {
        for (var skillMap in skillsData['found']) {
          mappedSkills.add(MappedSkill.fromFoundMap(skillMap));
        }
      }

      // Skills no encontradas
      if (skillsData['notFound'] != null) {
        for (var skillData in skillsData['notFound']) {
          // Ahora notFound es un array de objetos {name, level, suggested}
          if (skillData is String) {
            // Retrocompatibilidad: si es solo un string
            mappedSkills.add(MappedSkill.fromNotFound(skillData));
          } else if (skillData is Map) {
            // Nuevo formato: objeto con más información
            mappedSkills.add(MappedSkill.fromNotFound(
              skillData['name'] ?? skillData.toString(),
              level: skillData['level'] ?? 5,
            ));
          }
        }
      }

      print('✅ CV procesado: ${mappedSkills.length} skills extraídas');

      return {
        'profile': profile,
        'skills': mappedSkills,
      };
    } catch (e) {
      print('❌ Error extrayendo CV: $e');
      return null;
    }
  }

  // ========================================
  // 💾 GUARDAR SKILLS CONFIRMADAS
  // ========================================

  /// Guarda las skills confirmadas por el usuario
  Future<bool> saveConfirmedSkills(List<Map<String, dynamic>> confirmedSkills) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      print('💾 Guardando ${confirmedSkills.length} skills confirmadas...');

      final callable = _functions.httpsCallable(
        'guardarSkillsConfirmadas',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60), // 1 minuto
        ),
      );

      final result = await callable.call({
        'userId': user.uid,
        'confirmedSkills': confirmedSkills,
      });

      if (result.data['error'] != null) {
        throw Exception(result.data['error']);
      }

      print('✅ Skills guardadas: ${result.data['savedCount']}');
      return true;
    } catch (e) {
      print('❌ Error guardando skills: $e');
      return false;
    }
  }

  // ========================================
  // 📊 CONSULTAR SKILLS DEL USUARIO
  // ========================================

  /// Obtiene todas las skills profesionales del usuario
  Future<List<UserSkillModel>> getUserSkills() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('professional_skills')
          .orderBy('level', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserSkillModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo skills del usuario: $e');
      return [];
    }
  }

  /// Obtiene skills agrupadas por sector
  Future<Map<String, List<UserSkillModel>>> getUserSkillsBySector() async {
    final skills = await getUserSkills();
    final Map<String, List<UserSkillModel>> grouped = {};

    for (var skill in skills) {
      if (!grouped.containsKey(skill.sector)) {
        grouped[skill.sector] = [];
      }
      grouped[skill.sector]!.add(skill);
    }

    return grouped;
  }

  /// Agrupa las skills del usuario por naturaleza (técnica, blanda, liderazgo, etc.)
  Future<Map<SkillNature, List<UserSkillModel>>> getUserSkillsByNature() async {
    final skills = await getUserSkills();
    final Map<SkillNature, List<UserSkillModel>> grouped = {};

    for (var skill in skills) {
      grouped.putIfAbsent(skill.nature, () => []);
      grouped[skill.nature]!.add(skill);
    }

    return grouped;
  }

  /// Stream de skills del usuario (tiempo real)
  Stream<List<UserSkillModel>> watchUserSkills() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('professional_skills')
        .orderBy('level', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserSkillModel.fromFirestore(doc))
            .toList());
  }

  // ========================================
  // ✏️ ACTUALIZAR SKILLS
  // ========================================

  /// Actualiza el nivel de una skill del usuario
  Future<bool> updateSkillLevel(String skillId, int newLevel) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Validar nivel 1-10
      final validLevel = newLevel.clamp(1, 10);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('professional_skills')
          .doc(skillId)
          .update({
        'level': validLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Nivel actualizado: $skillId → $validLevel');
      return true;
    } catch (e) {
      print('❌ Error actualizando nivel: $e');
      return false;
    }
  }

  /// Elimina una skill del perfil del usuario
  Future<bool> deleteSkill(String skillId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('professional_skills')
          .doc(skillId)
          .delete();

      print('✅ Skill eliminada: $skillId');
      return true;
    } catch (e) {
      print('❌ Error eliminando skill: $e');
      return false;
    }
  }

  // ========================================
  // 🗂️ CATÁLOGO DE SKILLS DISPONIBLES
  // ========================================

  /// Obtiene todas las skills disponibles en el sistema
  Future<List<SkillModel>> getAllSkills() async {
    try {
      final snapshot = await _firestore
          .collection('skills')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => SkillModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo catálogo de skills: $e');
      return [];
    }
  }

  /// Obtiene skills por sector
  Future<List<SkillModel>> getSkillsBySector(String sector) async {
    try {
      final snapshot = await _firestore
          .collection('skills')
          .where('sector', isEqualTo: sector)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => SkillModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo skills por sector: $e');
      return [];
    }
  }

  /// Busca skills por nombre (búsqueda parcial)
  Future<List<SkillModel>> searchSkills(String query) async {
    try {
      if (query.isEmpty) return [];

      // Firestore no tiene búsqueda full-text, así que obtenemos todas
      // y filtramos en cliente (para producción usar Algolia/ElasticSearch)
      final snapshot = await _firestore.collection('skills').get();

      final queryLower = query.toLowerCase();

      return snapshot.docs
          .map((doc) => SkillModel.fromFirestore(doc))
          .where((skill) => skill.name.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      print('❌ Error buscando skills: $e');
      return [];
    }
  }

  // ========================================
  // 📈 ESTADÍSTICAS
  // ========================================

  /// Calcula el nivel promedio de skills del usuario
  Future<double> getUserAverageSkillLevel() async {
    final skills = await getUserSkills();
    if (skills.isEmpty) return 0.0;

    final sum = skills.fold<int>(0, (sum, skill) => sum + skill.level);
    return sum / skills.length;
  }

  /// Cuenta skills por nivel de competencia
  Future<Map<String, int>> getSkillLevelDistribution() async {
    final skills = await getUserSkills();
    final Map<String, int> distribution = {
      'Principiante (1-3)': 0,
      'Intermedio (4-6)': 0,
      'Avanzado (7-8)': 0,
      'Experto (9-10)': 0,
    };

    for (var skill in skills) {
      if (skill.level <= 3) {
        distribution['Principiante (1-3)'] = distribution['Principiante (1-3)']! + 1;
      } else if (skill.level <= 6) {
        distribution['Intermedio (4-6)'] = distribution['Intermedio (4-6)']! + 1;
      } else if (skill.level <= 8) {
        distribution['Avanzado (7-8)'] = distribution['Avanzado (7-8)']! + 1;
      } else {
        distribution['Experto (9-10)'] = distribution['Experto (9-10)']! + 1;
      }
    }

    return distribution;
  }
}

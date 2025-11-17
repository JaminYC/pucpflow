import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Skill (habilidad profesional) almacenada en Firestore
/// Colección: 'skills'
class SkillModel {
  final String id;
  final String name;
  final String sector; // ej: "Programación", "Cloud", "Frontend"
  final String? description;
  final int standardLevel; // Nivel estándar recomendado (1-10)

  SkillModel({
    required this.id,
    required this.name,
    required this.sector,
    this.description,
    this.standardLevel = 5,
  });

  factory SkillModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SkillModel(
      id: documentId,
      name: map['name'] ?? '',
      sector: map['sector'] ?? 'General',
      description: map['description'],
      standardLevel: map['standardLevel'] ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sector': sector,
      'description': description,
      'standardLevel': standardLevel,
    };
  }

  factory SkillModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SkillModel.fromMap(data, doc.id);
  }
}

/// Modelo de UserSkill (habilidad del usuario)
/// Colección: 'users/{uid}/professional_skills'
class UserSkillModel {
  final String id;
  final String skillId;
  final String skillName;
  final String sector;
  final int level; // Nivel de competencia del usuario (1-10)
  final String notes;
  final DateTime acquiredAt;
  final DateTime? updatedAt;

  UserSkillModel({
    required this.id,
    required this.skillId,
    required this.skillName,
    required this.sector,
    required this.level,
    this.notes = '',
    required this.acquiredAt,
    this.updatedAt,
  });

  factory UserSkillModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserSkillModel(
      id: documentId,
      skillId: map['skillId'] ?? documentId,
      skillName: map['skillName'] ?? '',
      sector: map['sector'] ?? 'General',
      level: map['level'] ?? 5,
      notes: map['notes'] ?? '',
      acquiredAt: map['acquiredAt'] != null
          ? (map['acquiredAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skillId': skillId,
      'skillName': skillName,
      'sector': sector,
      'level': level,
      'notes': notes,
      'acquiredAt': Timestamp.fromDate(acquiredAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory UserSkillModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSkillModel.fromMap(data, doc.id);
  }

  /// Crea una copia con campos modificados
  UserSkillModel copyWith({
    String? id,
    String? skillId,
    String? skillName,
    String? sector,
    int? level,
    String? notes,
    DateTime? acquiredAt,
    DateTime? updatedAt,
  }) {
    return UserSkillModel(
      id: id ?? this.id,
      skillId: skillId ?? this.skillId,
      skillName: skillName ?? this.skillName,
      sector: sector ?? this.sector,
      level: level ?? this.level,
      notes: notes ?? this.notes,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Modelo para skills mapeadas desde el CV
class MappedSkill {
  final String aiSkill; // Nombre extraído por IA
  final String? dbSkillId; // ID en Firestore (si se encontró)
  final String? dbSkillName; // Nombre en BD (si se encontró)
  final String? sector;
  final int level; // Nivel sugerido por IA (1-10)
  final bool isFound; // Si se encontró en BD o no

  MappedSkill({
    required this.aiSkill,
    this.dbSkillId,
    this.dbSkillName,
    this.sector,
    required this.level,
    required this.isFound,
  });

  factory MappedSkill.fromFoundMap(Map<String, dynamic> map) {
    return MappedSkill(
      aiSkill: map['aiSkill'] ?? '',
      dbSkillId: map['dbSkillId'],
      dbSkillName: map['dbSkillName'],
      sector: map['sector'],
      level: map['level'] ?? 5,
      isFound: true,
    );
  }

  factory MappedSkill.fromNotFound(String skillName, {int level = 5}) {
    return MappedSkill(
      aiSkill: skillName,
      level: level,
      isFound: false,
    );
  }
}

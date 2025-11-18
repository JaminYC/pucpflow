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
  final String? suggestedSector; // Sector sugerido para skills custom
  final String? cvContext; // Contexto del CV donde se mencionó

  MappedSkill({
    required this.aiSkill,
    this.dbSkillId,
    this.dbSkillName,
    this.sector,
    required this.level,
    required this.isFound,
    this.suggestedSector,
    this.cvContext,
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

  factory MappedSkill.fromNotFoundMap(Map<String, dynamic> map) {
    return MappedSkill(
      aiSkill: map['name'] ?? '',
      level: map['level'] ?? 5,
      isFound: false,
      suggestedSector: map['suggestedSector'],
      cvContext: map['cvContext'],
    );
  }
}

/// Modelo para sugerencias de skills personalizadas
class SkillSuggestion {
  final String id;
  final String suggestedName;
  final String normalizedName;
  final String suggestedBy;
  final String userEmail;
  final int level;
  final String cvContext;
  final int frequency;
  final String status; // pending, approved, rejected, merged
  final String? approvedAs;
  final String suggestedSector;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  SkillSuggestion({
    required this.id,
    required this.suggestedName,
    required this.normalizedName,
    required this.suggestedBy,
    required this.userEmail,
    required this.level,
    this.cvContext = '',
    this.frequency = 1,
    this.status = 'pending',
    this.approvedAs,
    this.suggestedSector = 'General',
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory SkillSuggestion.fromMap(Map<String, dynamic> map, String documentId) {
    return SkillSuggestion(
      id: documentId,
      suggestedName: map['suggestedName'] ?? '',
      normalizedName: map['normalizedName'] ?? '',
      suggestedBy: map['suggestedBy'] ?? '',
      userEmail: map['userEmail'] ?? '',
      level: map['level'] ?? 5,
      cvContext: map['cvContext'] ?? '',
      frequency: map['frequency'] ?? 1,
      status: map['status'] ?? 'pending',
      approvedAs: map['approvedAs'],
      suggestedSector: map['suggestedSector'] ?? 'General',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: map['reviewedBy'],
    );
  }

  factory SkillSuggestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SkillSuggestion.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'suggestedName': suggestedName,
      'normalizedName': normalizedName,
      'suggestedBy': suggestedBy,
      'userEmail': userEmail,
      'level': level,
      'cvContext': cvContext,
      'frequency': frequency,
      'status': status,
      'approvedAs': approvedAs,
      'suggestedSector': suggestedSector,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Proyecto PMI
/// Colección: 'pmi_projects'
class PMIProject {
  final String id;
  final String name;
  final String description;
  final String ownerId; // uid del creador
  final String ownerName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status; // 'draft', 'active', 'completed', 'cancelled'

  // Metadatos opcionales
  final String? objetivo;
  final String? alcance;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final List<String> documentosIniciales; // URLs de documentos subidos

  // Estadísticas
  final int totalFases;
  final int fasesCompletadas;
  final int totalTareas;
  final int tareasCompletadas;
  final double progreso; // 0.0 a 1.0

  PMIProject({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
    this.updatedAt,
    this.status = 'draft',
    this.objetivo,
    this.alcance,
    this.fechaInicio,
    this.fechaFin,
    this.documentosIniciales = const [],
    this.totalFases = 0,
    this.fasesCompletadas = 0,
    this.totalTareas = 0,
    this.tareasCompletadas = 0,
    this.progreso = 0.0,
  });

  factory PMIProject.fromMap(Map<String, dynamic> map, String documentId) {
    return PMIProject(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      status: map['status'] ?? 'draft',
      objetivo: map['objetivo'],
      alcance: map['alcance'],
      fechaInicio: map['fechaInicio'] != null
          ? (map['fechaInicio'] as Timestamp).toDate()
          : null,
      fechaFin: map['fechaFin'] != null
          ? (map['fechaFin'] as Timestamp).toDate()
          : null,
      documentosIniciales: List<String>.from(map['documentosIniciales'] ?? []),
      totalFases: map['totalFases'] ?? 0,
      fasesCompletadas: map['fasesCompletadas'] ?? 0,
      totalTareas: map['totalTareas'] ?? 0,
      tareasCompletadas: map['tareasCompletadas'] ?? 0,
      progreso: (map['progreso'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'status': status,
      'objetivo': objetivo,
      'alcance': alcance,
      'fechaInicio': fechaInicio != null ? Timestamp.fromDate(fechaInicio!) : null,
      'fechaFin': fechaFin != null ? Timestamp.fromDate(fechaFin!) : null,
      'documentosIniciales': documentosIniciales,
      'totalFases': totalFases,
      'fasesCompletadas': fasesCompletadas,
      'totalTareas': totalTareas,
      'tareasCompletadas': tareasCompletadas,
      'progreso': progreso,
    };
  }

  factory PMIProject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PMIProject.fromMap(data, doc.id);
  }

  PMIProject copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? ownerName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? objetivo,
    String? alcance,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    List<String>? documentosIniciales,
    int? totalFases,
    int? fasesCompletadas,
    int? totalTareas,
    int? tareasCompletadas,
    double? progreso,
  }) {
    return PMIProject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      objetivo: objetivo ?? this.objetivo,
      alcance: alcance ?? this.alcance,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      documentosIniciales: documentosIniciales ?? this.documentosIniciales,
      totalFases: totalFases ?? this.totalFases,
      fasesCompletadas: fasesCompletadas ?? this.fasesCompletadas,
      totalTareas: totalTareas ?? this.totalTareas,
      tareasCompletadas: tareasCompletadas ?? this.tareasCompletadas,
      progreso: progreso ?? this.progreso,
    );
  }
}

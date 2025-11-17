import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Fase PMI
/// Subcolección: 'pmi_projects/{projectId}/fases'
class PMIFase {
  final String id;
  final String projectId;
  final String name; // 'Iniciación', 'Planificación', 'Ejecución', 'Monitoreo', 'Cierre'
  final int orden; // 1, 2, 3, 4, 5
  final String description;
  final String status; // 'pending', 'in_progress', 'completed'
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  // Estadísticas
  final int totalNodos;
  final int nodosCompletados;
  final double progreso; // 0.0 a 1.0

  PMIFase({
    required this.id,
    required this.projectId,
    required this.name,
    required this.orden,
    required this.description,
    this.status = 'pending',
    this.fechaInicio,
    this.fechaFin,
    this.totalNodos = 0,
    this.nodosCompletados = 0,
    this.progreso = 0.0,
  });

  factory PMIFase.fromMap(Map<String, dynamic> map, String documentId, String projectId) {
    return PMIFase(
      id: documentId,
      projectId: projectId,
      name: map['name'] ?? '',
      orden: map['orden'] ?? 1,
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      fechaInicio: map['fechaInicio'] != null
          ? (map['fechaInicio'] as Timestamp).toDate()
          : null,
      fechaFin: map['fechaFin'] != null
          ? (map['fechaFin'] as Timestamp).toDate()
          : null,
      totalNodos: map['totalNodos'] ?? 0,
      nodosCompletados: map['nodosCompletados'] ?? 0,
      progreso: (map['progreso'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'orden': orden,
      'description': description,
      'status': status,
      'fechaInicio': fechaInicio != null ? Timestamp.fromDate(fechaInicio!) : null,
      'fechaFin': fechaFin != null ? Timestamp.fromDate(fechaFin!) : null,
      'totalNodos': totalNodos,
      'nodosCompletados': nodosCompletados,
      'progreso': progreso,
    };
  }

  factory PMIFase.fromFirestore(DocumentSnapshot doc, String projectId) {
    final data = doc.data() as Map<String, dynamic>;
    return PMIFase.fromMap(data, doc.id, projectId);
  }

  PMIFase copyWith({
    String? id,
    String? projectId,
    String? name,
    int? orden,
    String? description,
    String? status,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? totalNodos,
    int? nodosCompletados,
    double? progreso,
  }) {
    return PMIFase(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      orden: orden ?? this.orden,
      description: description ?? this.description,
      status: status ?? this.status,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      totalNodos: totalNodos ?? this.totalNodos,
      nodosCompletados: nodosCompletados ?? this.nodosCompletados,
      progreso: progreso ?? this.progreso,
    );
  }

  /// Obtiene el color de la fase según su nombre
  static int getColorForFase(String faseName) {
    switch (faseName) {
      case 'Iniciación':
        return 0xFF4CAF50; // Verde
      case 'Planificación':
        return 0xFF2196F3; // Azul
      case 'Ejecución':
        return 0xFFFF9800; // Naranja
      case 'Monitoreo':
        return 0xFF9C27B0; // Púrpura
      case 'Cierre':
        return 0xFF607D8B; // Gris azulado
      default:
        return 0xFF757575; // Gris
    }
  }

  /// Obtiene el ícono de la fase según su nombre
  static String getIconForFase(String faseName) {
    switch (faseName) {
      case 'Iniciación':
        return '🚀';
      case 'Planificación':
        return '📋';
      case 'Ejecución':
        return '⚙️';
      case 'Monitoreo':
        return '📊';
      case 'Cierre':
        return '✅';
      default:
        return '📁';
    }
  }
}

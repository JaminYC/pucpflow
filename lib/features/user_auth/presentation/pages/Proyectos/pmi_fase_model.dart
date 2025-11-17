import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Fase PMI
/// Subcolección: proyectos/{proyectoId}/fases_pmi/{faseId}
class PMIFase {
  final String id;
  final String nombre; // 'Iniciación', 'Planificación', 'Ejecución', 'Monitoreo', 'Cierre'
  final int orden; // 1, 2, 3, 4, 5
  final String descripcion;
  final String estado; // 'pending', 'in_progress', 'completed'
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final List<String> tareasIds; // IDs de tareas asociadas a esta fase
  final List<String> documentosIds; // IDs de documentos asociados

  // Estadísticas calculadas
  final int totalTareas;
  final int tareasCompletadas;
  final double progreso; // 0.0 a 1.0

  PMIFase({
    required this.id,
    required this.nombre,
    required this.orden,
    this.descripcion = '',
    this.estado = 'pending',
    this.fechaInicio,
    this.fechaFin,
    this.tareasIds = const [],
    this.documentosIds = const [],
    this.totalTareas = 0,
    this.tareasCompletadas = 0,
    this.progreso = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'orden': orden,
      'descripcion': descripcion,
      'estado': estado,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'tareasIds': tareasIds,
      'documentosIds': documentosIds,
      'totalTareas': totalTareas,
      'tareasCompletadas': tareasCompletadas,
      'progreso': progreso,
    };
  }

  factory PMIFase.fromJson(Map<String, dynamic> json, String id) {
    return PMIFase(
      id: id,
      nombre: json['nombre'] ?? '',
      orden: json['orden'] ?? 1,
      descripcion: json['descripcion'] ?? '',
      estado: json['estado'] ?? 'pending',
      fechaInicio: json['fechaInicio'] != null
          ? (json['fechaInicio'] is Timestamp
              ? (json['fechaInicio'] as Timestamp).toDate()
              : DateTime.tryParse(json['fechaInicio']))
          : null,
      fechaFin: json['fechaFin'] != null
          ? (json['fechaFin'] is Timestamp
              ? (json['fechaFin'] as Timestamp).toDate()
              : DateTime.tryParse(json['fechaFin']))
          : null,
      tareasIds: List<String>.from(json['tareasIds'] ?? []),
      documentosIds: List<String>.from(json['documentosIds'] ?? []),
      totalTareas: json['totalTareas'] ?? 0,
      tareasCompletadas: json['tareasCompletadas'] ?? 0,
      progreso: (json['progreso'] ?? 0.0).toDouble(),
    );
  }

  factory PMIFase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PMIFase.fromJson(data, doc.id);
  }

  PMIFase copyWith({
    String? id,
    String? nombre,
    int? orden,
    String? descripcion,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    List<String>? tareasIds,
    List<String>? documentosIds,
    int? totalTareas,
    int? tareasCompletadas,
    double? progreso,
  }) {
    return PMIFase(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      orden: orden ?? this.orden,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      tareasIds: tareasIds ?? this.tareasIds,
      documentosIds: documentosIds ?? this.documentosIds,
      totalTareas: totalTareas ?? this.totalTareas,
      tareasCompletadas: tareasCompletadas ?? this.tareasCompletadas,
      progreso: progreso ?? this.progreso,
    );
  }

  /// Obtiene el color de la fase según su nombre
  int getColor() {
    switch (nombre) {
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
  String getIcon() {
    switch (nombre) {
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

  /// Fases predefinidas de PMI
  static List<PMIFase> getFasesDefault() {
    return [
      PMIFase(
        id: 'iniciacion',
        nombre: 'Iniciación',
        orden: 1,
        descripcion: 'Definir el proyecto formalmente y obtener autorización para comenzar',
      ),
      PMIFase(
        id: 'planificacion',
        nombre: 'Planificación',
        orden: 2,
        descripcion: 'Establecer el alcance, objetivos y curso de acción para lograr los objetivos',
      ),
      PMIFase(
        id: 'ejecucion',
        nombre: 'Ejecución',
        orden: 3,
        descripcion: 'Completar el trabajo definido en el plan de gestión del proyecto',
      ),
      PMIFase(
        id: 'monitoreo',
        nombre: 'Monitoreo',
        orden: 4,
        descripcion: 'Rastrear, revisar y regular el progreso y desempeño del proyecto',
      ),
      PMIFase(
        id: 'cierre',
        nombre: 'Cierre',
        orden: 5,
        descripcion: 'Finalizar todas las actividades y cerrar formalmente el proyecto',
      ),
    ];
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Documento PMI
/// Subcolección: proyectos/{proyectoId}/documentos_pmi/{docId}
class PMIDocumento {
  final String id;
  final String nombre;
  final String tipo; // 'acta_constitucion', 'plan_proyecto', 'registro_riesgos', etc.
  final String? descripcion;
  final String? urlArchivo; // URL de Storage si es archivo subido
  final String? contenido; // Contenido JSON si es generado por IA
  final String faseId; // Fase a la que pertenece
  final String? creadoPor; // UID del usuario que lo creó
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;
  final String estado; // 'borrador', 'revision', 'aprobado', 'obsoleto'
  final List<String> etiquetas; // Tags para organización

  PMIDocumento({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.descripcion,
    this.urlArchivo,
    this.contenido,
    required this.faseId,
    this.creadoPor,
    required this.fechaCreacion,
    this.fechaActualizacion,
    this.estado = 'borrador',
    this.etiquetas = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'tipo': tipo,
      'descripcion': descripcion,
      'urlArchivo': urlArchivo,
      'contenido': contenido,
      'faseId': faseId,
      'creadoPor': creadoPor,
      'fechaCreacion': fechaCreacion,
      'fechaActualizacion': fechaActualizacion,
      'estado': estado,
      'etiquetas': etiquetas,
    };
  }

  factory PMIDocumento.fromJson(Map<String, dynamic> json, String id) {
    return PMIDocumento(
      id: id,
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? 'otro',
      descripcion: json['descripcion'],
      urlArchivo: json['urlArchivo'],
      contenido: json['contenido'],
      faseId: json['faseId'] ?? '',
      creadoPor: json['creadoPor'],
      fechaCreacion: json['fechaCreacion'] != null
          ? (json['fechaCreacion'] is Timestamp
              ? (json['fechaCreacion'] as Timestamp).toDate()
              : DateTime.tryParse(json['fechaCreacion']) ?? DateTime.now())
          : DateTime.now(),
      fechaActualizacion: json['fechaActualizacion'] != null
          ? (json['fechaActualizacion'] is Timestamp
              ? (json['fechaActualizacion'] as Timestamp).toDate()
              : DateTime.tryParse(json['fechaActualizacion']))
          : null,
      estado: json['estado'] ?? 'borrador',
      etiquetas: List<String>.from(json['etiquetas'] ?? []),
    );
  }

  factory PMIDocumento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PMIDocumento.fromJson(data, doc.id);
  }

  PMIDocumento copyWith({
    String? id,
    String? nombre,
    String? tipo,
    String? descripcion,
    String? urlArchivo,
    String? contenido,
    String? faseId,
    String? creadoPor,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? estado,
    List<String>? etiquetas,
  }) {
    return PMIDocumento(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      descripcion: descripcion ?? this.descripcion,
      urlArchivo: urlArchivo ?? this.urlArchivo,
      contenido: contenido ?? this.contenido,
      faseId: faseId ?? this.faseId,
      creadoPor: creadoPor ?? this.creadoPor,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      estado: estado ?? this.estado,
      etiquetas: etiquetas ?? this.etiquetas,
    );
  }

  /// Tipos de documentos PMI predefinidos
  static Map<String, String> getTiposDocumentos() {
    return {
      'acta_constitucion': 'Acta de Constitución del Proyecto',
      'plan_proyecto': 'Plan de Gestión del Proyecto',
      'registro_riesgos': 'Registro de Riesgos',
      'registro_stakeholders': 'Registro de Interesados',
      'cronograma': 'Cronograma del Proyecto',
      'presupuesto': 'Presupuesto y Control de Costos',
      'wbs': 'EDT / WBS',
      'plan_calidad': 'Plan de Gestión de Calidad',
      'plan_comunicacion': 'Plan de Comunicación',
      'plan_recursos': 'Plan de Gestión de Recursos',
      'registro_cambios': 'Registro de Control de Cambios',
      'lecciones_aprendidas': 'Lecciones Aprendidas',
      'informe_cierre': 'Informe de Cierre del Proyecto',
      'otro': 'Otro Documento',
    };
  }

  /// Obtiene el ícono según el tipo de documento
  String getIcon() {
    switch (tipo) {
      case 'acta_constitucion':
        return '📜';
      case 'plan_proyecto':
        return '📋';
      case 'registro_riesgos':
        return '⚠️';
      case 'registro_stakeholders':
        return '👥';
      case 'cronograma':
        return '📅';
      case 'presupuesto':
        return '💰';
      case 'wbs':
        return '🌳';
      case 'plan_calidad':
        return '✅';
      case 'plan_comunicacion':
        return '📢';
      case 'plan_recursos':
        return '🔧';
      case 'registro_cambios':
        return '🔄';
      case 'lecciones_aprendidas':
        return '💡';
      case 'informe_cierre':
        return '🏁';
      default:
        return '📄';
    }
  }
}

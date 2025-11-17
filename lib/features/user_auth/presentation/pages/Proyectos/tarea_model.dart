class Tarea {
  String titulo;
  DateTime? fecha;
  int duracion;
  int prioridad;
  bool completado;
  int colorId;
  List<String> responsables;
  String tipoTarea;
  Map<String, int> requisitos;
  String? dificultad;
  String? descripcion;
  List<String> tareasPrevias;
  String area; // ✅ Para recursos: "Equipo Desarrollo", "Consultor Externo", etc.
  List<String> habilidadesRequeridas;

  // ========================================
  // 🆕 CAMPOS PMI - Jerarquía del Proyecto
  // ========================================
  String? fasePMI;        // "Iniciación", "Planificación", "Ejecución", "Monitoreo", "Cierre"
  String? entregable;     // "Project Charter", "Plan de Proyecto", "Informe Final"
  String? paqueteTrabajo; // "Documentación Inicial", "Análisis de Riesgos", "Testing"

  // CAMPO AUXILIAR (NO SE GUARDA EN FIRESTORE)
  List<String>? responsablesNombres;

  Tarea({
    required this.titulo,
    this.fecha,
    required this.duracion,
    this.prioridad = 2,
    this.completado = false,
    required this.colorId,
    this.responsables = const [],
    required this.tipoTarea,
    this.requisitos = const {},
    this.dificultad,
    this.descripcion,
    this.tareasPrevias = const [],
    this.area = 'General',
    this.habilidadesRequeridas = const [],
    // Campos PMI opcionales
    this.fasePMI,
    this.entregable,
    this.paqueteTrabajo,
    this.responsablesNombres,
  });

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'fecha': fecha?.toIso8601String(),
      'duracion': duracion,
      'prioridad': prioridad,
      'completado': completado,
      'colorId': colorId,
      'responsables': responsables,
      'tipoTarea': tipoTarea,
      'requisitos': requisitos,
      'dificultad': dificultad,
      'descripcion': descripcion,
      'tareasPrevias': tareasPrevias,
      'area': area,
      'habilidadesRequeridas': habilidadesRequeridas,
      // Campos PMI
      'fasePMI': fasePMI,
      'entregable': entregable,
      'paqueteTrabajo': paqueteTrabajo,
    };
  }

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      titulo: json['titulo'] ?? 'Sin título',
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
      duracion: json['duracion'] ?? 60,
      prioridad: json['prioridad'] ?? 2,
      completado: json['completado'] ?? false,
      colorId: json['colorId'] ?? 0,
      responsables: List<String>.from(json['responsables'] ?? []),
      tipoTarea: json['tipoTarea'] ?? 'General',
      requisitos: Map<String, int>.from(json['requisitos'] ?? {}),
      dificultad: json['dificultad'],
      descripcion: json['descripcion'],
      tareasPrevias: List<String>.from(json['tareasPrevias'] ?? []),
      area: json['area'] ?? 'General',
      habilidadesRequeridas: List<String>.from(json['habilidadesRequeridas'] ?? []),
      // Campos PMI
      fasePMI: json['fasePMI'],
      entregable: json['entregable'],
      paqueteTrabajo: json['paqueteTrabajo'],
    );
  }
}

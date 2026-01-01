class Tarea {
  String titulo;
  DateTime? fecha; // ⚠️ DEPRECADO: Se mantiene por compatibilidad, usar fechaLimite o fechaProgramada
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

  // ========================================
  // 🆕 CAMPOS DE FECHAS MEJORADOS
  // ========================================
  DateTime? fechaLimite;     // Deadline - cuándo DEBE estar completa la tarea
  DateTime? fechaProgramada; // Hora/fecha programada - cuándo se HARÁ la tarea
  DateTime? fechaCompletada; // Timestamp exacto de cuándo se completó la tarea

  // ========================================
  // 🆕 GOOGLE CALENDAR INTEGRATION
  // ========================================
  String? googleCalendarEventId; // ID del evento en Google Calendar para sincronización

  // CAMPO AUXILIAR (NO SE GUARDA EN FIRESTORE)
  List<String>? responsablesNombres;

  Tarea({
    required this.titulo,
    this.fecha, // Se mantiene por compatibilidad
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
    // Campos de fechas mejorados
    this.fechaLimite,
    this.fechaProgramada,
    this.fechaCompletada,
    // Google Calendar integration
    this.googleCalendarEventId,
    this.responsablesNombres,
  });

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'fecha': fecha?.toIso8601String(), // Mantener por compatibilidad
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
      // Campos de fechas mejorados
      'fechaLimite': fechaLimite?.toIso8601String(),
      'fechaProgramada': fechaProgramada?.toIso8601String(),
      'fechaCompletada': fechaCompletada?.toIso8601String(),
      // Google Calendar integration
      'googleCalendarEventId': googleCalendarEventId,
    };
  }

  factory Tarea.fromJson(Map<String, dynamic> json) {
    // Migración automática: si existe 'fecha' pero no 'fechaLimite', asumimos que 'fecha' es el deadline
    DateTime? fechaMigrada;
    DateTime? fechaLimiteMigrada;
    DateTime? fechaProgramadaMigrada;
    DateTime? fechaCompletadaMigrada;

    if (json['fecha'] != null) {
      fechaMigrada = DateTime.parse(json['fecha']);
    }

    if (json['fechaLimite'] != null) {
      fechaLimiteMigrada = DateTime.parse(json['fechaLimite']);
    } else if (fechaMigrada != null) {
      // Si no hay fechaLimite pero sí fecha, migrar fecha → fechaLimite
      fechaLimiteMigrada = fechaMigrada;
    }

    if (json['fechaProgramada'] != null) {
      fechaProgramadaMigrada = DateTime.parse(json['fechaProgramada']);
    }

    if (json['fechaCompletada'] != null) {
      fechaCompletadaMigrada = DateTime.parse(json['fechaCompletada']);
    }

    return Tarea(
      titulo: json['titulo'] ?? 'Sin título',
      fecha: fechaMigrada, // Mantener por compatibilidad
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
      area: _normalizarArea(json['area'] ?? 'General'),
      habilidadesRequeridas: List<String>.from(json['habilidadesRequeridas'] ?? []),
      // Campos PMI
      fasePMI: json['fasePMI'],
      entregable: json['entregable'],
      paqueteTrabajo: json['paqueteTrabajo'],
      // Campos de fechas mejorados
      fechaLimite: fechaLimiteMigrada,
      fechaProgramada: fechaProgramadaMigrada,
      fechaCompletada: fechaCompletadaMigrada,
      // Google Calendar integration
      googleCalendarEventId: json['googleCalendarEventId'],
    );
  }

  // Normalizar nombres de áreas (eliminar saltos de línea y espacios extra)
  static String _normalizarArea(String area) {
    return area.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

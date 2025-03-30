class Tarea {
  String titulo;
  DateTime? fecha; // Puede ser nulo para tareas libres
  int duracion;
  int prioridad;
  bool completado;
  int colorId;
  List<String> responsables; // Lista de IDs de usuarios responsables
  String tipoTarea; // "Manual", "Libre", "Automática"

  // Nuevos campos para matching y descripción
  Map<String, int> requisitos;
  String? dificultad; // "baja", "media", "alta"
  String? descripcion;

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
      responsables: json['responsables'] != null
          ? List<String>.from(json['responsables'])
          : [],
      tipoTarea: json['tipoTarea'] ?? 'General',
      requisitos: Map<String, int>.from(json['requisitos'] ?? {}),
      dificultad: json['dificultad'],
      descripcion: json['descripcion'],
    );
  }
}

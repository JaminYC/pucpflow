class Tarea {
  String titulo;
  DateTime fecha;
  int duracion;
  int prioridad;
  bool completado;
  int colorId;
  String responsable; // Nuevo campo obligatorio

  Tarea({
    required this.titulo,
    required this.fecha,
    required this.duracion,
    this.prioridad = 2,
    this.completado = false,
    required this.colorId,
    required this.responsable,
  });

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'fecha': fecha.toIso8601String(),
      'duracion': duracion,
      'prioridad': prioridad,
      'completado': completado,
      'colorId': colorId,
      'responsable': responsable,
    };
  }

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      titulo: json['titulo'],
      fecha: DateTime.parse(json['fecha']),
      duracion: json['duracion'],
      prioridad: json['prioridad'] ?? 2,
      completado: json['completado'] ?? false,
      colorId: json['colorId'],
      responsable: json['responsable'],
    );
  }
}

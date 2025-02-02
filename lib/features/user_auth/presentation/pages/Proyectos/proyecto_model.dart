class Proyecto {
  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fechaInicio;
  List<Tarea> tareas;

  Proyecto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fechaInicio,
    this.tareas = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'fechaInicio': fechaInicio.toIso8601String(),
      'tareas': tareas.map((t) => t.toJson()).toList(),
    };
  }

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    return Proyecto(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      fechaInicio: DateTime.parse(json['fechaInicio']),
      tareas: (json['tareas'] as List<dynamic>?)
              ?.map((tareaJson) => Tarea.fromJson(tareaJson))
              .toList() ??
          [],
    );
  }
}
class Tarea {
  final String titulo;
  final DateTime fecha;
  final int colorId; // ✅ Añadido

  Tarea({
    required this.titulo,
    required this.fecha,
    required this.colorId, // ✅ Añadido
  });

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'fecha': fecha.toIso8601String(),
      'colorId': colorId, // ✅ Guardar el color
    };
  }

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      titulo: json['titulo'],
      fecha: DateTime.parse(json['fecha']),
      colorId: json['colorId'] ?? 1, // ✅ Cargar el color
    );
  }
}

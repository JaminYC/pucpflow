import 'dart:convert';
import 'tarea_model.dart';

class Proyecto {
  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fechaInicio;
  final String propietario;  // 🔹 ID del creador del proyecto
  final List<String> participantes; // 🔹 Lista de IDs de usuarios
  List<Tarea> tareas;

  Proyecto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fechaInicio,
    required this.propietario,
    required this.participantes,
    this.tareas = const [],
  });
   // ✅ Método copyWith para actualizar propiedades sin perder los valores originales
  Proyecto copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    DateTime? fechaInicio,
    String? propietario,
    List<String>? participantes,
  }) {
    return Proyecto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      propietario: propietario ?? this.propietario,
      participantes: participantes ?? this.participantes,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'fechaInicio': fechaInicio.toIso8601String(),
      'propietario': propietario,
      'participantes': participantes,
      'tareas': tareas.map((t) => t.toJson()).toList(),
    };
  }

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    return Proyecto(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      fechaInicio: DateTime.parse(json['fechaInicio']),
      propietario: json['propietario'],
      participantes: List<String>.from(json['participantes'] ?? []),
      tareas: (json['tareas'] as List<dynamic>?)
              ?.map((tareaJson) => Tarea.fromJson(tareaJson))
              .toList() ?? [],
    );
  }
}

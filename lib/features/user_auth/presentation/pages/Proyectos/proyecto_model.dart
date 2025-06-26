import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'tarea_model.dart';
DateTime? _parseFecha(dynamic valor) {
  if (valor == null) return null;
  if (valor is Timestamp) return valor.toDate();
  if (valor is String) return DateTime.tryParse(valor);
  return null;
}

class Proyecto {
  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime? fechaFin;           // 🔹 Nuevo
  final DateTime? fechaCreacion;      // 🔹 Nuevo
  final DateTime? fechaActualizacion; // 🔹 Nuevo
  final String propietario;
  final List<String> participantes;
  final String visibilidad;
  final String? imagenUrl;
  final Map<String, List<String>> areas;
  final String estado;                // 🔹 Nuevo: "Activo", "Finalizado", etc.
  List<Tarea> tareas;

  Proyecto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fechaInicio,
    this.fechaFin,
    this.fechaCreacion,
    this.fechaActualizacion,
    required this.propietario,
    required this.participantes,
    this.visibilidad = "Privado",
    this.imagenUrl,
    this.tareas = const [],
    this.areas = const {},
    this.estado = "Activo",
  });

  Proyecto copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? propietario,
    List<String>? participantes,
    String? visibilidad,
    String? imagenUrl,
    List<Tarea>? tareas,
    Map<String, List<String>>? areas,
    String? estado,
  }) {
    return Proyecto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      propietario: propietario ?? this.propietario,
      participantes: participantes ?? this.participantes,
      visibilidad: visibilidad ?? this.visibilidad,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      tareas: tareas ?? this.tareas,
      areas: areas ?? this.areas,
      estado: estado ?? this.estado,
    );
  }

Map<String, dynamic> toJson() {
  return {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'fechaInicio': fechaInicio,  // ⬅️ sin .toIso8601String()
    'fechaFin': fechaFin,
    'fechaCreacion': fechaCreacion,
    'fechaActualizacion': fechaActualizacion,
    'propietario': propietario,
    'participantes': participantes,
    'visibilidad': visibilidad,
    'imagenUrl': imagenUrl,
    'tareas': tareas.map((t) => t.toJson()).toList(),
    'areas': areas,
    'estado': estado,
  };
}


factory Proyecto.fromJson(Map<String, dynamic> json) {
  return Proyecto(
    id: json['id'],
    nombre: json['nombre'],
    descripcion: json['descripcion'],
    fechaInicio: _parseFecha(json['fechaInicio'])!,
    fechaFin: _parseFecha(json['fechaFin']),
    fechaCreacion: _parseFecha(json['fechaCreacion']),
    fechaActualizacion: _parseFecha(json['fechaActualizacion']),
    propietario: json['propietario'],
    participantes: List<String>.from(json['participantes'] ?? []),
    visibilidad: json['visibilidad'] ?? "Privado",
    imagenUrl: json['imagenUrl'],
    tareas: (json['tareas'] as List<dynamic>?)?.map((t) => Tarea.fromJson(t)).toList() ?? [],
    areas: (json['areas'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, List<String>.from(value))) ?? {},
    estado: json['estado'] ?? "Activo",
  );
}

factory Proyecto.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return Proyecto.fromJson({...data, 'id': doc.id});
}

}

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'tarea_model.dart';

class Proyecto {
  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fechaInicio;
  final String propietario;
  final List<String> participantes;
  final String visibilidad; // "Publico" o "Privado"
  final String? imagenUrl;
  final Map<String, List<String>> areas;
  List<Tarea> tareas;

  Proyecto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fechaInicio,
    required this.propietario,
    required this.participantes,
    this.visibilidad = "Privado",
    this.imagenUrl,
    this.tareas = const [],
    this.areas = const {},
  });

  Proyecto copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    DateTime? fechaInicio,
    String? propietario,
    List<String>? participantes,
    String? visibilidad,
    String? imagenUrl,
    List<Tarea>? tareas,
    Map<String, List<String>>? areas,
  }) {
    return Proyecto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      propietario: propietario ?? this.propietario,
      participantes: participantes ?? this.participantes,
      visibilidad: visibilidad ?? this.visibilidad,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      tareas: tareas ?? this.tareas,
      areas: areas ?? this.areas,
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
      'visibilidad': visibilidad,
      'imagenUrl': imagenUrl,
      'tareas': tareas.map((t) => t.toJson()).toList(),
      'areas': areas,
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
      visibilidad: json['visibilidad'] ?? "Privado",
      imagenUrl: json['imagenUrl'],
      tareas: (json['tareas'] as List<dynamic>?)?.map((tareaJson) => Tarea.fromJson(tareaJson)).toList() ?? [],
      areas: (json['areas'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(key, List<String>.from(value))) ?? {},
    );
  }

  factory Proyecto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Proyecto(
      id: doc.id, // ✅ Este siempre funciona
      nombre: data['nombre'],
      descripcion: data['descripcion'],
      fechaInicio: DateTime.parse(data['fechaInicio']),
      propietario: data['propietario'],
      participantes: List<String>.from(data['participantes'] ?? []),
      visibilidad: data['visibilidad'] ?? "Privado",
      imagenUrl: data['imagenUrl'],
      tareas: (data['tareas'] as List<dynamic>?)?.map((t) => Tarea.fromJson(t)).toList() ?? [],
      areas: (data['areas'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(key, List<String>.from(value))) ?? {},
    );
  }

  /// Permite agregar o actualizar un área con una lista de participantes
  Proyecto actualizarArea(String nombreArea, List<String> nuevosParticipantes) {
    final nuevasAreas = Map<String, List<String>>.from(areas);
    nuevasAreas[nombreArea] = nuevosParticipantes;
    return copyWith(areas: nuevasAreas);
  }

  /// Permite eliminar un área del proyecto
  Proyecto eliminarArea(String nombreArea) {
    final nuevasAreas = Map<String, List<String>>.from(areas);
    nuevasAreas.remove(nombreArea);
    return copyWith(areas: nuevasAreas);
  }
} 

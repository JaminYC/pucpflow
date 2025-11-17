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

  // ========================================
  // 🆕 CAMPOS PMI (opcionales para retrocompatibilidad)
  // ========================================
  final bool esPMI;                        // Indica si el proyecto sigue metodología PMI
  final String? objetivo;                  // Objetivo del proyecto
  final String? alcance;                   // Alcance formal del proyecto
  final double? presupuesto;               // Presupuesto total planificado
  final double? costoActual;               // Costo actual acumulado
  final String? fasePMIActual;             // Fase actual: "Iniciación", "Planificación", etc.
  final List<String>? documentosIniciales; // URLs de documentos subidos (charter, etc.)
  final Map<String, dynamic>? metadatasPMI; // Metadata adicional flexible
  final Map<String, dynamic>? blueprintIA; // Nuevo: guardamos blueprint contextual

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
    // Campos PMI opcionales
    this.esPMI = false,
    this.objetivo,
    this.alcance,
    this.presupuesto,
    this.costoActual,
    this.fasePMIActual,
    this.documentosIniciales,
    this.metadatasPMI,
    this.blueprintIA,
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
    bool? esPMI,
    String? objetivo,
    String? alcance,
    double? presupuesto,
    double? costoActual,
    String? fasePMIActual,
    List<String>? documentosIniciales,
    Map<String, dynamic>? metadatasPMI,
    Map<String, dynamic>? blueprintIA,
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
      esPMI: esPMI ?? this.esPMI,
      objetivo: objetivo ?? this.objetivo,
      alcance: alcance ?? this.alcance,
      presupuesto: presupuesto ?? this.presupuesto,
      costoActual: costoActual ?? this.costoActual,
      fasePMIActual: fasePMIActual ?? this.fasePMIActual,
      documentosIniciales: documentosIniciales ?? this.documentosIniciales,
      metadatasPMI: metadatasPMI ?? this.metadatasPMI,
      blueprintIA: blueprintIA ?? this.blueprintIA,
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
    // Campos PMI
    'esPMI': esPMI,
    'objetivo': objetivo,
    'alcance': alcance,
    'presupuesto': presupuesto,
    'costoActual': costoActual,
    'fasePMIActual': fasePMIActual,
    'documentosIniciales': documentosIniciales,
    'metadatasPMI': metadatasPMI,
    'blueprintIA': blueprintIA,
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
    // Campos PMI con valores por defecto para retrocompatibilidad
    esPMI: json['esPMI'] ?? false,
    objetivo: json['objetivo'],
    alcance: json['alcance'],
    presupuesto: json['presupuesto']?.toDouble(),
    costoActual: json['costoActual']?.toDouble(),
    fasePMIActual: json['fasePMIActual'],
    documentosIniciales: json['documentosIniciales'] != null
        ? List<String>.from(json['documentosIniciales'])
        : null,
    metadatasPMI: json['metadatasPMI'],
    blueprintIA: json['blueprintIA'] != null
        ? Map<String, dynamic>.from(json['blueprintIA'])
        : null,
  );
}

factory Proyecto.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return Proyecto.fromJson({...data, 'id': doc.id});
}

}

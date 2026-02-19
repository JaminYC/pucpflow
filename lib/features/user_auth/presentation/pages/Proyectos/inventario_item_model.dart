import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Item de Inventario
/// Subcolección: proyectos/{proyectoId}/inventario/{itemId}
class InventarioItem {
  final String id;
  final String nombre;
  final String descripcion;
  final String tipo; // 'fisico' | 'digital'
  final String categoria; // 'material', 'equipo', 'herramienta', 'api', 'licencia', 'servidor', 'otro'
  final int cantidad;
  final String estado; // 'disponible' | 'pendiente' | 'adquirido'
  final double? costoEstimado;
  final String? proveedorFuente;
  final String? notas;
  final String? creadoPor;
  final DateTime fechaCreacion;

  InventarioItem({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    required this.tipo,
    this.categoria = 'otro',
    this.cantidad = 1,
    this.estado = 'pendiente',
    this.costoEstimado,
    this.proveedorFuente,
    this.notas,
    this.creadoPor,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'tipo': tipo,
      'categoria': categoria,
      'cantidad': cantidad,
      'estado': estado,
      'costoEstimado': costoEstimado,
      'proveedorFuente': proveedorFuente,
      'notas': notas,
      'creadoPor': creadoPor,
      'fechaCreacion': fechaCreacion,
    };
  }

  factory InventarioItem.fromJson(Map<String, dynamic> json, String id) {
    return InventarioItem(
      id: id,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      tipo: json['tipo'] ?? 'fisico',
      categoria: json['categoria'] ?? 'otro',
      cantidad: json['cantidad'] ?? 1,
      estado: json['estado'] ?? 'pendiente',
      costoEstimado: (json['costoEstimado'] as num?)?.toDouble(),
      proveedorFuente: json['proveedorFuente'],
      notas: json['notas'],
      creadoPor: json['creadoPor'],
      fechaCreacion: json['fechaCreacion'] != null
          ? (json['fechaCreacion'] is Timestamp
              ? (json['fechaCreacion'] as Timestamp).toDate()
              : DateTime.tryParse(json['fechaCreacion'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  factory InventarioItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventarioItem.fromJson(data, doc.id);
  }

  static Map<String, String> getCategoriasFisicas() {
    return {
      'material': 'Material',
      'equipo': 'Equipo',
      'herramienta': 'Herramienta',
      'otro': 'Otro',
    };
  }

  static Map<String, String> getCategoriasDigitales() {
    return {
      'api': 'API / Servicio',
      'licencia': 'Licencia',
      'servidor': 'Servidor / Hosting',
      'otro': 'Otro',
    };
  }

  static Map<String, String> getEstados() {
    return {
      'pendiente': 'Pendiente',
      'disponible': 'Disponible',
      'adquirido': 'Adquirido',
    };
  }
}

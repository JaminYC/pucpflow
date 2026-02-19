import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Recurso de Conocimiento
/// Subcolección: proyectos/{proyectoId}/repositorio_conocimiento/{recursoId}
class RecursoConocimiento {
  final String id;
  final String titulo;
  final String? url;
  final String? urlArchivo; // URL de Firebase Storage si es archivo subido
  final String tipo; // 'paper', 'video', 'tutorial', 'documento', 'imagen', 'otro'
  final String? descripcion;
  final List<String> tags;
  final String? categoriaIA; // Categoría asignada automáticamente por IA
  final String? nombreArchivo; // Nombre original del archivo subido
  final String? creadoPor;
  final DateTime fechaCreacion;

  RecursoConocimiento({
    required this.id,
    required this.titulo,
    this.url,
    this.urlArchivo,
    this.tipo = 'otro',
    this.descripcion,
    this.tags = const [],
    this.categoriaIA,
    this.nombreArchivo,
    this.creadoPor,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'url': url,
      'urlArchivo': urlArchivo,
      'tipo': tipo,
      'descripcion': descripcion,
      'tags': tags,
      'categoriaIA': categoriaIA,
      'nombreArchivo': nombreArchivo,
      'creadoPor': creadoPor,
      'fechaCreacion': fechaCreacion,
    };
  }

  factory RecursoConocimiento.fromJson(Map<String, dynamic> json, String id) {
    return RecursoConocimiento(
      id: id,
      titulo: json['titulo'] ?? '',
      url: json['url'],
      urlArchivo: json['urlArchivo'],
      tipo: json['tipo'] ?? 'otro',
      descripcion: json['descripcion'],
      tags: List<String>.from(json['tags'] ?? []),
      categoriaIA: json['categoriaIA'],
      nombreArchivo: json['nombreArchivo'],
      creadoPor: json['creadoPor'],
      fechaCreacion: json['fechaCreacion'] != null
          ? (json['fechaCreacion'] is Timestamp
              ? (json['fechaCreacion'] as Timestamp).toDate()
              : DateTime.tryParse(json['fechaCreacion'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  factory RecursoConocimiento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecursoConocimiento.fromJson(data, doc.id);
  }

  /// Verifica si la URL es de YouTube
  bool get esYoutube {
    if (url == null) return false;
    final u = url!.toLowerCase();
    return u.contains('youtube.com') || u.contains('youtu.be');
  }

  /// Extrae el ID del video de YouTube de la URL
  String? get youtubeVideoId {
    if (url == null) return null;
    final uri = Uri.tryParse(url!);
    if (uri == null) return null;

    // youtube.com/watch?v=VIDEO_ID
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }
    // youtu.be/VIDEO_ID
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    return null;
  }

  static Map<String, String> getTipos() {
    return {
      'paper': 'Paper / Artículo',
      'video': 'Video',
      'tutorial': 'Tutorial',
      'documento': 'Documento',
      'imagen': 'Imagen',
      'otro': 'Otro',
    };
  }
}

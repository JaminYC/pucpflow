import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/recurso_conocimiento_model.dart';

class RepositorioConocimientoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Referencia a la subcolección de repositorio de conocimiento
  CollectionReference _repoRef(String proyectoId) {
    return _firestore
        .collection('proyectos')
        .doc(proyectoId)
        .collection('repositorio_conocimiento');
  }

  /// Stream reactivo de recursos
  Stream<List<RecursoConocimiento>> streamRecursos(String proyectoId) {
    return _repoRef(proyectoId)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecursoConocimiento.fromFirestore(doc))
            .toList());
  }

  /// Agregar un recurso (link externo)
  Future<void> agregarRecurso(String proyectoId, RecursoConocimiento recurso) async {
    await _repoRef(proyectoId).add(recurso.toJson());
  }

  /// Subir archivo a Storage y crear recurso
  Future<void> subirArchivoYCrearRecurso({
    required String proyectoId,
    required String titulo,
    required String nombreArchivo,
    required Uint8List bytes,
    required String contentType,
    String? creadoPor,
  }) async {
    // Subir a Firebase Storage
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('proyectos/$proyectoId/repositorio/${timestamp}_$nombreArchivo');
    final metadata = SettableMetadata(contentType: contentType);
    final uploadTask = ref.putData(bytes, metadata);
    final snapshot = await uploadTask.whenComplete(() {});
    final urlArchivo = await snapshot.ref.getDownloadURL();

    // Intentar categorizar con IA
    String tipo = 'otro';
    List<String> tags = [];
    String? categoriaIA;

    try {
      final resultado = await categorizarConIA(
        titulo: titulo,
        nombreArchivo: nombreArchivo,
      );
      tipo = resultado['tipo'] ?? 'otro';
      tags = List<String>.from(resultado['tags'] ?? []);
      categoriaIA = resultado['categoria'];
    } catch (e) {
      // Si falla la IA, inferir tipo por extensión
      tipo = _inferirTipoPorExtension(nombreArchivo);
    }

    final recurso = RecursoConocimiento(
      id: '',
      titulo: titulo,
      urlArchivo: urlArchivo,
      tipo: tipo,
      tags: tags,
      categoriaIA: categoriaIA,
      nombreArchivo: nombreArchivo,
      creadoPor: creadoPor,
      fechaCreacion: DateTime.now(),
    );

    await _repoRef(proyectoId).add(recurso.toJson());
  }

  /// Categorizar recurso usando Cloud Function con IA
  Future<Map<String, dynamic>> categorizarConIA({
    required String titulo,
    String? url,
    String? nombreArchivo,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('categorizarRecurso');
    final result = await callable.call({
      'titulo': titulo,
      'url': url,
      'nombreArchivo': nombreArchivo,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Eliminar recurso (y archivo de Storage si existe)
  Future<void> eliminarRecurso(String proyectoId, RecursoConocimiento recurso) async {
    // Eliminar archivo de Storage si existe
    if (recurso.urlArchivo != null) {
      try {
        final ref = _storage.refFromURL(recurso.urlArchivo!);
        await ref.delete();
      } catch (e) {
        // Ignorar si el archivo ya no existe
      }
    }

    await _repoRef(proyectoId).doc(recurso.id).delete();
  }

  /// Actualizar recurso
  Future<void> actualizarRecurso(String proyectoId, String recursoId, Map<String, dynamic> datos) async {
    await _repoRef(proyectoId).doc(recursoId).update(datos);
  }

  /// Inferir tipo de recurso por extensión del archivo
  String _inferirTipoPorExtension(String nombreArchivo) {
    final ext = nombreArchivo.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'txt':
        return 'documento';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return 'imagen';
      case 'mp4':
      case 'avi':
      case 'mov':
        return 'video';
      default:
        return 'otro';
    }
  }
}

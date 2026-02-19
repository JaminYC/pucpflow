import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/inventario_item_model.dart';

class InventarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referencia a la subcolección de inventario de un proyecto
  CollectionReference _inventarioRef(String proyectoId) {
    return _firestore
        .collection('proyectos')
        .doc(proyectoId)
        .collection('inventario');
  }

  /// Stream reactivo de items del inventario
  Stream<List<InventarioItem>> streamInventario(String proyectoId) {
    return _inventarioRef(proyectoId)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventarioItem.fromFirestore(doc))
            .toList());
  }

  /// Agregar un item al inventario
  Future<void> agregarItem(String proyectoId, InventarioItem item) async {
    await _inventarioRef(proyectoId).add(item.toJson());
  }

  /// Actualizar un item del inventario
  Future<void> actualizarItem(String proyectoId, String itemId, Map<String, dynamic> datos) async {
    await _inventarioRef(proyectoId).doc(itemId).update(datos);
  }

  /// Eliminar un item del inventario
  Future<void> eliminarItem(String proyectoId, String itemId) async {
    await _inventarioRef(proyectoId).doc(itemId).delete();
  }

  /// Calcular costo total estimado del inventario
  Future<double> calcularCostoTotal(String proyectoId) async {
    final snapshot = await _inventarioRef(proyectoId).get();
    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final costo = (data['costoEstimado'] as num?)?.toDouble() ?? 0;
      final cantidad = (data['cantidad'] as num?)?.toInt() ?? 1;
      total += costo * cantidad;
    }
    return total;
  }

  /// Importar items desde imagen (foto de tabla) usando IA con visión
  Future<List<Map<String, dynamic>>> importarDesdeImagen({
    required Uint8List imageBytes,
    String? contextoProyecto,
  }) async {
    final base64Image = base64Encode(imageBytes);
    final callable = FirebaseFunctions.instance.httpsCallable(
      'parsearInventarioDesdeImagen',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );

    final result = await callable.call({
      'imagenBase64': base64Image,
      'contextoProyecto': contextoProyecto,
    });

    final data = Map<String, dynamic>.from(result.data);
    if (data['success'] == true && data['items'] != null) {
      return List<Map<String, dynamic>>.from(
        (data['items'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }
    return [];
  }

  /// Importar items desde texto (copiar-pegar tabla)
  Future<List<Map<String, dynamic>>> importarDesdeTexto({
    required String textoTabla,
    String? contextoProyecto,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'parsearInventarioDesdeImagen',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call({
      'textoTabla': textoTabla,
      'contextoProyecto': contextoProyecto,
    });

    final data = Map<String, dynamic>.from(result.data);
    if (data['success'] == true && data['items'] != null) {
      return List<Map<String, dynamic>>.from(
        (data['items'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }
    return [];
  }

  /// Guardar items parseados por IA en Firestore
  Future<int> guardarItemsParseados({
    required String proyectoId,
    required List<Map<String, dynamic>> items,
    String? creadoPor,
  }) async {
    int count = 0;
    final batch = _firestore.batch();

    for (var itemData in items) {
      final item = InventarioItem(
        id: '',
        nombre: itemData['nombre'] ?? 'Item sin nombre',
        descripcion: itemData['descripcion'] ?? '',
        tipo: itemData['tipo'] ?? 'fisico',
        categoria: itemData['categoria'] ?? 'otro',
        cantidad: (itemData['cantidad'] as num?)?.toInt() ?? 1,
        estado: itemData['estado'] ?? 'pendiente',
        costoEstimado: (itemData['costoEstimado'] as num?)?.toDouble(),
        proveedorFuente: itemData['proveedorFuente'],
        creadoPor: creadoPor,
        fechaCreacion: DateTime.now(),
      );

      final docRef = _inventarioRef(proyectoId).doc();
      batch.set(docRef, item.toJson());
      count++;
    }

    await batch.commit();
    return count;
  }

  /// Exportar inventario a CSV
  String exportarACSV(List<InventarioItem> items) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Nombre,Tipo,Categoría,Cantidad,Estado,Costo Estimado,Subtotal,Proveedor/Fuente,Descripción,Notas');

    // Rows
    for (var item in items) {
      final subtotal = (item.costoEstimado ?? 0) * item.cantidad;
      buffer.writeln(
        '"${_escapeCsv(item.nombre)}",'
        '"${item.tipo}",'
        '"${item.categoria}",'
        '${item.cantidad},'
        '"${InventarioItem.getEstados()[item.estado] ?? item.estado}",'
        '${item.costoEstimado ?? ""},'
        '$subtotal,'
        '"${_escapeCsv(item.proveedorFuente ?? "")}",'
        '"${_escapeCsv(item.descripcion ?? "")}",'
        '"${_escapeCsv(item.notas ?? "")}"',
      );
    }

    // Total row
    double total = 0;
    for (var item in items) {
      total += (item.costoEstimado ?? 0) * item.cantidad;
    }
    buffer.writeln(',,,,,,${total.toStringAsFixed(2)},,,');

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    return value.replaceAll('"', '""').replaceAll('\n', ' ');
  }
}

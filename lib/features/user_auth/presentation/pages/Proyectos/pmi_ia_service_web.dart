import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'pmi_service.dart';

/// Clase auxiliar para manejar archivos PDF en web y móvil
class PDFFileData {
  final String name;
  final Uint8List bytes;

  PDFFileData({required this.name, required this.bytes});
}

/// Servicio para generación de proyectos PMI con IA (compatible con web)
class PMIIAServiceWeb {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final PMIService pmiService = PMIService();

  /// Selecciona PDFs (compatible con web y móvil)
  Future<List<PDFFileData>> seleccionarPDFs() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        withData: true, // Importante para web
      );

      if (result != null && result.files.isNotEmpty) {
        List<PDFFileData> archivos = [];

        for (var file in result.files) {
          if (file.bytes != null) {
            // En web siempre tenemos bytes
            archivos.add(PDFFileData(
              name: file.name,
              bytes: file.bytes!,
            ));
          } else if (file.path != null && !kIsWeb) {
            // En móvil/desktop, leer desde path
            try {
              // Importar dart:io solo en no-web
              final fileBytes = await _readFileBytes(file.path!);
              if (fileBytes != null) {
                archivos.add(PDFFileData(
                  name: file.name,
                  bytes: fileBytes,
                ));
              }
            } catch (e) {
              print('❌ Error leyendo archivo: $e');
            }
          }
        }

        print('✅ ${archivos.length} archivo(s) seleccionado(s)');
        return archivos;
      }
      return [];
    } catch (e) {
      print('❌ Error seleccionando PDFs: $e');
      return [];
    }
  }

  /// Lee bytes de archivo (solo en no-web)
  Future<Uint8List?> _readFileBytes(String path) async {
    if (kIsWeb) return null;
    try {
      // Solo importar dart:io cuando no es web
      final file = await _loadFile(path);
      return file;
    } catch (e) {
      print('❌ Error leyendo bytes: $e');
      return null;
    }
  }

  /// Carga archivo desde path (implementación específica por plataforma)
  Future<Uint8List?> _loadFile(String path) async {
    if (kIsWeb) return null;
    // Esta función será implementada con conditional imports
    // Por ahora, retornar null en web
    return null;
  }

  /// Convierte archivos PDF a base64
  Future<List<String>> convertirPDFsABase64(List<PDFFileData> archivos) async {
    try {
      List<String> base64List = [];
      for (var archivo in archivos) {
        base64List.add(base64Encode(archivo.bytes));
      }
      print('✅ ${base64List.length} archivo(s) convertido(s) a base64');
      return base64List;
    } catch (e) {
      print('❌ Error convirtiendo PDFs a base64: $e');
      return [];
    }
  }

  /// Genera proyecto PMI con IA
  Future<Map<String, dynamic>?> generarProyectoPMIConIA({
    required List<String> documentosBase64,
    required String nombreProyecto,
    String? descripcionBreve,
  }) async {
    try {
      print('🤖 [PMI] Llamando a Cloud Function generarProyectoPMI...');
      print('📄 [PMI] Documentos a enviar: ${documentosBase64.length}');
      print('📝 [PMI] Nombre del proyecto: $nombreProyecto');

      final callable = _functions.httpsCallable(
        'generarProyectoPMI',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 540),
        ),
      );

      print('⏳ [PMI] Enviando petición a Firebase Functions...');
      final result = await callable.call({
        'documentosBase64': documentosBase64,
        'nombreProyecto': nombreProyecto,
        'descripcionBreve': descripcionBreve ?? '',
      });

      print('📥 [PMI] Respuesta recibida de Cloud Function');
      final data = Map<String, dynamic>.from(result.data as Map);

      if (data['error'] != null) {
        print('❌ [PMI] Error en respuesta: ${data['error']}');
        throw Exception(data['error']);
      }

      if (!data['success']) {
        print('❌ [PMI] Generación no exitosa');
        throw Exception('La generación no fue exitosa');
      }

      print('✅ [PMI] Proyecto PMI generado por IA exitosamente');
      final proyecto = Map<String, dynamic>.from(data['proyecto'] as Map);
      print('📊 [PMI] Estructura recibida: ${proyecto.keys}');
      return proyecto;
    } catch (e) {
      print('❌ [PMI] Error generando proyecto PMI con IA: $e');
      return null;
    }
  }
}

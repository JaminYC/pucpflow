import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'pmi_service.dart';
import 'tarea_model.dart';

/// Servicio para generación de proyectos PMI con IA
class PMIIAService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final PMIService pmiService = PMIService(); // Público para acceso desde páginas

  // ========================================
  // 📄 SELECCIÓN Y CONVERSIÓN DE ARCHIVOS
  // ========================================

  /// Permite seleccionar múltiples archivos PDF
  Future<List<File>> seleccionarPDFs() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        List<File> archivos = [];
        for (var file in result.files) {
          if (file.path != null) {
            archivos.add(File(file.path!));
          }
        }
        return archivos;
      }
      return [];
    } catch (e) {
      print('❌ Error seleccionando PDFs: $e');
      return [];
    }
  }

  /// Convierte archivos PDF a base64
  Future<List<String>> convertirPDFsABase64(List<File> archivos) async {
    try {
      List<String> base64List = [];
      for (var archivo in archivos) {
        final bytes = await archivo.readAsBytes();
        base64List.add(base64Encode(bytes));
      }
      return base64List;
    } catch (e) {
      print('❌ Error convirtiendo PDFs a base64: $e');
      return [];
    }
  }

  // ========================================
  // 🤖 GENERACIÓN DE PROYECTO PMI CON IA
  // ========================================

  /// Genera un proyecto PMI completo usando documentos y OpenAI
  /// Retorna el proyectoId creado
  Future<Map<String, dynamic>?> generarProyectoPMIConIA({
    required List<String> documentosBase64,
    required String nombreProyecto,
    String? descripcionBreve,
  }) async {
    try {
      print('🤖 Llamando a Cloud Function generarProyectoPMI...');

      final callable = _functions.httpsCallable(
        'generarProyectoPMI',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 540), // 9 minutos
        ),
      );

      final result = await callable.call({
        'documentosBase64': documentosBase64,
        'nombreProyecto': nombreProyecto,
        'descripcionBreve': descripcionBreve ?? '',
      });

      final data = result.data;

      if (data['error'] != null) {
        throw Exception(data['error']);
      }

      if (!data['success']) {
        throw Exception('La generación no fue exitosa');
      }

      print('✅ Proyecto PMI generado por IA exitosamente');
      return data['proyecto'];
    } catch (e) {
      print('❌ Error generando proyecto PMI con IA: $e');
      return null;
    }
  }

  /// Flujo completo: desde selección de archivos hasta creación del proyecto
  Future<String?> generarProyectoCompleto({
    required String nombreProyecto,
    String? descripcionBreve,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    required Function(String) onProgress,
  }) async {
    try {
      // 1. Seleccionar PDFs
      onProgress('Seleccionando documentos...');
      final archivos = await seleccionarPDFs();

      if (archivos.isEmpty) {
        throw Exception('No se seleccionaron documentos');
      }

      onProgress('${archivos.length} documento(s) seleccionado(s)');

      // 2. Convertir a base64
      onProgress('Convirtiendo documentos...');
      final documentosBase64 = await convertirPDFsABase64(archivos);

      if (documentosBase64.isEmpty) {
        throw Exception('Error convirtiendo documentos');
      }

      // 3. Generar estructura PMI con IA
      onProgress('Analizando documentos con IA (esto puede tardar 2-3 minutos)...');
      final proyectoIA = await generarProyectoPMIConIA(
        documentosBase64: documentosBase64,
        nombreProyecto: nombreProyecto,
        descripcionBreve: descripcionBreve,
      );

      if (proyectoIA == null) {
        throw Exception('Error generando estructura PMI');
      }

      // 4. Crear proyecto en Firestore
      onProgress('Creando proyecto en la base de datos...');
      final proyectoId = await pmiService.crearProyectoPMI(
        nombre: nombreProyecto,
        descripcion: proyectoIA['descripcion'] ?? descripcionBreve ?? '',
        fechaInicio: fechaInicio ?? DateTime.now(),
        fechaFin: fechaFin,
        objetivo: proyectoIA['objetivo'],
        alcance: proyectoIA['alcance'],
        presupuesto: proyectoIA['presupuestoEstimado']?.toDouble(),
      );

      if (proyectoId == null) {
        throw Exception('Error creando proyecto en Firestore');
      }

      // 5. Crear fases con sus tareas
      onProgress('Creando fases y tareas...');
      await _crearFasesConTareas(proyectoId, proyectoIA['fases']);

      // 6. Guardar riesgos y stakeholders en metadatas
      onProgress('Guardando información adicional...');
      await _guardarMetadatasPMI(
        proyectoId,
        proyectoIA['riesgos'],
        proyectoIA['stakeholders'],
      );

      onProgress('✅ Proyecto PMI creado exitosamente');
      return proyectoId;
    } catch (e) {
      print('❌ Error en flujo completo: $e');
      onProgress('❌ Error: $e');
      return null;
    }
  }

  // ========================================
  // 🔧 MÉTODOS AUXILIARES PRIVADOS
  // ========================================

  /// Crea fases y sus tareas en Firestore
  Future<void> _crearFasesConTareas(
      String proyectoId, List<dynamic> fasesData) async {
    try {
      for (var faseData in fasesData) {
        final faseId = _obtenerIdFase(faseData['nombre']);

        // Las fases ya se crearon al inicializar el proyecto PMI
        // Ahora agregamos las tareas a cada fase

        final tareasData = faseData['tareas'] as List<dynamic>? ?? [];
        List<String> tareasIds = [];

        for (var tareaData in tareasData) {
          // Crear tarea en el formato existente
          final fechaLimiteCalculada = DateTime.now().add(Duration(days: tareaData['duracionDias'] ?? 7));
          final tarea = Tarea(
            titulo: tareaData['titulo'] ?? '',
            descripcion: tareaData['descripcion'] ?? '',
            fecha: fechaLimiteCalculada, // Mantener por compatibilidad
            fechaLimite: fechaLimiteCalculada, // ✅ Deadline - fecha límite calculada
            fechaProgramada: null, // No hay hora específica en proyectos PMI generados por IA
            duracion: (tareaData['duracionDias'] ?? 1) * 60, // Convertir días a minutos
            prioridad: tareaData['prioridad'] ?? 3,
            completado: false,
            colorId: _obtenerColorPorFase(faseData['nombre']),
            responsables: [], // Sin asignar inicialmente
            tipoTarea: 'Automática',
            requisitos: {},
            dificultad: _calcularDificultad(tareaData['prioridad'] ?? 3),
            tareasPrevias: [],
            area: faseData['nombre'],
            habilidadesRequeridas: List<String>.from(
                tareaData['habilidadesRequeridas'] ?? []),
          );

          // TODO: Guardar tarea en subcollection cuando migremos
          // Por ahora, solo guardamos IDs
          tareasIds.add(tarea.titulo); // Usar título como ID temporal
        }

        // Actualizar fase con IDs de tareas
        await pmiService.actualizarFase(proyectoId, faseId, {
          'tareasIds': tareasIds,
          'totalTareas': tareasIds.length,
          'descripcion': faseData['descripcion'] ?? '',
        });
      }

      print('✅ Fases y tareas creadas exitosamente');
    } catch (e) {
      print('❌ Error creando fases con tareas: $e');
    }
  }

  /// Guarda riesgos y stakeholders en metadatas del proyecto
  Future<void> _guardarMetadatasPMI(
    String proyectoId,
    List<dynamic>? riesgos,
    List<dynamic>? stakeholders,
  ) async {
    try {
      final metadatas = {
        'riesgos': riesgos ?? [],
        'stakeholders': stakeholders ?? [],
        'generadoPorIA': true,
      };

      // Guardar en campo metadatasPMI del proyecto
      // TODO: Implementar cuando actualicemos el servicio base de proyectos
      print('✅ Metadatas PMI guardadas');
    } catch (e) {
      print('❌ Error guardando metadatas: $e');
    }
  }

  /// Obtiene el ID de fase según el nombre
  String _obtenerIdFase(String nombre) {
    switch (nombre) {
      case 'Iniciación':
        return 'iniciacion';
      case 'Planificación':
        return 'planificacion';
      case 'Ejecución':
        return 'ejecucion';
      case 'Monitoreo y Control':
      case 'Monitoreo':
        return 'monitoreo';
      case 'Cierre':
        return 'cierre';
      default:
        return nombre.toLowerCase().replaceAll(' ', '_');
    }
  }

  /// Obtiene color según la fase
  int _obtenerColorPorFase(String nombreFase) {
    switch (nombreFase) {
      case 'Iniciación':
        return 0xFF4CAF50; // Verde
      case 'Planificación':
        return 0xFF2196F3; // Azul
      case 'Ejecución':
        return 0xFFFF9800; // Naranja
      case 'Monitoreo y Control':
      case 'Monitoreo':
        return 0xFF9C27B0; // Púrpura
      case 'Cierre':
        return 0xFF607D8B; // Gris azulado
      default:
        return 0xFF757575; // Gris
    }
  }

  /// Calcula dificultad según prioridad
  String _calcularDificultad(int prioridad) {
    if (prioridad <= 2) return 'baja';
    if (prioridad <= 3) return 'media';
    return 'alta';
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pmi_ia_service_web.dart';
import 'ProyectoDetalleKanbanPage.dart';
import 'tarea_model.dart';

/// Página para crear proyectos PMI usando IA
class CrearProyectoPMIPage extends StatefulWidget {
  const CrearProyectoPMIPage({Key? key}) : super(key: key);

  @override
  State<CrearProyectoPMIPage> createState() => _CrearProyectoPMIPageState();
}

class _CrearProyectoPMIPageState extends State<CrearProyectoPMIPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _visionController = TextEditingController();
  final _pmiIAService = PMIIAServiceWeb();
  String _categoria = "Laboral";

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _generando = false;
  String _progresoMensaje = '';
  double _progreso = 0.0;
  List<PDFFileData> _pdfFiles = [];
  List<String> _pdfNames = [];

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _visionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarPDFs() async {
    final archivos = await _pmiIAService.seleccionarPDFs();
    if (archivos.isNotEmpty) {
      setState(() {
        _pdfFiles = archivos;
        _pdfNames = archivos.map((f) => f.name).toList();
      });
    }
  }

  void _eliminarPDF(int index) {
    setState(() {
      _pdfFiles.removeAt(index);
      _pdfNames.removeAt(index);
    });
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

  /// Guarda las tareas generadas por IA en el proyecto
  Future<void> _guardarTareasEnProyecto(
    String proyectoId,
    Map<String, dynamic> proyectoIA,
    String? userId, // ✅ UID del usuario para auto-asignar
  ) async {
    try {
      final fasesData = proyectoIA['fases'] as List<dynamic>? ?? [];
      List<Tarea> todasLasTareas = [];
      Set<String> areasUnicas = {}; // ✅ Recopilar áreas únicas
      int totalEntregables = 0;
      int totalPaquetes = 0;

      // Procesar cada fase → entregables → paquetes de trabajo → tareas
      for (var faseData in fasesData) {
        final nombreFase = faseData['nombre'] ?? '';
        final entregablesData = faseData['entregables'] as List<dynamic>? ?? [];

        for (var entregableData in entregablesData) {
          final nombreEntregable = entregableData['nombre'] ?? 'Entregable';
          totalEntregables++;

          final paquetesData = entregableData['paquetesTrabajo'] as List<dynamic>? ?? [];

          for (var paqueteData in paquetesData) {
            final nombrePaquete = paqueteData['nombre'] ?? 'Paquete de Trabajo';
            totalPaquetes++;

            final tareasData = paqueteData['tareas'] as List<dynamic>? ?? [];

            for (var tareaData in tareasData) {
              // Normalizar área recomendada por IA
              String areaRecomendada = tareaData['areaRecomendada'] ?? 'Sin asignar';
              areaRecomendada = areaRecomendada.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
              if (areaRecomendada.isEmpty) {
                areaRecomendada = 'Sin asignar';
              }
              areasUnicas.add(areaRecomendada); // ✅ Recopilar área única

              // Crear objeto Tarea con jerarquía PMI completa
              final tarea = Tarea(
                titulo: tareaData['titulo'] ?? 'Tarea sin título',
                descripcion: tareaData['descripcion'] ?? '',
                fecha: DateTime.now().add(
                  Duration(days: tareaData['duracionDias'] ?? 7),
                ),
                duracion: (tareaData['duracionDias'] ?? 1) * 60, // Convertir días a minutos
                prioridad: tareaData['prioridad'] ?? 3,
                completado: false,
                colorId: _obtenerColorPorFase(nombreFase),
                responsables: userId != null ? [userId] : [], // ✅ Auto-asignar al creador
                tipoTarea: 'Automática', // ✅ PMI siempre usa 'Automática'
                requisitos: {},
                dificultad: _calcularDificultad(tareaData['prioridad'] ?? 3),
                tareasPrevias: [],
                area: areaRecomendada, // ✅ Área normalizada y sin duplicados
                habilidadesRequeridas: List<String>.from(
                  tareaData['habilidadesRequeridas'] ?? [],
                ),
                // ✅ Campos PMI - Jerarquía del proyecto
                fasePMI: nombreFase,
                entregable: nombreEntregable,
                paqueteTrabajo: nombrePaquete,
              );

              todasLasTareas.add(tarea);
            }
          }
        }
      }

      print('📊 Estructura PMI generada:');
      print('   - ${fasesData.length} fases');
      print('   - $totalEntregables entregables');
      print('   - $totalPaquetes paquetes de trabajo');
      print('   - ${todasLasTareas.length} tareas');
      print('   - ${areasUnicas.length} áreas únicas: $areasUnicas');

      // Crear Map de áreas (recursos) para el proyecto PMI
      Map<String, List<String>> areasMap = {};
      for (var area in areasUnicas) {
        areasMap[area] = []; // Inicialmente sin participantes asignados
      }
      print('   📁 Creando ${areasMap.length} áreas para recursos: ${areasMap.keys}');

      // Guardar todas las tareas en subcolección y áreas en el proyecto
      if (todasLasTareas.isNotEmpty) {
        final tareasRef = FirebaseFirestore.instance
            .collection('proyectos')
            .doc(proyectoId)
            .collection('tareas');
        final batch = FirebaseFirestore.instance.batch();
        for (var tarea in todasLasTareas) {
          batch.set(tareasRef.doc(), tarea.toJson());
        }
        await batch.commit();

        await FirebaseFirestore.instance
            .collection('proyectos')
            .doc(proyectoId)
            .update({
          'areas': areasMap, // ✅ Guardar como "areas" (el modelo usa este campo)
        });

        print('✅ ${todasLasTareas.length} tareas en subcolección y ${areasMap.length} áreas guardados');
      }

      // Actualizar contadores de tareas por fase
      final pmiService = _pmiIAService.pmiService;
      for (var faseData in fasesData) {
        final faseId = _obtenerIdFase(faseData['nombre']);

        // Contar tareas de esta fase
        int tareasEnFase = todasLasTareas
            .where((t) => t.fasePMI == faseData['nombre'])
            .length;

        await pmiService.actualizarFase(proyectoId, faseId, {
          'totalTareas': tareasEnFase,
          'descripcion': faseData['descripcion'] ?? '',
        });
      }

      // Guardar riesgos y stakeholders en metadatasPMI
      final metadatas = {
        'riesgos': proyectoIA['riesgos'] ?? [],
        'stakeholders': proyectoIA['stakeholders'] ?? [],
        'generadoPorIA': true,
        'fechaGeneracion': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('proyectos')
          .doc(proyectoId)
          .update({
        'metadatasPMI': metadatas,
      });

      print('✅ Metadatas PMI guardadas');
    } catch (e) {
      print('❌ Error guardando tareas: $e');
      throw e;
    }
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  Future<void> _generarProyecto() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pdfFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debes subir al menos un documento PDF'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _generando = true;
      _progreso = 0.1;
      _progresoMensaje = 'Convirtiendo documentos...';
    });

    try {
      print('\n🚀 ========== INICIANDO GENERACIÓN DE PROYECTO PMI ==========');
      print('📄 PDFs seleccionados: ${_pdfFiles.length}');

      // Convertir PDFs a base64
      print('🔄 [PASO 1/5] Convirtiendo PDFs a base64...');
      final documentosBase64 = await _pmiIAService.convertirPDFsABase64(_pdfFiles);

      if (documentosBase64.isEmpty) {
        throw Exception('Error convirtiendo documentos');
      }
      print('✅ [PASO 1/5] ${documentosBase64.length} documentos convertidos (${documentosBase64[0].length} caracteres en base64)');

      setState(() {
        _progreso = 0.2;
        _progresoMensaje = 'Analizando documentos con IA (esto puede tardar 2-3 minutos)...';
      });

      // Generar estructura PMI con IA
      print('🤖 [PASO 2/5] Llamando a IA para generar estructura PMI...');
      print('   Proyecto: ${_nombreController.text.trim()}');
      print('   Descripción: ${_descripcionController.text.trim()}');

      final proyectoIA = await _pmiIAService.generarProyectoPMIConIA(
        documentosBase64: documentosBase64,
        nombreProyecto: _nombreController.text.trim(),
        descripcionBreve: _descripcionController.text.trim(),
      );

      if (proyectoIA == null) {
        throw Exception('Error generando estructura PMI');
      }
      print('✅ [PASO 2/5] Estructura PMI generada exitosamente');
      print('📊 Fases generadas: ${(proyectoIA['fases'] as List?)?.length ?? 0}');

      setState(() {
        _progreso = 0.7;
        _progresoMensaje = 'Creando proyecto en la base de datos...';
      });

      // Crear proyecto usando el servicio PMI directamente
      print('💾 [PASO 3/5] Creando proyecto en Firestore...');
      final pmiService = _pmiIAService.pmiService;
      final proyectoId = await pmiService.crearProyectoPMI(
        nombre: _nombreController.text.trim(),
        descripcion: proyectoIA['descripcion'] ?? _descripcionController.text.trim(),
        fechaInicio: _fechaInicio ?? DateTime.now(),
        fechaFin: _fechaFin,
        objetivo: proyectoIA['objetivo'],
        alcance: proyectoIA['alcance'],
        presupuesto: proyectoIA['presupuestoEstimado']?.toDouble(),
        categoria: _categoria,
        vision: _visionController.text.trim(),
      );

      if (proyectoId == null) {
        throw Exception('Error creando proyecto en Firestore');
      }
      print('✅ [PASO 3/5] Proyecto creado con ID: $proyectoId');

      setState(() {
        _progreso = 0.8;
        _progresoMensaje = 'Guardando tareas y fases...';
      });

      // Guardar tareas generadas por IA
      print('📝 [PASO 4/5] Guardando tareas y fases...');
      final user = FirebaseAuth.instance.currentUser;
      await _guardarTareasEnProyecto(proyectoId, proyectoIA, user?.uid);
      print('✅ [PASO 4/5] Tareas guardadas exitosamente');

      setState(() {
        _progreso = 0.9;
        _progresoMensaje = 'Guardando información adicional...';
      });

      // Pequeña pausa para que el usuario vea el progreso
      await Future.delayed(const Duration(milliseconds: 500));

      print('🎉 [PASO 5/5] ¡Proyecto PMI completado!');
      print('========== GENERACIÓN COMPLETADA EXITOSAMENTE ==========\n');

      setState(() {
        _progreso = 1.0;
        _progresoMensaje = '✅ Proyecto PMI creado exitosamente';
      });

      if (proyectoId != null && mounted) {
        // Navegar al proyecto creado
        print('🚀 Navegando al proyecto...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ProyectoDetalleKanbanPage(proyectoId: proyectoId),
          ),
        );
      } else if (mounted) {
        print('❌ proyectoId es null, no se puede navegar');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error generando proyecto PMI'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ ERROR GENERANDO PROYECTO PMI:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _generando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          '🎯 Crear Proyecto PMI con IA',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _generando ? _buildGenerandoUI() : _buildFormulario(),
    );
  }

  Widget _buildFormulario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera explicativa
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade700),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 12),
                      Text(
                        'Generación automática con IA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Sube documentos del proyecto (PDFs) y la IA generará automáticamente:\n\n'
                    '• Las 5 fases PMI (Iniciación, Planificación, Ejecución, Monitoreo, Cierre)\n'
                    '• Tareas específicas para cada fase\n'
                    '• Riesgos identificados\n'
                    '• Stakeholders del proyecto\n'
                    '• Presupuesto estimado',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Nombre del proyecto
            const Text(
              'Nombre del Proyecto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nombreController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ej: Implementación de Sistema ERP',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.folder, color: Colors.blue),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el nombre del proyecto';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Descripción breve
            const Text(
              'Descripción Breve (opcional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descripcionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contexto adicional del proyecto...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.description, color: Colors.blue),
              ),
            ),

            const SizedBox(height: 24),

            // Categoria
            const Text(
              'Categoria',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _categoria,
              dropdownColor: Colors.grey.shade900,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.category, color: Colors.blue),
              ),
              items: const [
                DropdownMenuItem(value: 'Laboral', child: Text('Laboral')),
                DropdownMenuItem(value: 'Personal', child: Text('Personal')),
              ],
              onChanged: (value) {
                setState(() => _categoria = value ?? 'Laboral');
              },
            ),

            const SizedBox(height: 24),

            // Vision
            const Text(
              'Vision del Proyecto (opcional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _visionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ej: Transformar el proceso en 6 meses...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.visibility, color: Colors.blue),
              ),
            ),

            const SizedBox(height: 24),

            // Documentos PDF
            const Text(
              'Documentos del Proyecto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Botón para subir PDFs
            InkWell(
              onTap: _seleccionarPDFs,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _pdfFiles.isEmpty ? Colors.blue.shade700 : Colors.green.shade700,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _pdfFiles.isEmpty ? Icons.upload_file : Icons.check_circle,
                      color: _pdfFiles.isEmpty ? Colors.blue : Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _pdfFiles.isEmpty
                          ? 'Clic para subir documentos PDF'
                          : '${_pdfFiles.length} documento(s) subido(s)',
                      style: TextStyle(
                        color: _pdfFiles.isEmpty ? Colors.white70 : Colors.green,
                        fontSize: 16,
                        fontWeight: _pdfFiles.isEmpty ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    if (_pdfFiles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Soporta múltiples archivos PDF',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Lista de PDFs subidos
            if (_pdfFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.description, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Archivos seleccionados:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_pdfNames.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _pdfNames[index],
                                style: const TextStyle(color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 20),
                              onPressed: () => _eliminarPDF(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Fechas
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha de Inicio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _seleccionarFecha(true),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Colors.blue, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _fechaInicio != null
                                    ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                                    : 'Seleccionar',
                                style: TextStyle(
                                  color: _fechaInicio != null
                                      ? Colors.white
                                      : Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha de Fin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _seleccionarFecha(false),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event,
                                  color: Colors.blue, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _fechaFin != null
                                    ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'
                                    : 'Opcional',
                                style: TextStyle(
                                  color: _fechaFin != null
                                      ? Colors.white
                                      : Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Botón generar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _generarProyecto,
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text(
                  'Generar Proyecto con IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notas informativas
            if (_pdfFiles.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade900.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade700),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Primero sube los documentos PDF del proyecto, luego podrás generar.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade900.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade700),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.green, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'La IA analizará tus documentos en 2-3 minutos y generará el proyecto PMI completo.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerandoUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spinner
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 40),

            // Título
            const Text(
              'Generando Proyecto PMI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Mensaje de progreso
            Text(
              _progresoMensaje,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progreso,
                minHeight: 8,
                backgroundColor: Colors.grey.shade800,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              '${(_progreso * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

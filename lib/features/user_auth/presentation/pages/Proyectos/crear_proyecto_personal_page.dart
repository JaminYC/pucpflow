import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'ProyectoDetalleKanbanPage.dart';
import 'proyecto_model.dart';
import 'tarea_model.dart';

class CrearProyectoPersonalPage extends StatefulWidget {
  const CrearProyectoPersonalPage({super.key});

  @override
  State<CrearProyectoPersonalPage> createState() => _CrearProyectoPersonalPageState();
}

class _CrearProyectoPersonalPageState extends State<CrearProyectoPersonalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _objetivosController = TextEditingController();
  final _restriccionesController = TextEditingController();
  final _preferenciasController = TextEditingController();
  String _categoria = "Laboral";

  bool _generando = false;
  bool _creandoProyecto = false;
  Map<String, dynamic>? _proyectoGenerado;
  List<PlatformFile> _pdfFiles = [];

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _objetivosController.dispose();
    _restriccionesController.dispose();
    _preferenciasController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarPDFs() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _pdfFiles = result.files;
        });
      }
    } catch (e) {
      print('Error seleccionando PDFs: $e');
    }
  }

  Future<void> _generarProyecto() async {
    if (!_formKey.currentState!.validate()) return;

    print('📋 Validación exitosa, iniciando generación...');

    setState(() {
      _generando = true;
      _proyectoGenerado = null;
    });

    try {
      // Convertir PDFs a base64
      List<String> documentosBase64 = [];
      print('📄 Procesando ${_pdfFiles.length} archivos PDF...');
      for (var file in _pdfFiles) {
        if (file.bytes != null) {
          documentosBase64.add(base64Encode(file.bytes!));
          print('   ✓ PDF procesado: ${file.name} (${file.bytes!.length} bytes)');
        }
      }
      print('✅ ${documentosBase64.length} PDFs convertidos a base64');

      // Llamar a Cloud Function
      print('☁️ Configurando llamada a Firebase Functions...');
      final callable = FirebaseFunctions.instance.httpsCallable(
        'generarProyectoPersonal',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 480),
        ),
      );

      print('🚀 Iniciando generación de proyecto personal...');

      final result = await callable.call({
        'nombreProyecto': _nombreController.text.trim(),
        'descripcionLibre': _descripcionController.text.trim(),
        'objetivosPrincipales': _objetivosController.text.trim(),
        'restricciones': _restriccionesController.text.trim(),
        'preferencias': _preferenciasController.text.trim(),
        'documentosBase64': documentosBase64,
      });

      print('✅ Respuesta recibida de Cloud Function');

      // Convertir explícitamente a Map<String, dynamic>
      final data = Map<String, dynamic>.from(result.data as Map);

      print('📦 Datos convertidos: ${data.keys}');

      if (data['error'] != null) {
        print('❌ Error en la respuesta: ${data['error']}');
        throw Exception(data['error']);
      }

      if (data['proyecto'] != null) {
        print('✨ Proyecto generado correctamente');
        setState(() {
          _proyectoGenerado = Map<String, dynamic>.from(data['proyecto'] as Map);
          _generando = false;
        });
      } else {
        print('⚠️ No se recibió proyecto en la respuesta');
        throw Exception('No se recibió el proyecto generado');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ ¡Proyecto personal generado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _generando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _crearProyecto() async {
    if (_proyectoGenerado == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _creandoProyecto = true);

    try {
      final proyectoRef = FirebaseFirestore.instance.collection('proyectos').doc();

      // Convertir fases a tareas
      List<Tarea> tareas = [];
      final fases = _proyectoGenerado!['fases'] as List? ?? [];

      print('📊 Generando proyecto personal con ${fases.length} fases...');

      int faseIndex = 0;
      for (var fase in fases) {
        final nombreFase = fase['nombre'] ?? 'Fase ${faseIndex + 1}';
        final tareasFase = fase['tareas'] as List? ?? [];

        print('   ✓ Fase "${nombreFase}" (${tareasFase.length} tareas)');

        for (var tareaData in tareasFase) {
          final nombreTarea = tareaData['nombre'] ?? 'Tarea ${tareas.length + 1}';
          final duracionMinutos = _parseDuracion(tareaData['tiempoEstimado']);

          // ✅ Calcular fecha límite basada en duración estimada
          // Sumar duraciones acumuladas para tener fechas progresivas
          final duracionAcumulada = tareas.fold<int>(0, (sum, t) => sum + t.duracion);
          final fechaLimite = DateTime.now().add(Duration(minutes: duracionAcumulada + duracionMinutos));

          tareas.add(Tarea(
            titulo: nombreTarea,
            descripcion: tareaData['descripcion'] ?? '',
            fecha: fechaLimite, // Mantener por compatibilidad
            fechaLimite: fechaLimite, // ✅ Deadline - fecha límite calculada
            fechaProgramada: null, // No hay hora específica en proyectos personales
            duracion: duracionMinutos,
            prioridad: _parsePrioridad(tareaData['prioridad']),
            completado: false,
            colorId: _getColorForPhase(nombreFase),
            responsables: [user.uid], // ✅ Auto-asignar al creador del proyecto
            tipoTarea: 'Libre', // ✅ Tipo correcto: Libre/Asignada/Automática
            requisitos: {},
            dificultad: tareaData['prioridad'] == 'alta' ? 'alta' : 'media',
            tareasPrevias: [],
            area: 'Personal', // ✅ Área única para proyectos personales
            habilidadesRequeridas: List<String>.from(tareaData['recursosNecesarios'] ?? []),
            fasePMI: nombreFase, // Guardamos la fase para agrupar/visualizar
            entregable: null,
            paqueteTrabajo: null,
          ));
        }
        faseIndex++;
      }

      print('✅ Proyecto personal generado: ${tareas.length} tareas en ${fases.length} fases');

      final proyecto = Proyecto(
        id: proyectoRef.id,
        nombre: _nombreController.text.trim(),
        descripcion: _proyectoGenerado!['resumenEjecutivo'] ?? _descripcionController.text.trim(),
        vision: (_proyectoGenerado?['vision'] ?? '').toString(),
        fechaInicio: DateTime.now(),
        fechaFin: null,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
        propietario: user.uid,
        participantes: [user.uid],
        categoria: _categoria,
        tareas: tareas,
        areas: {'Personal': []}, // ✅ Proyectos personales solo tienen una área general
        blueprintIA: _proyectoGenerado,
        objetivo: _proyectoGenerado!['vision'],
        alcance: (_proyectoGenerado!['objetivos'] as List?)?.join(' | '),
      );

      await proyectoRef.set(proyecto.toJson());

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProyectoDetalleKanbanPage(proyectoId: proyectoRef.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _creandoProyecto = false);
      }
    }
  }

  int _parseDuracion(String? tiempo) {
    if (tiempo == null) return 60;
    if (tiempo.contains('día')) {
      final match = RegExp(r'\d+').firstMatch(tiempo);
      if (match != null) {
        return int.parse(match.group(0)!) * 480; // 8 horas/día
      }
    }
    return 60;
  }

  int _parsePrioridad(String? prioridad) {
    switch (prioridad?.toLowerCase()) {
      case 'alta':
        return 5;
      case 'media':
        return 3;
      case 'baja':
        return 1;
      default:
        return 3;
    }
  }

  int _getColorForPhase(String fase) {
    final hash = fase.hashCode;
    final colors = [
      0xFF8B5CF6,
      0xFF3B82F6,
      0xFF06B6D4,
      0xFF10B981,
      0xFFF97316,
      0xFFEC4899,
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0A0E27),
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    '🎨 Proyecto Personal',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFEC4899).withOpacity(0.2),
                          const Color(0xFF8B5CF6).withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Contenido
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Info Card
                    _buildInfoCard(),
                    const SizedBox(height: 20),

                    // Nombre
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            icon: Icons.lightbulb_outline,
                            title: 'Nombre del Proyecto',
                            subtitle: '¿Cómo se llama tu proyecto?',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _nombreController,
                            label: 'Nombre',
                            hint: 'Ej: Aprender Flutter en 3 meses',
                            validator: (v) => v?.isEmpty ?? true ? 'Obligatorio' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildCategoriaDropdown(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            icon: Icons.description_outlined,
                            title: 'Descripción',
                            subtitle: 'Cuéntanos de qué trata',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _descripcionController,
                            label: 'Descripción libre',
                            hint: 'Escribe todo lo que quieras sobre tu proyecto...',
                            maxLines: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Objetivos
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            icon: Icons.flag_outlined,
                            title: 'Objetivos',
                            subtitle: '¿Qué quieres lograr?',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _objetivosController,
                            label: 'Objetivos principales',
                            hint: 'Ej: Crear mi primera app, Publicar en Play Store...',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Restricciones
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            icon: Icons.warning_amber_outlined,
                            title: 'Restricciones',
                            subtitle: '¿Qué limitaciones tienes?',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _restriccionesController,
                            label: 'Limitaciones (opcional)',
                            hint: 'Ej: Solo 2 horas/día, Presupuesto de \$500...',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Preferencias
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            icon: Icons.tune_outlined,
                            title: 'Preferencias',
                            subtitle: '¿Cómo te gusta trabajar?',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _preferenciasController,
                            label: 'Tus preferencias (opcional)',
                            hint: 'Ej: Prefiero videos a documentación, Me gusta trabajar de noche...',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PDFs
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            icon: Icons.cloud_upload_outlined,
                            title: 'Documentos (Opcional)',
                            subtitle: 'Sube PDFs con información adicional',
                          ),
                          const SizedBox(height: 16),
                          _buildPDFUploader(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón Generar
                    _buildGenerateButton(),
                    const SizedBox(height: 24),

                    // Preview
                    if (_proyectoGenerado != null) ...[
                      _buildProjectPreview(),
                      const SizedBox(height: 16),
                      _buildCreateButton(),
                    ],

                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEC4899).withOpacity(0.15),
            const Color(0xFF8B5CF6).withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEC4899).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFFEC4899),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Total Libertad!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'La IA creará un plan 100% personalizado adaptado a TUS necesidades',
                  style: TextStyle(
                    color: Color(0xFFB8BCC8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2D3347).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: -8,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFEC4899).withOpacity(0.2),
                const Color(0xFF8B5CF6).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFEC4899), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFB8BCC8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFFB8BCC8)),
        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEC4899)),
        ),
      ),
    );
  }

  Widget _buildCategoriaDropdown() {
    return DropdownButtonFormField<String>(
      value: _categoria,
      dropdownColor: const Color(0xFF1A1F3A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Categoria',
        labelStyle: const TextStyle(color: Color(0xFFB8BCC8)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEC4899)),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Laboral', child: Text('Laboral')),
        DropdownMenuItem(value: 'Personal', child: Text('Personal')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _categoria = value);
      },
    );
  }

  Widget _buildPDFUploader() {
    return Column(
      children: [
        InkWell(
          onTap: _generando ? null : _seleccionarPDFs,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEC4899).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: _generando
                      ? const Color(0xFFB8BCC8).withOpacity(0.3)
                      : const Color(0xFFEC4899),
                ),
                const SizedBox(width: 12),
                Text(
                  _pdfFiles.isEmpty
                      ? 'Subir PDFs (opcional)'
                      : '${_pdfFiles.length} archivo(s)',
                  style: TextStyle(
                    color: _generando
                        ? const Color(0xFFB8BCC8).withOpacity(0.5)
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_pdfFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pdfFiles.map((file) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Color(0xFFEC4899), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      file.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    if (!_generando) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _pdfFiles.remove(file)),
                        child: const Icon(Icons.close, color: Color(0xFFB8BCC8), size: 16),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _generando
            ? null
            : const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
              ),
        color: _generando ? const Color(0xFF2D3347) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _generando
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFEC4899).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _generando ? null : _generarProyecto,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _generando
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFB8BCC8),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Generando tu proyecto personal...',
                        style: TextStyle(
                          color: Color(0xFFB8BCC8),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Generar con IA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectPreview() {
    if (_proyectoGenerado == null) return const SizedBox();

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✨ ¡Proyecto Generado!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Revisa tu plan personalizado',
                      style: TextStyle(color: Color(0xFFB8BCC8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: const Color(0xFF2D3347)),
          const SizedBox(height: 20),

          // Resumen
          if (_proyectoGenerado!['resumenEjecutivo'] != null)
            _buildPreviewSection(
              'Resumen',
              _proyectoGenerado!['resumenEjecutivo'],
            ),

          // Visión
          if (_proyectoGenerado!['vision'] != null)
            _buildPreviewSection(
              'Visión',
              _proyectoGenerado!['vision'],
            ),

          // Objetivos
          if (_proyectoGenerado!['objetivos'] != null)
            _buildListSection(
              'Objetivos',
              List<String>.from(_proyectoGenerado!['objetivos']),
            ),

          // Fases
          if (_proyectoGenerado!['fases'] != null)
            _buildPhasesPreview(),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFEC4899),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFFB8BCC8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFEC4899),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Color(0xFFEC4899))),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(color: Color(0xFFB8BCC8), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPhasesPreview() {
    final fases = _proyectoGenerado!['fases'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fases del Proyecto (${fases.length})',
          style: const TextStyle(
            color: Color(0xFFEC4899),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...fases.map((fase) {
          final tareas = fase['tareas'] as List? ?? [];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fase['nombre'] ?? 'Fase',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tareas.length} tareas • ${fase['duracionEstimada'] ?? 'Sin duración'}',
                  style: const TextStyle(color: Color(0xFFB8BCC8), fontSize: 12),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _creandoProyecto
            ? null
            : const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
        color: _creandoProyecto ? const Color(0xFF2D3347) : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _creandoProyecto ? null : _crearProyecto,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _creandoProyecto
                ? const CircularProgressIndicator(
                    color: Color(0xFFB8BCC8),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Crear Proyecto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/project_ai_config.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/project_ai_service.dart';
import 'ProyectoDetalleKanbanPage.dart';
import 'proyecto_model.dart';
import 'tarea_model.dart';

class CrearProyectoContextualPage extends StatefulWidget {
  const CrearProyectoContextualPage({super.key});

  @override
  State<CrearProyectoContextualPage> createState() =>
      _CrearProyectoContextualPageState();
}

class _CrearProyectoContextualPageState
    extends State<CrearProyectoContextualPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _visionController = TextEditingController();

  ProjectMethodology _methodology = ProjectMethodology.general;
  String _categoria = "Laboral";
  bool _generando = false;
  bool _creatingProject = false;
  Map<String, dynamic>? _blueprint;
  final ProjectAIService _aiService = ProjectAIService();
  List<_LocalAttachment> _attachments = [];
  String? _docError;

  @override
  void dispose() {
    _nombreController.dispose();
    _visionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              // Header elegante
              SliverAppBar(
                expandedHeight: isMobile ? 120 : 160,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0A0E27),
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Proyecto Flexible',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF8B5CF6).withOpacity(0.1),
                          const Color(0xFF3B82F6).withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Contenido principal
              SliverPadding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Información del proyecto
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            icon: Icons.rocket_launch_outlined,
                            title: 'Comienza tu proyecto',
                            subtitle: 'Solo lo esencial, la IA hará el resto',
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _nombreController,
                            label: 'Nombre del proyecto',
                            validator: (value) => value == null || value.trim().isEmpty
                                ? 'Obligatorio'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildCategoriaDropdown(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _visionController,
                            label: '¿Qué quieres lograr?',
                            helper: 'Describe tu objetivo principal',
                            maxLines: 3,
                            validator: (value) => value == null || value.trim().isEmpty
                                ? 'Obligatorio'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            icon: Icons.account_tree_outlined,
                            title: 'Metodología',
                            subtitle: 'Elige tu enfoque de trabajo',
                          ),
                          const SizedBox(height: 16),
                          _buildMethodologySelector(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Documentos
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            icon: Icons.cloud_upload_outlined,
                            title: 'Documentos de Apoyo',
                            subtitle: 'Sube archivos PDF para análisis contextual',
                          ),
                          const SizedBox(height: 20),
                          _buildDocumentUploader(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón generar
                    _buildGenerateButton(),
                    const SizedBox(height: 24),

                    // Preview del blueprint
                    if (_blueprint != null) ...[
                      _buildBlueprintPreview(_blueprint!),
                      const SizedBox(height: 20),
                      _buildCreateProjectButton(),
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

  // ===== COMPONENTES UI CON ESTILO FLOW =====

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF2D3347).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 8),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF8B5CF6).withOpacity(0.2),
                const Color(0xFF3B82F6).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF8B5CF6),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFB8BCC8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodologySelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ProjectMethodology.values.map((method) {
        final isSelected = method == _methodology;
        return GestureDetector(
          onTap: () => setState(() => _methodology = method),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF8B5CF6).withOpacity(0.15)
                  : const Color(0xFF1A1F3A).withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF2D3347).withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              method.label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFFB8BCC8),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDocumentUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _generando ? null : _pickDocuments,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A).withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: _generando ? const Color(0xFFB8BCC8).withOpacity(0.3) : const Color(0xFF3B82F6),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  _attachments.isEmpty ? 'Seleccionar PDFs (máx. 4 MB c/u)' : '${_attachments.length} archivo(s) seleccionado(s)',
                  style: TextStyle(
                    color: _generando ? const Color(0xFFB8BCC8).withOpacity(0.5) : const Color(0xFFFFFFFF),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_docError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _docError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _attachments.map((file) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Color(0xFF3B82F6), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      file.name,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 13,
                      ),
                    ),
                    if (!_generando) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _attachments.remove(file)),
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFF3B82F6),
                ],
              ),
        color: _generando ? const Color(0xFF2D3347) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _generando
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _generando ? null : _generarBlueprint,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _generando
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
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
                        'Generando blueprint con IA...',
                        style: TextStyle(
                          color: Color(0xFFB8BCC8),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.auto_awesome, color: Color(0xFFFFFFFF), size: 22),
                      SizedBox(width: 12),
                      Text(
                        'Generar Proyecto con IA',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
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

  Widget _buildCreateProjectButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _creatingProject
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF10B981),
                  Color(0xFF059669),
                ],
              ),
        color: _creatingProject ? const Color(0xFF2D3347) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _creatingProject
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _creatingProject ? null : _createProjectFromBlueprint,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _creatingProject
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
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
                        'Creando proyecto...',
                        style: TextStyle(
                          color: Color(0xFFB8BCC8),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_outline, color: Color(0xFFFFFFFF), size: 22),
                      SizedBox(width: 12),
                      Text(
                        'Crear Proyecto desde Blueprint',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? helper,
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
        labelStyle: TextStyle(color: Colors.grey.shade300),
        helperText: helper,
        helperStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
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
        labelStyle: TextStyle(color: Colors.grey.shade300),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
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

  List<String> _parseList(String value) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();
  }

  static const _maxArchivosKB = 4 * 1024; // 4 MB por archivo
  static const _maxTotalKB   = 8 * 1024; // 8 MB total

  Future<void> _pickDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null) return;

      final attachments = <_LocalAttachment>[];
      final rechazados  = <String>[];

      for (final file in result.files) {
        if (file.bytes == null) {
          rechazados.add('${file.name} (no se pudo leer)');
          continue;
        }
        final kb = file.bytes!.length ~/ 1024;
        if (kb > _maxArchivosKB) {
          rechazados.add('${file.name} (${kb ~/ 1024} MB — máx. 4 MB)');
          continue;
        }
        attachments.add(_LocalAttachment(name: file.name, bytes: file.bytes!));
      }

      // Verificar tamaño total
      final totalKb = attachments.fold<int>(
          0, (acc, f) => acc + f.bytes.length ~/ 1024);
      if (totalKb > _maxTotalKB) {
        setState(() {
          _docError =
              'El total de documentos excede 8 MB. Reduce el número o el tamaño de los archivos.';
          _attachments = [];
        });
        return;
      }

      String? warning;
      if (rechazados.isNotEmpty) {
        warning = 'Archivos omitidos por ser demasiado grandes:\n${rechazados.join('\n')}';
      }

      setState(() {
        _attachments = attachments;
        _docError = warning ??
            (attachments.isEmpty
                ? 'No se pudieron leer los archivos seleccionados.'
                : null);
      });
    } catch (e) {
      setState(() {
        _docError = 'Error al leer documentos: $e';
      });
    }
  }

  Future<void> _generarBlueprint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _generando = true;
      _blueprint = null;
    });

    final config = ProjectBlueprintConfig(
      methodology: _methodology,
      focusAreas: const [],
      softSkillFocus: const [],
      businessDrivers: const [],
      customContext: null,
    );

    Map<String, dynamic>? result;

    if (_attachments.isNotEmpty) {
      // Con documentos: convertir a Base64 y usar generarBlueprint
      print('🚀 INICIANDO GENERACIÓN CON DOCUMENTOS (${_attachments.length} PDFs)');
      final documentosBase64 = _attachments
          .map((a) => base64Encode(a.bytes))
          .toList();
      print('   📄 Base64 generado: ${documentosBase64.length} docs');

      result = await _aiService.generarBlueprint(
        documentosBase64: documentosBase64,
        nombreProyecto: _nombreController.text.trim(),
        config: config,
        descripcionBreve: _visionController.text.trim(),
      );

      // generarBlueprint devuelve el blueprint directo (ya procesado en service)
      // pero el preview espera el formato workflow — normalizar si es necesario
      if (result != null && !result.containsKey('workflow')) {
        // Si el resultado tiene 'backlog' o 'fases', mapearlo a 'workflow'
        final fases = result['fases'] as List? ??
            result['backlog'] as List? ?? [];
        if (fases.isNotEmpty) {
          result['workflow'] = fases;
        }
      }
    } else {
      // Sin documentos: usar generarWorkflow
      print('🚀 INICIANDO GENERACIÓN DE WORKFLOW (sin documentos)');
      result = await _aiService.generarWorkflow(
        nombreProyecto: _nombreController.text.trim(),
        config: config,
        habilidadesEquipo: const [],
        objetivo: _visionController.text.trim(),
      );
    }

    if (!mounted) return;

    print('📦 RESULTADO: ${result == null ? "null" : result.keys.toList()}');
    if (result != null && result.containsKey('workflow')) {
      final wf = result['workflow'] as List?;
      print('   - Fases: ${wf?.length ?? 0}');
    }

    setState(() {
      _generando = false;
      _blueprint = result;
    });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo generar el blueprint. Intenta nuevamente.'),
        ),
      );
    }
  }

  Map<String, dynamic>? _tryParseJson(String value) {
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return {'contextoLibre': value};
    }
  }

  Widget _buildBlueprintPreview(Map<String, dynamic> data) {
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFFFFFFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blueprint Generado',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Proyecto listo para crear',
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
          const SizedBox(height: 24),
          Container(
            height: 1,
            color: const Color(0xFF2D3347),
          ),
          const SizedBox(height: 24),
          // ✅ Solo mostrar información legible y útil para el usuario
          if (data['resumenEjecutivo'] != null)
            _buildPreviewBlock('📝 Resumen', data['resumenEjecutivo']),
          if (data['objetivosSMART'] != null)
            _buildListBlock('🎯 Objetivos', data['objetivosSMART']),
          if (data['workflow'] != null && data['workflow'] is List)
            _buildWorkflowPreview('📋 Fases del proyecto', data['workflow']),
        ],
      ),
    );
  }

  Widget _buildPreviewBlock(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2D3347).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              content,
              style: const TextStyle(
                color: Color(0xFFB8BCC8),
                height: 1.6,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowPreview(String title, List workflow) {
    if (workflow.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...workflow.take(5).map((fase) {
            final nombre = fase['nombre'] ?? 'Fase sin nombre';
            final objetivo = fase['objetivo'] ?? '';
            final tareas = fase['tareas'] as List? ?? [];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${tareas.length} tareas',
                          style: TextStyle(
                            color: const Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nombre,
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (objetivo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      objetivo,
                      style: TextStyle(
                        color: const Color(0xFFB8BCC8),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildListBlock(String title, dynamic listData) {
    final List items = listData is List ? listData : [];
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2D3347).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item is String ? item : jsonEncode(item),
                      style: const TextStyle(
                        color: Color(0xFFB8BCC8),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _createProjectFromBlueprint() async {
    if (_blueprint == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para crear proyectos')),
      );
      return;
    }

    setState(() => _creatingProject = true);
    try {
      final proyectoRef =
          FirebaseFirestore.instance.collection('proyectos').doc();

      final tareas = _mapBlueprintToTasks(_blueprint!, user.uid);

      print('\n🔍 VERIFICACIÓN FINAL DE ÁREAS:');
      print('   📊 Total de tareas generadas: ${tareas.length}');

      // ✅ Construir áreas únicas desde las tareas generadas
      final areasContextuales = <String, List<String>>{};
      for (final tarea in tareas) {
        final areaNormalizada = tarea.area.trim();
        if (!areasContextuales.containsKey(areaNormalizada)) {
          areasContextuales[areaNormalizada] = [];
          print('   ✅ Área agregada: "$areaNormalizada"');
        }
      }

      print('   🔒 TOTAL ÁREAS ÚNICAS FINALES: ${areasContextuales.length}');
      print('   📋 Lista de áreas: ${areasContextuales.keys.toList()}');

      // 🚨 VERIFICACIÓN CRÍTICA: Detectar si hay duplicados
      final areasSet = areasContextuales.keys.toSet();
      if (areasSet.length != areasContextuales.length) {
        print('   ❌ ERROR: Se detectaron duplicados en áreas!');
        throw Exception('Error crítico: áreas duplicadas detectadas');
      }
      print('   ✅ VALIDACIÓN EXITOSA: No hay duplicados\n');

      final proyecto = Proyecto(
        id: proyectoRef.id,
        nombre: _nombreController.text.trim(),
        descripcion: _blueprint!['resumenEjecutivo'] ?? '',
        vision: _visionController.text.trim(),
        fechaInicio: DateTime.now(),
        fechaFin: null,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
        propietario: user.uid,
        participantes: [user.uid],
        categoria: _categoria,
        tareas: tareas,
        areas: areasContextuales, // ✅ Áreas fijas para proyectos contextuales
        blueprintIA: _blueprint,
        objetivo: _blueprint!['resumenEjecutivo'],
        alcance:
            (_blueprint!['objetivosSMART'] as List?)?.join(' | '),
      );

      await proyectoRef.set(proyecto.toJson());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proyecto creado satisfactoriamente'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProyectoDetalleKanbanPage(proyectoId: proyectoRef.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creando proyecto: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingProject = false);
      }
    }
  }

  /// Normaliza un nombre de área/fase para garantizar unicidad
  String _normalizarNombreArea(String nombre) {
    return nombre
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Espacios múltiples → un espacio
        .replaceAll(RegExp(r'[^\w\sáéíóúñÁÉÍÓÚÑ-]'), '') // Remover caracteres especiales excepto espacios, guiones y acentos
        .toLowerCase(); // Normalizar a minúsculas para comparación
  }

  List<Tarea> _mapBlueprintToTasks(Map<String, dynamic> blueprint, String userId) {
    final tasks = <Tarea>[];

    // ✅ Procesar workflow/fases (nuevo formato) en lugar de backlog/hitos (formato viejo)
    final workflow = blueprint['workflow'] as List? ?? [];

    print('📊 Generando proyecto flexible con ${workflow.length} fases del workflow...');

    // 🔒 PASO 1: Crear un mapa para detectar y resolver duplicados de nombres de fases
    final nombresUsados = <String, String>{}; // normalizado → original único
    final nombresOriginales = <String>[]; // Lista ordenada de nombres únicos

    for (var i = 0; i < workflow.length; i++) {
      var nombreOriginal = workflow[i]['nombre']?.toString().trim() ?? 'Fase ${i + 1}';
      var nombreNormalizado = _normalizarNombreArea(nombreOriginal);

      // Si ya existe ese nombre normalizado, agregar sufijo
      if (nombresUsados.containsKey(nombreNormalizado)) {
        var contador = 2;
        var nuevoNombre = '$nombreOriginal $contador';
        var nuevoNormalizado = _normalizarNombreArea(nuevoNombre);

        while (nombresUsados.containsKey(nuevoNormalizado)) {
          contador++;
          nuevoNombre = '$nombreOriginal $contador';
          nuevoNormalizado = _normalizarNombreArea(nuevoNombre);
        }

        nombreOriginal = nuevoNombre;
        nombreNormalizado = nuevoNormalizado;
        print('   ⚠️ Nombre de fase duplicado detectado, renombrado a: "$nombreOriginal"');
      }

      nombresUsados[nombreNormalizado] = nombreOriginal;
      nombresOriginales.add(nombreOriginal);
    }

    print('   ✅ Nombres de fases únicos garantizados: $nombresOriginales');

    // 🔒 PASO 2: Generar tareas usando los nombres únicos
    int faseIndex = 0;
    int duracionAcumuladaDias = 0;

    for (var fase in workflow) {
      final nombreFaseUnico = nombresOriginales[faseIndex]; // ✅ Usar nombre único garantizado
      final tareasFase = fase['tareas'] as List? ?? [];
      final duracionFaseDiasNum = fase['duracionDias'] ?? 7;
      final duracionFaseDias = (duracionFaseDiasNum is int) ? duracionFaseDiasNum : (duracionFaseDiasNum as num).toInt();

      print('   ✓ Fase "${nombreFaseUnico}" (${tareasFase.length} tareas)');

      for (var tareaData in tareasFase) {
        final nombreTarea = tareaData['titulo'] ?? 'Tarea ${tasks.length + 1}';

        // ✅ Combinar habilidades técnicas y blandas
        final habilidadesTecnicas = List<String>.from(tareaData['habilidadesTecnicas'] ?? []);
        final habilidadesBlandas = List<String>.from(tareaData['habilidadesBlandas'] ?? []);
        final todasHabilidades = [...habilidadesTecnicas, ...habilidadesBlandas];

        // ✅ Obtener outputs como entregable
        final outputs = List<String>.from(tareaData['outputs'] ?? []);
        final entregable = outputs.isNotEmpty ? outputs.join(', ') : null;

        // ✅ Calcular fecha límite distribuyendo tareas en la duración de la fase
        final duracionTareaDias = tareasFase.isNotEmpty ? (duracionFaseDias / tareasFase.length).ceil() : duracionFaseDias;
        duracionAcumuladaDias += duracionTareaDias;
        final fechaLimite = DateTime.now().add(Duration(days: duracionAcumuladaDias));

        print('      📅 Tarea "$nombreTarea" → Fecha: ${fechaLimite.toString().split(' ')[0]} (+$duracionAcumuladaDias días)');

        tasks.add(Tarea(
          titulo: nombreTarea,
          descripcion: tareaData['descripcion'] ?? '',
          fecha: fechaLimite, // Mantener por compatibilidad
          fechaLimite: fechaLimite, // ✅ Deadline - fecha límite de entrega
          fechaProgramada: null, // No hay hora específica en proyectos contextuales
          duracion: duracionTareaDias * 8 * 60, // Convertir días a minutos (8h/día)
          prioridad: 3, // Prioridad media por defecto
          completado: false,
          colorId: _getColorForPhase(nombreFaseUnico, faseIndex),
          responsables: [userId], // ✅ Auto-asignar al creador
          tipoTarea: fase['tipo'] ?? 'Flexible',
          requisitos: {},
          dificultad: 'media',
          tareasPrevias: [],
          area: nombreFaseUnico, // 🔒 GARANTIZADO ÚNICO
          habilidadesRequeridas: todasHabilidades,
          fasePMI: nombreFaseUnico, // 🔒 GARANTIZADO ÚNICO
          entregable: entregable,
          paqueteTrabajo: null,
        ));
      }

      faseIndex++;
    }

    print('✅ Proyecto flexible generado: ${tasks.length} tareas en ${workflow.length} fases');
    print('🔒 Áreas únicas garantizadas: ${nombresOriginales.toSet().length} áreas distintas');

    return tasks;
  }

  int _getColorForPhase(String nombreFase, int index) {
    // Colores diferentes para cada fase
    final colores = [
      0xFF64B5F6, // Azul
      0xFF81C784, // Verde
      0xFFFFD54F, // Amarillo
      0xFFFF8A65, // Naranja
      0xFFBA68C8, // Púrpura
      0xFF4DD0E1, // Cyan
      0xFFAED581, // Lima
    ];
    return colores[index % colores.length];
  }
}

class _LocalAttachment {
  final String name;
  final List<int> bytes;

  _LocalAttachment({required this.name, required this.bytes});
}

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
  final _descripcionController = TextEditingController();
  final _visionController = TextEditingController();
  final _focusController = TextEditingController();
  final _softSkillsController = TextEditingController();
  final _driversController = TextEditingController();
  final _customContextController = TextEditingController();

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
    _descripcionController.dispose();
    _visionController.dispose();
    _focusController.dispose();
    _softSkillsController.dispose();
    _driversController.dispose();
    _customContextController.dispose();
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
                    'Crear Proyecto con IA',
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
                            icon: Icons.description_outlined,
                            title: 'Información del Proyecto',
                            subtitle: 'Define el contexto y alcance inicial',
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
                          _buildTextField(
                            controller: _visionController,
                            label: 'Vision del proyecto',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _descripcionController,
                            label: 'Descripción breve / historia del usuario',
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metodología
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            icon: Icons.account_tree_outlined,
                            title: 'Metodología Base',
                            subtitle: 'Selecciona el framework de trabajo',
                          ),
                          const SizedBox(height: 20),
                          _buildMethodologySelector(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Foco estratégico
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            icon: Icons.track_changes_outlined,
                            title: 'Foco Estratégico',
                            subtitle: 'Define prioridades y áreas clave',
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _focusController,
                            label: 'Áreas de enfoque',
                            helper:
                                'Ej: Descubrimiento de cliente, Experiencia móvil, Operaciones',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _softSkillsController,
                            label: 'Soft skills prioritarias',
                            helper:
                                'Ej: Comunicación efectiva, Gestión del cambio, Liderazgo',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _driversController,
                            label: 'Drivers de negocio',
                            helper:
                                'Ej: Retención de clientes, Velocidad de entrega, Innovación',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Contexto adicional
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            icon: Icons.note_add_outlined,
                            title: 'Contexto Adicional',
                            subtitle: 'Información complementaria (opcional)',
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _customContextController,
                            label: 'Notas adicionales',
                            maxLines: 4,
                          ),
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
                  _attachments.isEmpty ? 'Seleccionar documentos PDF' : '${_attachments.length} archivo(s) seleccionado(s)',
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
      String? warning;
      for (final file in result.files) {
        if (file.bytes != null) {
          attachments.add(
            _LocalAttachment(name: file.name, bytes: file.bytes!),
          );
        } else {
          warning =
              'Algunos archivos no pudieron leerse. Intenta seleccionarlos nuevamente.';
        }
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
      focusAreas: _parseList(_focusController.text),
      softSkillFocus: _parseList(_softSkillsController.text),
      businessDrivers: _parseList(_driversController.text),
      customContext: _customContextController.text.trim().isEmpty
          ? null
          : _tryParseJson(_customContextController.text.trim()),
    );

    final result = await _aiService.generarBlueprint(
      documentosBase64:
          _attachments.map((doc) => base64Encode(doc.bytes)).toList(),
      nombreProyecto: _nombreController.text.trim(),
      descripcionBreve: _descripcionController.text.trim(),
      config: config,
    );

    if (!mounted) return;

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
          if (data['resumenEjecutivo'] != null)
            _buildPreviewBlock('Resumen ejecutivo', data['resumenEjecutivo']),
          if (data['objetivosSMART'] != null)
            _buildListBlock('Objetivos SMART', data['objetivosSMART']),
          if (data['hitosPrincipales'] != null)
            _buildListBlock('Hitos principales', data['hitosPrincipales']),
          if (data['backlogInicial'] != null)
            _buildListBlock('Backlog inicial', data['backlogInicial']),
          if (data['skillMatrixSugerida'] != null)
            _buildListBlock(
                'Matriz de skills sugerida', data['skillMatrixSugerida']),
          if (data['softSkillsPlan'] != null)
            _buildPreviewBlock(
                'Plan de soft skills', data['softSkillsPlan'].toString()),
          if (data['recomendacionesPMI'] != null)
            _buildPreviewBlock('Recomendaciones PMI',
                data['recomendacionesPMI'].toString()),
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

      final tareas = _mapBlueprintToTasks(_blueprint!);

      final proyecto = Proyecto(
        id: proyectoRef.id,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? (_blueprint!['resumenEjecutivo'] ?? '')
            : _descripcionController.text.trim(),
        vision: _visionController.text.trim(),
        fechaInicio: DateTime.now(),
        fechaFin: null,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
        propietario: user.uid,
        participantes: [user.uid],
        categoria: _categoria,
        tareas: tareas,
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

  List<Tarea> _mapBlueprintToTasks(Map<String, dynamic> blueprint) {
    final tasks = <Tarea>[];
    final backlog = blueprint['backlogInicial'] as List? ?? [];
    final defaultSkills = _skillsFromMatrix(blueprint);

    for (final item in backlog) {
      final map = item is Map ? Map<String, dynamic>.from(item) : {};
      final tipo = (map['tipo'] ?? 'Contextual').toString();
      final entregables = _safeStringList(map['entregables']);
      final metricas = _safeStringList(map['metricasExito']);
      final descripcionParts = <String>[];
      if (entregables.isNotEmpty) {
        descripcionParts.add('Entregables: ${entregables.join(", ")}');
      }
      if (metricas.isNotEmpty) {
        descripcionParts.add('Métricas: ${metricas.join(", ")}');
      }
      tasks.add(
        Tarea(
          titulo: (map['nombre'] ?? 'Tarea contextual') as String,
          fecha: DateTime.now(),
          duracion: tipo.toLowerCase() == 'seguimiento' ? 45 : 60,
          prioridad: 3,
          completado: false,
          colorId: _colorForTipo(tipo),
          responsables: const [],
          tipoTarea: tipo,
          requisitos: const {},
          dificultad: 'media',
          descripcion: descripcionParts.isEmpty ? null : descripcionParts.join('\n'),
          tareasPrevias: const [],
          area: 'Blueprint IA',
          habilidadesRequeridas: defaultSkills,
          fasePMI: null,
          entregable: 'Backlog IA',
          paqueteTrabajo: null,
        ),
      );
    }

    final hitos = blueprint['hitosPrincipales'] as List? ?? [];
    for (final item in hitos) {
      final map = item is Map ? Map<String, dynamic>.from(item) : {};
      final soft = _safeStringList(map['softSkillsClaves']);
      final riesgos = _safeStringList(map['riesgosHumanos']);
      final descripcionParts = <String>[];
      if (riesgos.isNotEmpty) {
        descripcionParts.add('Riesgos humanos: ${riesgos.join(", ")}');
      }
      if (soft.isNotEmpty) {
        descripcionParts.add('Soft skills clave: ${soft.join(", ")}');
      }
      tasks.add(
        Tarea(
          titulo: 'Hito: ${map['nombre'] ?? 'Sin nombre'}',
          fecha: DateTime.now().add(Duration(days: _parseMonth(map['mes']) * 30)),
          duracion: 30,
          prioridad: 4,
          completado: false,
          colorId: 0xFFFFB74D,
          responsables: const [],
          tipoTarea: 'Hito',
          requisitos: const {},
          dificultad: 'media',
          descripcion: descripcionParts.isEmpty ? null : descripcionParts.join('\n'),
          tareasPrevias: const [],
          area: 'Hitos',
          habilidadesRequeridas: soft.isNotEmpty ? soft : defaultSkills,
          fasePMI: null,
          entregable: 'Hito IA',
          paqueteTrabajo: null,
        ),
      );
    }

    return tasks;
  }

  List<String> _skillsFromMatrix(Map<String, dynamic> blueprint) {
    final matrix = blueprint['skillMatrixSugerida'] as List? ?? [];
    final result = <String>[];
    for (final item in matrix) {
      final map = item is Map ? Map<String, dynamic>.from(item) : {};
      final skill = map['skill'] ?? map['name'];
      if (skill is String && skill.isNotEmpty) {
        result.add(skill);
      }
      if (result.length >= 4) break;
    }
    return result;
  }

  List<String> _safeStringList(dynamic source) {
    if (source is List) {
      return source
          .whereType<String>()
          .map((e) => e.trim())
          .where((element) => element.isNotEmpty)
          .toList();
    } else if (source is String && source.isNotEmpty) {
      return [source];
    }
    return [];
  }

  int _colorForTipo(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'descubrimiento':
        return 0xFF64B5F6;
      case 'ejecucion':
        return 0xFF81C784;
      case 'seguimiento':
        return 0xFFFFD54F;
      default:
        return 0xFF90A4AE;
    }
  }

  int _parseMonth(dynamic value) {
    if (value is num) return value.toInt().clamp(1, 24);
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed.clamp(1, 24);
      }
    }
    return 1;
  }
}

class _LocalAttachment {
  final String name;
  final List<int> bytes;

  _LocalAttachment({required this.name, required this.bytes});
}

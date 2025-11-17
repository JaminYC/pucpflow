import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/project_ai_config.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/project_ai_service.dart';
import 'ProyectoDetallePage.dart';
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
  final _focusController = TextEditingController();
  final _softSkillsController = TextEditingController();
  final _driversController = TextEditingController();
  final _customContextController = TextEditingController();

  ProjectMethodology _methodology = ProjectMethodology.general;
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
    _focusController.dispose();
    _softSkillsController.dispose();
    _driversController.dispose();
    _customContextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Blueprint Contextual IA',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionTitle('Contexto del proyecto'),
              _buildTextField(
                controller: _nombreController,
                label: 'Nombre del proyecto',
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _descripcionController,
                label: 'Descripción breve / historia del usuario',
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Metodología base'),
              Wrap(
                spacing: 8,
                children: ProjectMethodology.values.map((method) {
                  final isSelected = method == _methodology;
                  return ChoiceChip(
                    label: Text(method.label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _methodology = method);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Foco estratégico'),
              _buildTextField(
                controller: _focusController,
                label: 'Áreas de enfoque (separadas por coma)',
                helper:
                    'Ejemplo: Descubrimiento de cliente, Experiencia móvil, Operaciones',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _softSkillsController,
                label: 'Soft skills prioritarias',
                helper:
                    'Ejemplo: Comunicación efectiva, Gestión del cambio, Liderazgo',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _driversController,
                label: 'Drivers de negocio',
                helper:
                    'Ejemplo: Retención de clientes, Velocidad de entrega, Innovación',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Contexto adicional'),
              _buildTextField(
                controller: _customContextController,
                label: 'Notas adicionales (JSON o párrafo libre)',
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Documentos de apoyo (PDF)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _generando ? null : _pickDocuments,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Subir documentos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${_attachments.length} archivo(s)',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ],
              ),
              if (_docError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _docError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _attachments.map((file) {
                    return Chip(
                      label: Text(
                        file.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: _generando
                          ? null
                          : () {
                              setState(() {
                                _attachments.remove(file);
                              });
                            },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _generando ? null : _generarBlueprint,
                icon: _generando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_generando
                    ? 'Generando blueprint...'
                    : 'Generar con IA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_blueprint != null) ...[
                _buildBlueprintPreview(_blueprint!),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed:
                      _creatingProject ? null : _createProjectFromBlueprint,
                  icon: _creatingProject
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.playlist_add_check),
                  label: Text(_creatingProject
                      ? 'Creando proyecto...'
                      : 'Crear proyecto desde blueprint'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Blueprint generado',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey.shade300,
              height: 1.5,
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item is String ? item : jsonEncode(item),
                style: const TextStyle(color: Colors.white70),
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
        fechaInicio: DateTime.now(),
        fechaFin: null,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
        propietario: user.uid,
        participantes: [user.uid],
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
          builder: (_) => ProyectoDetallePage(proyectoId: proyectoRef.id),
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

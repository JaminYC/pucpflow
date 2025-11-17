import 'package:flutter/material.dart';
import '../models/skill_model.dart';
import '../models/cv_profile_model.dart';
import '../services/skills_service.dart';

class ReviewSkillsPage extends StatefulWidget {
  final CVProfileModel profile;
  final List<MappedSkill> mappedSkills;

  const ReviewSkillsPage({
    super.key,
    required this.profile,
    required this.mappedSkills,
  });

  @override
  State<ReviewSkillsPage> createState() => _ReviewSkillsPageState();
}

class _ReviewSkillsPageState extends State<ReviewSkillsPage> {
  final SkillsService _skillsService = SkillsService();

  late List<MappedSkill> _selectedSkills;
  late Map<String, int> _skillLevels; // skillId -> level
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Por defecto, todas las skills encontradas están seleccionadas
    _selectedSkills = widget.mappedSkills.where((s) => s.isFound).toList();
    _skillLevels = {};
    for (var skill in _selectedSkills) {
      if (skill.dbSkillId != null) {
        _skillLevels[skill.dbSkillId!] = skill.level;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final foundSkills = widget.mappedSkills.where((s) => s.isFound).toList();
    final notFoundSkills = widget.mappedSkills.where((s) => !s.isFound).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Revisa tus Habilidades',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey.shade900,
              Colors.black,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header con info del perfil
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.shade400.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.profile.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.profile.email.isNotEmpty)
                              Text(
                                widget.profile.email,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.profile.summary.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    Text(
                      widget.profile.summary,
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Contador de skills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Habilidades detectadas: ${foundSkills.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_selectedSkills.length} seleccionadas',
                    style: TextStyle(
                      color: Colors.green.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lista de skills
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Skills encontradas
                  if (foundSkills.isNotEmpty) ...[
                    const Text(
                      'Habilidades Encontradas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...foundSkills.map((skill) => _buildSkillCard(skill)),
                  ],

                  // Skills no encontradas
                  if (notFoundSkills.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Habilidades No Encontradas en BD',
                      style: TextStyle(
                        color: Colors.orange.shade400,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade900.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade400.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade400),
                              const SizedBox(width: 8),
                              const Text(
                                'Estas habilidades no están en nuestra base de datos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: notFoundSkills.map((skill) {
                              return Chip(
                                label: Text(skill.aiSkill),
                                backgroundColor: Colors.orange.shade800.withValues(alpha: 0.3),
                                labelStyle: TextStyle(color: Colors.orange.shade200),
                                side: BorderSide(color: Colors.orange.shade400.withValues(alpha: 0.5)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 100), // Espacio para el botón flotante
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedSkills.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveSkills,
              backgroundColor: Colors.green.shade600,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(
                _isSaving ? 'Guardando...' : 'Confirmar ${_selectedSkills.length} Skills',
                style: const TextStyle(fontSize: 16),
              ),
            ),
    );
  }

  Widget _buildSkillCard(MappedSkill skill) {
    if (skill.dbSkillId == null) return const SizedBox.shrink();

    final isSelected = _selectedSkills.any((s) => s.dbSkillId == skill.dbSkillId);
    final currentLevel = _skillLevels[skill.dbSkillId] ?? skill.level;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue.shade900.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Colors.blue.shade400.withValues(alpha: 0.5)
              : Colors.grey.shade800,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleSkill(skill),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Checkbox
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade400 : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Colors.blue.shade400 : Colors.grey.shade600,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Nombre de la skill
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skill.dbSkillName ?? skill.aiSkill,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (skill.sector != null)
                            Text(
                              skill.sector!,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Badge de nivel
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getLevelColor(currentLevel),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Nivel $currentLevel',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Slider de nivel (solo si está seleccionada)
                if (isSelected) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Nivel de competencia:',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _getLevelLabel(currentLevel),
                        style: TextStyle(
                          color: _getLevelColor(currentLevel),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: _getLevelColor(currentLevel),
                      inactiveTrackColor: Colors.grey.shade800,
                      thumbColor: _getLevelColor(currentLevel),
                      overlayColor: _getLevelColor(currentLevel).withValues(alpha: 0.3),
                      valueIndicatorColor: _getLevelColor(currentLevel),
                      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                    ),
                    child: Slider(
                      value: currentLevel.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: currentLevel.toString(),
                      onChanged: (value) {
                        setState(() {
                          _skillLevels[skill.dbSkillId!] = value.toInt();
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSkill(MappedSkill skill) {
    setState(() {
      final index = _selectedSkills.indexWhere((s) => s.dbSkillId == skill.dbSkillId);
      if (index >= 0) {
        _selectedSkills.removeAt(index);
      } else {
        _selectedSkills.add(skill);
        if (skill.dbSkillId != null && !_skillLevels.containsKey(skill.dbSkillId)) {
          _skillLevels[skill.dbSkillId!] = skill.level;
        }
      }
    });
  }

  Color _getLevelColor(int level) {
    if (level <= 3) return Colors.orange.shade600;
    if (level <= 6) return Colors.blue.shade600;
    if (level <= 8) return Colors.purple.shade600;
    return Colors.green.shade600;
  }

  String _getLevelLabel(int level) {
    if (level <= 3) return 'Principiante';
    if (level <= 6) return 'Intermedio';
    if (level <= 8) return 'Avanzado';
    return 'Experto';
  }

  Future<void> _saveSkills() async {
    setState(() => _isSaving = true);

    try {
      // Preparar lista de skills confirmadas
      final confirmedSkills = _selectedSkills.map((skill) {
        return {
          'skillId': skill.dbSkillId,
          'level': _skillLevels[skill.dbSkillId] ?? skill.level,
          'notes': '',
        };
      }).toList();

      // Guardar en Firestore via Cloud Function
      final success = await _skillsService.saveConfirmedSkills(confirmedSkills);

      if (!mounted) return;

      if (success) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('${_selectedSkills.length} habilidades guardadas exitosamente'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
          ),
        );

        // Volver a la pantalla anterior después de un delay
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context); // Volver dos veces para salir del flujo completo
        }
      } else {
        throw Exception('Error al guardar las habilidades');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/skill_model.dart';
import '../services/skills_service.dart';
import 'upload_cv_page.dart';

class SkillsProfilePage extends StatefulWidget {
  const SkillsProfilePage({super.key});

  @override
  State<SkillsProfilePage> createState() => _SkillsProfilePageState();
}

class _SkillsProfilePageState extends State<SkillsProfilePage> {
  final SkillsService _skillsService = SkillsService();

  List<UserSkillModel> _userSkills = [];
  Map<String, List<UserSkillModel>> _skillsBySector = {};
  bool _isLoading = true;
  double _averageLevel = 0.0;
  Map<String, int> _levelDistribution = {};

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    setState(() => _isLoading = true);

    try {
      final skills = await _skillsService.getUserSkills();
      final skillsBySector = await _skillsService.getUserSkillsBySector();
      final average = await _skillsService.getUserAverageSkillLevel();
      final distribution = await _skillsService.getSkillLevelDistribution();

      setState(() {
        _userSkills = skills;
        _skillsBySector = skillsBySector;
        _averageLevel = average;
        _levelDistribution = distribution;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mis Habilidades Profesionales',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.white),
            tooltip: 'Cargar CV',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UploadCVPage()),
              );
              _loadSkills(); // Recargar después de volver
            },
          ),
        ],
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
            : _userSkills.isEmpty
                ? _buildEmptyState()
                : _buildSkillsContent(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 120,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 24),
            const Text(
              'No tienes habilidades registradas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Carga tu CV para extraer automáticamente tus habilidades profesionales',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadCVPage()),
                );
                _loadSkills();
              },
              icon: const Icon(Icons.upload_file),
              label: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text('Cargar CV', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsContent() {
    return RefreshIndicator(
      onRefresh: _loadSkills,
      color: Colors.blue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estadísticas generales
          _buildStatsSection(),
          const SizedBox(height: 24),

          // Gráfico de distribución
          _buildDistributionChart(),
          const SizedBox(height: 24),

          // Skills por sector
          _buildSkillsBySector(),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Skills',
                _userSkills.length.toString(),
                Icons.workspace_premium,
                Colors.blue.shade400,
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white24,
              ),
              _buildStatItem(
                'Nivel Promedio',
                _averageLevel.toStringAsFixed(1),
                Icons.trending_up,
                Colors.green.shade400,
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white24,
              ),
              _buildStatItem(
                'Sectores',
                _skillsBySector.length.toString(),
                Icons.category,
                Colors.purple.shade400,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionChart() {
    if (_levelDistribution.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.shade400.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.purple.shade400),
              const SizedBox(width: 12),
              const Text(
                'Distribución por Nivel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                // Gráfico de pastel
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),

                // Leyenda
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _levelDistribution.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _getColorForLevel(entry.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total = _levelDistribution.values.fold<int>(0, (sum, val) => sum + val);
    if (total == 0) return [];

    return _levelDistribution.entries.map((entry) {
      final percentage = (entry.value / total * 100).toStringAsFixed(0);
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '$percentage%',
        color: _getColorForLevel(entry.key),
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getColorForLevel(String levelKey) {
    if (levelKey.contains('Principiante')) return Colors.orange.shade600;
    if (levelKey.contains('Intermedio')) return Colors.blue.shade600;
    if (levelKey.contains('Avanzado')) return Colors.purple.shade600;
    return Colors.green.shade600;
  }

  Widget _buildSkillsBySector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, color: Colors.blue.shade400),
            const SizedBox(width: 12),
            const Text(
              'Habilidades por Sector',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._skillsBySector.entries.map((entry) {
          return _buildSectorCard(entry.key, entry.value);
        }),
      ],
    );
  }

  Widget _buildSectorCard(String sector, List<UserSkillModel> skills) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade800,
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getSectorIcon(sector),
              color: Colors.blue.shade400,
              size: 24,
            ),
          ),
          title: Text(
            sector,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${skills.length} habilidades',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          children: skills.map((skill) => _buildSkillItem(skill)).toList(),
        ),
      ),
    );
  }

  Widget _buildSkillItem(UserSkillModel skill) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              skill.skillName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getLevelColorForValue(skill.level),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Nivel ${skill.level}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSectorIcon(String sector) {
    final sectorLower = sector.toLowerCase();
    if (sectorLower.contains('programación') || sectorLower.contains('programacion')) {
      return Icons.code;
    } else if (sectorLower.contains('cloud')) {
      return Icons.cloud;
    } else if (sectorLower.contains('frontend')) {
      return Icons.web;
    } else if (sectorLower.contains('backend')) {
      return Icons.storage;
    } else if (sectorLower.contains('database') || sectorLower.contains('datos')) {
      return Icons.storage_outlined;
    } else if (sectorLower.contains('mobile') || sectorLower.contains('móvil')) {
      return Icons.phone_android;
    } else if (sectorLower.contains('design') || sectorLower.contains('diseño')) {
      return Icons.design_services;
    }
    return Icons.category;
  }

  Color _getLevelColorForValue(int level) {
    if (level <= 3) return Colors.orange.shade600;
    if (level <= 6) return Colors.blue.shade600;
    if (level <= 8) return Colors.purple.shade600;
    return Colors.green.shade600;
  }
}

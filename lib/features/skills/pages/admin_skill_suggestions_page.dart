import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/skill_model.dart';
import '../services/admin_skills_service.dart';
import '../services/skills_service.dart';

class AdminSkillSuggestionsPage extends StatefulWidget {
  const AdminSkillSuggestionsPage({super.key});

  @override
  State<AdminSkillSuggestionsPage> createState() => _AdminSkillSuggestionsPageState();
}

class _AdminSkillSuggestionsPageState extends State<AdminSkillSuggestionsPage> {
  final AdminSkillsService _adminService = AdminSkillsService();
  final SkillsService _skillsService = SkillsService();

  bool _isLoading = true;
  bool _isAdmin = false;
  List<SkillSuggestion> _suggestions = [];
  Map<String, int> _stats = {};
  String _selectedFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pop(context);
      return;
    }

    // Verificar si es admin
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final isAdmin = userDoc.data()?['isAdmin'] == true;

    if (!mounted) return;

    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos de administrador'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
      return;
    }

    setState(() => _isAdmin = true);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final suggestions = await _adminService.getSuggestionsByStatus(_selectedFilter);
    final stats = await _adminService.getSuggestionsStats();

    if (!mounted) return;

    setState(() {
      _suggestions = suggestions;
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Gestión de Sugerencias',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
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
        child: Column(
          children: [
            // Estadísticas
            _buildStatsSection(),

            // Filtros
            _buildFilterTabs(),

            // Lista de sugerencias
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _suggestions.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            return _buildSuggestionCard(_suggestions[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900.withValues(alpha: 0.3),
            Colors.purple.shade900.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', _stats['total'] ?? 0, Icons.inventory_2, Colors.blue),
          _buildStatItem('Pendientes', _stats['pending'] ?? 0, Icons.pending_actions, Colors.orange),
          _buildStatItem('Aprobadas', _stats['approved'] ?? 0, Icons.check_circle, Colors.green),
          _buildStatItem('Rechazadas', _stats['rejected'] ?? 0, Icons.cancel, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildFilterTabs() {
    final filters = [
      {'value': 'pending', 'label': 'Pendientes', 'icon': Icons.pending_actions},
      {'value': 'approved', 'label': 'Aprobadas', 'icon': Icons.check_circle},
      {'value': 'merged', 'label': 'Fusionadas', 'icon': Icons.merge},
      {'value': 'rejected', 'label': 'Rechazadas', 'icon': Icons.cancel},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Text(filter['label'] as String),
                ],
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: Colors.blue.shade700,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade400,
              ),
              onSelected: (selected) {
                setState(() => _selectedFilter = filter['value'] as String);
                _loadData();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay sugerencias $_selectedFilter',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(SkillSuggestion suggestion) {
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending_actions;

    switch (suggestion.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'merged':
        statusColor = Colors.purple;
        statusIcon = Icons.merge;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF101524),
            const Color(0xFF111C32),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.suggestedName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.category, color: Colors.grey.shade400, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            suggestion.suggestedSector,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${suggestion.frequency}',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info del sugeridor
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey.shade500, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Sugerido por: ${suggestion.userEmail}',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey.shade500, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(suggestion.createdAt),
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),

                // Contexto del CV
                if (suggestion.cvContext.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description, color: Colors.grey.shade500, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Contexto: ${suggestion.cvContext}',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Acciones (solo para pendientes)
                if (suggestion.status == 'pending') ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showApproveDialog(suggestion),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Aprobar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showMergeDialog(suggestion),
                          icon: const Icon(Icons.merge, size: 18),
                          label: const Text('Fusionar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showRejectDialog(suggestion),
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade900.withValues(alpha: 0.3),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ],

                // Info de revisión (para aprobadas/rechazadas/fusionadas)
                if (suggestion.status != 'pending' && suggestion.reviewedAt != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revisado el ${_formatDate(suggestion.reviewedAt!)}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                        if (suggestion.reviewedBy != null)
                          Text(
                            'Por: ${suggestion.reviewedBy}',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Diálogos de acciones

  Future<void> _showApproveDialog(SkillSuggestion suggestion) async {
    final sectorController = TextEditingController(text: suggestion.suggestedSector);
    final descriptionController = TextEditingController();

    // Buscar skills similares automáticamente
    final similarSkills = await _skillsService.searchSkills(suggestion.suggestedName);
    final allSkills = await _skillsService.getAllSkills();

    // Obtener lista de sectores únicos
    final sectors = allSkills.map((s) => s.sector).toSet().toList()..sort();

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text('Aprobar Sugerencia', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Aprobar "${suggestion.suggestedName}" como nueva skill estándar?',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Advertencia si hay skills similares
              if (similarSkills.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade700),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange.shade400, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Skills similares encontradas:',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...similarSkills.take(3).map((skill) => Padding(
                        padding: const EdgeInsets.only(left: 28, top: 4),
                        child: Text(
                          '• ${skill.name} (${skill.sector})',
                          style: TextStyle(color: Colors.orange.shade200, fontSize: 13),
                        ),
                      )),
                      if (similarSkills.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(left: 28, top: 4),
                          child: Text(
                            '... y ${similarSkills.length - 3} más',
                            style: TextStyle(color: Colors.orange.shade300, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Considera fusionar en lugar de aprobar',
                        style: TextStyle(color: Colors.orange.shade400, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Selector de sector con autocompletado
              Autocomplete<String>(
                initialValue: TextEditingValue(text: suggestion.suggestedSector),
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return sectors;
                  }
                  return sectors.where((sector) =>
                      sector.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (sector) {
                  sectorController.text = sector;
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  sectorController.text = controller.text;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Sector',
                      labelStyle: TextStyle(color: Colors.grey.shade400),
                      hintText: 'Selecciona o escribe un sector',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  hintText: 'Describe brevemente esta habilidad',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Información adicional
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contexto del CV:',
                      style: TextStyle(color: Colors.blue.shade300, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion.cvContext.isNotEmpty ? suggestion.cvContext : 'No disponible',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aprobar como Nueva Skill'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _approveSuggestion(
        suggestion.id,
        sectorController.text,
        descriptionController.text.isNotEmpty ? descriptionController.text : null,
      );
    }
  }

  Future<void> _showMergeDialog(SkillSuggestion suggestion) async {
    // Buscar skills similares automáticamente
    final searchController = TextEditingController(text: suggestion.suggestedName);
    final initialResults = await _skillsService.searchSkills(suggestion.suggestedName);
    List<SkillModel> similarSkills = initialResults;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F2E),
          title: const Text('Fusionar con Skill Existente', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de la sugerencia
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade700),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.purple.shade400, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Fusionando: ${suggestion.suggestedName}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sector sugerido: ${suggestion.suggestedSector}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                      Text(
                        'Frecuencia: ${suggestion.frequency} usuario(s)',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                      if (suggestion.cvContext.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Contexto: ${suggestion.cvContext}',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontStyle: FontStyle.italic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Búsqueda
                TextField(
                  controller: searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) async {
                    if (value.length > 2) {
                      final results = await _skillsService.searchSkills(value);
                      setState(() => similarSkills = results);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Buscar skill existente',
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    hintText: 'Escribe para buscar...',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () async {
                              searchController.clear();
                              final results = await _skillsService.searchSkills(suggestion.suggestedName);
                              setState(() => similarSkills = results);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Resultados
                if (similarSkills.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No se encontraron skills. Prueba con otro término.',
                        style: TextStyle(color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    '${similarSkills.length} skill(s) encontrada(s):',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade800),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: similarSkills.length,
                      itemBuilder: (context, index) {
                        final skill = similarSkills[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: index > 0
                                ? Border(top: BorderSide(color: Colors.grey.shade900))
                                : null,
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade900.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                skill.sector,
                                style: TextStyle(color: Colors.blue.shade300, fontSize: 10),
                              ),
                            ),
                            title: Text(
                              skill.name,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            subtitle: skill.description != null
                                ? Text(
                                    skill.description!,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: const Icon(Icons.merge_type, color: Colors.white70, size: 20),
                            onTap: () {
                              Navigator.pop(context);
                              _mergeSuggestion(suggestion.id, skill.id);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(SkillSuggestion suggestion) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade400),
            const SizedBox(width: 8),
            const Text('Rechazar Sugerencia', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de rechazar esta sugerencia?',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 16),

            // Información de la sugerencia
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade700.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.red.shade300, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion.suggestedName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.category, 'Sector', suggestion.suggestedSector),
                  _buildInfoRow(Icons.person_outline, 'Sugerido por', suggestion.userEmail),
                  _buildInfoRow(Icons.trending_up, 'Frecuencia', '${suggestion.frequency} usuario(s)'),
                  if (suggestion.cvContext.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Contexto:',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion.cvContext,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontStyle: FontStyle.italic),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Advertencia
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade900.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade400, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La sugerencia se guardará como rechazada para análisis futuro',
                      style: TextStyle(color: Colors.orange.shade300, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar Definitivamente'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _rejectSuggestion(suggestion.id);
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 14),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Acciones

  Future<void> _approveSuggestion(String suggestionId, String sector, String? description) async {
    final result = await _adminService.approveSuggestion(
      suggestionId: suggestionId,
      sector: sector,
      description: description,
    );

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al aprobar sugerencia'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _mergeSuggestion(String suggestionId, String mergeWithSkillId) async {
    final result = await _adminService.mergeSuggestion(
      suggestionId: suggestionId,
      mergeWithSkillId: mergeWithSkillId,
    );

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.purple,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al fusionar sugerencia'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectSuggestion(String suggestionId) async {
    final result = await _adminService.rejectSuggestion(suggestionId: suggestionId);

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.orange,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al rechazar sugerencia'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

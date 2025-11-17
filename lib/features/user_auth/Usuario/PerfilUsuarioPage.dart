// ðŸ“„ PERFIL DE USUARIO PROFESIONAL - perfil_usuario_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pucpflow/features/user_auth/Usuario/UserModel.dart';
import 'package:pucpflow/features/user_auth//firebase_auth_implementation/firebase_auth_services.dart';
import 'package:pucpflow/features/user_auth/Usuario/OpenAIAssistantService.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:video_player/video_player.dart';
import 'package:pucpflow/features/skills/pages/upload_cv_page.dart';
import 'package:pucpflow/features/skills/services/skills_service.dart';
import 'package:pucpflow/features/skills/models/skill_model.dart';

class PerfilUsuarioPage extends StatefulWidget {
  final String uid;

  const PerfilUsuarioPage({super.key, required this.uid});

  @override
  State<PerfilUsuarioPage> createState() => _PerfilUsuarioPageState();
}

class _PerfilUsuarioPageState extends State<PerfilUsuarioPage> with SingleTickerProviderStateMixin {
  UserModel? user;
  bool loading = true;
  late VideoPlayerController _videoController;
  late TabController _tabController;
  final TextEditingController _tipoController = TextEditingController();
  final SkillsService _skillsService = SkillsService();

  List<UserSkillModel> _professionalSkills = [];
  Map<String, List<UserSkillModel>> _skillsBySector = {};
  bool _loadingSkills = true;

  Map<String, List<String>> categorias = {
    "Cognitivas": ["pensamiento_logico", "planeamiento_estrategico", "toma_de_decisiones"],
    "Organizativas": ["gestion_del_tiempo", "planificacion", "seguimiento"],
    "Creativas": ["propuesta_de_ideas", "diseno_visual", "comunicacion_escrita"],
    "Interpersonales": ["comunicacion_efectiva", "empatia", "liderazgo"],
    "Adaptativas": ["aprendizaje_rapido", "resolucion_de_conflictos", "autonomia"]
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _videoController = VideoPlayerController.asset("assets/background.mp4")
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController.play();
        }
      }).catchError((error) {
        // Si falla el video, continuamos sin Ã©l
        print('Error inicializando video: $error');
      });
    cargarUsuario();
    _cargarSkillsProfesionales();
  }

  Future<void> _cargarSkillsProfesionales() async {
    setState(() => _loadingSkills = true);
    try {
      final skills = await _skillsService.getUserSkills();
      final skillsBySector = await _skillsService.getUserSkillsBySector();
      setState(() {
        _professionalSkills = skills;
        _skillsBySector = skillsBySector;
        _loadingSkills = false;
      });
    } catch (e) {
      setState(() => _loadingSkills = false);
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _tipoController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> cargarUsuario() async {
    final data = await FirebaseAuthService().getUserFromFirestore(widget.uid);
    setState(() {
      user = data;
      loading = false;
      _tipoController.text = user?.tipoPersonalidad ?? "";
    });
  }

  Future<void> actualizarPerfilConIA() async {
    if (user != null) {
      setState(() => loading = true);
      user!.tipoPersonalidad = _tipoController.text;
      await OpenAIAssistantService().generarResumenYHabilidades(user!);
      await cargarUsuario();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || user == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue.shade400),
              const SizedBox(height: 20),
              const Text(
                "Cargando perfil...",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video background
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),

          // Overlay gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),

          // Content
          CustomScrollView(
            slivers: [
              // App Bar con foto de perfil
              SliverAppBar(
                expandedHeight: 300,
                floating: false,
                pinned: true,
                backgroundColor: Colors.black.withValues(alpha: 0.9),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(),
                  centerTitle: true,
                ),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: Colors.blue.shade400,
                    indicatorWeight: 2,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    padding: EdgeInsets.zero,
                    tabs: const [
                      Tab(icon: Icon(Icons.dashboard, size: 20), text: "Overview", height: 60),
                      Tab(icon: Icon(Icons.workspace_premium, size: 20), text: "Skills", height: 60),
                      Tab(icon: Icon(Icons.analytics, size: 20), text: "AnÃ¡lisis", height: 60),
                    ],
                  ),
                ),
              ),

              // Tab content
              SliverFillRemaining(
                hasScrollBody: true,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildSkillsTab(),
                    _buildAnalysisTab(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================
  // ðŸ“¸ HEADER CON FOTO DE PERFIL
  // ========================================
  Widget _buildHeader() {
    final resumenCompacto = (user!.resumenIA ?? user!.metasPersonales ?? "").trim();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900.withValues(alpha: 0.35),
            Colors.deepPurple.shade900.withValues(alpha: 0.45),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Align(
                alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user, color: Colors.blue.shade200, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Perfil del talento',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade400, Colors.purple.shade400],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade400.withValues(alpha: 0.35),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 58,
                            backgroundColor: Colors.black,
                            child: ClipOval(
                              child: SizedBox(
                                width: 110,
                                height: 110,
                                child: user?.fotoPerfil != null
                                    ? Image.network(
                                        user!.fotoPerfil!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildInitialsAvatar(),
                                      )
                                    : _buildInitialsAvatar(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      Text(
                        user!.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user!.correoElectronico,
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      if ((user!.tipoPersonalidad ?? "").isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.purple.shade200.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.psychology_outlined, color: Colors.purple.shade200, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                user!.tipoPersonalidad!.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if ((user!.tipoPersonalidad ?? "").isNotEmpty) const SizedBox(height: 12),
                      if (resumenCompacto.isNotEmpty)
                        Text(
                          resumenCompacto,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      if (resumenCompacto.isNotEmpty) const SizedBox(height: 18),
                      Container(height: 1, width: double.infinity, color: Colors.white.withValues(alpha: 0.08)),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildQuickStat(Icons.workspace_premium, "${_professionalSkills.length}", "Skills"),
                          _buildQuickStat(Icons.star_rate_rounded, "${user!.puntosTotales}", "Puntos"),
                          _buildQuickStat(Icons.task_alt_outlined, "${user!.tareasHechas.length}", "Tareas"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blue.shade300, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // ========================================
  // ðŸ“Š TAB 1: OVERVIEW
  // ========================================
  Widget _buildOverviewTab() {
    final objetivo = user!.objetivoAprendizaje.trim();
    final meta = user!.metasPersonales.trim();
    final resumenExtenso = user!.resumenIA?.trim();
    final totalTareas = user!.tareasAsignadas.length + user!.tareasHechas.length + user!.tareasPorHacer.length;
    final completion = totalTareas == 0 ? 0.0 : user!.tareasHechas.length / totalTareas;

    final taskStats = <_DashboardStatData>[
      _DashboardStatData(
        icon: Icons.assignment_outlined,
        label: "Asignadas",
        value: "${user!.tareasAsignadas.length}",
        color: Colors.orange.shade400,
        description: "Preparadas para ejecutar",
      ),
      _DashboardStatData(
        icon: Icons.check_circle_outline,
        label: "Completadas",
        value: "${user!.tareasHechas.length}",
        color: Colors.green.shade400,
        description: "Entregas validadas",
      ),
      _DashboardStatData(
        icon: Icons.splitscreen_outlined,
        label: "Por hacer",
        value: "${user!.tareasPorHacer.length}",
        color: Colors.blue.shade400,
        description: "Pendientes priorizadas",
      ),
      _DashboardStatData(
        icon: Icons.trending_up,
        label: "Avance general",
        value: "${(completion * 100).round()}%",
        color: Colors.cyan.shade400,
        description: "Completadas sobre el total",
        progress: completion,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionTitle(
          "Dashboard de tareas",
          subtitle: "Estado general y proximos pasos",
        ),
        Text(
          "Visualiza el balance de asignaciones, entregas y progreso para priorizar acciones.",
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
        const SizedBox(height: 12),
        _buildResponsiveStatsGrid(taskStats),
        const SizedBox(height: 16),
        _buildModernCard(
          title: "Listado de tareas",
          icon: Icons.view_timeline,
          color: Colors.green.shade400,
          child: Column(
            children: [
              _buildTaskStatusList("Asignadas", user!.tareasAsignadas, Colors.orange.shade300),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.05), margin: const EdgeInsets.symmetric(vertical: 12)),
              _buildTaskStatusList("Completadas", user!.tareasHechas, Colors.green.shade400),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.05), margin: const EdgeInsets.symmetric(vertical: 12)),
              _buildTaskStatusList("Por hacer", user!.tareasPorHacer, Colors.blue.shade400),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildActionButtons(),
        const SizedBox(height: 32),
        _buildSectionTitle(
          "Perfil profesional",
          subtitle: "Informacion clave del usuario",
        ),
        _buildModernCard(
          title: "Identidad del talento",
          icon: Icons.badge_outlined,
          color: Colors.purple.shade400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tipo de personalidad",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _tipoController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Ej: INTJ, ENFP, ISTJ...",
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.psychology, color: Colors.purple.shade200, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildInfoChip(Icons.mail_outline, user!.correoElectronico, Colors.blue.shade300),
                  if (objetivo.isNotEmpty) _buildInfoChip(Icons.rocket_launch_outlined, objetivo, Colors.orange.shade300),
                  if (meta.isNotEmpty) _buildInfoChip(Icons.flag_outlined, meta, Colors.green.shade300),
                ],
              ),
            ],
          ),
        ),
        if (resumenExtenso != null && resumenExtenso.isNotEmpty)
          _buildModernCard(
            title: "Narrativa generada por IA",
            icon: Icons.auto_awesome,
            color: Colors.blue.shade400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resumenExtenso,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 12),
                Text(
                  "Actualiza con IA para refrescar insights.",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildInitialsAvatar() {
    return Container(
      color: Colors.grey.shade800,
      child: Center(
        child: Text(
          user!.nombre.isNotEmpty ? user!.nombre[0].toUpperCase() : 'U',
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveStatsGrid(List<_DashboardStatData> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth >= 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) => _buildStatCard(stats[index]),
        );
      },
    );
  }

Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: actualizarPerfilConIA,
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text("Actualizar perfil con IA"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildStatCard(_DashboardStatData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(height: 14),
          Text(
            data.label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12, letterSpacing: 0.2),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (data.progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: data.progress!.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.grey.shade800,
                valueColor: AlwaysStoppedAnimation<Color>(data.color),
              ),
            ),
          ],
          if (data.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                data.description!,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskStatusList(String title, List<String> tasks, Color color) {
    final preview = tasks.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$title (${tasks.length})",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 20),
          ],
        ),
        const SizedBox(height: 8),
        if (preview.isEmpty)
          Text(
            "Sin elementos registrados",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          )
        else
          ...preview.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (tasks.length > preview.length)
          Text(
            "+${tasks.length - preview.length} adicionales",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
      ],
    );
  }
  Widget _buildTaskRow(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade300, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$count",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // ðŸ’¼ TAB 2: SKILLS PROFESIONALES
  // ========================================
  Widget _buildSkillsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        // Header con botÃ³n de cargar CV
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Habilidades Profesionales",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadCVPage()),
                );
                _cargarSkillsProfesionales();
              },
              icon: const Icon(Icons.upload_file, size: 20),
              label: const Text("Cargar CV"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (_loadingSkills)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          )
        else if (_professionalSkills.isEmpty)
          _buildEmptySkillsState()
        else
          _buildProfessionalSkillsContent(),
      ],
    );
  }

  Widget _buildEmptySkillsState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.description_outlined, size: 60, color: Colors.blue.shade300),
          ),
          const SizedBox(height: 24),
          const Text(
            "No tienes habilidades profesionales registradas",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Carga tu CV en formato PDF y nuestra IA extraerÃ¡ automÃ¡ticamente tus habilidades con niveles de competencia",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UploadCVPage()),
              );
              _cargarSkillsProfesionales();
            },
            icon: const Icon(Icons.upload_file, size: 24),
            label: const Text("Cargar CV Ahora", style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalSkillsContent() {
    return Column(
      children: [
        // Stats card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade600.withValues(alpha: 0.3),
                Colors.purple.shade600.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn("Total Skills", "${_professionalSkills.length}", Icons.workspace_premium, Colors.blue.shade300),
              Container(width: 2, height: 50, color: Colors.white24),
              _buildStatColumn("Nivel Promedio", _getAverageLevel().toStringAsFixed(1), Icons.trending_up, Colors.green.shade300),
              Container(width: 2, height: 50, color: Colors.white24),
              _buildStatColumn("Sectores", "${_skillsBySector.length}", Icons.category, Colors.purple.shade300),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Skills por sector
        ..._skillsBySector.entries.map((entry) {
          return _buildSectorCard(entry.key, entry.value);
        }),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectorCard(String sector, List<UserSkillModel> skills) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600.withValues(alpha: 0.5),
                  Colors.blue.shade800.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getSectorIcon(sector), color: Colors.white, size: 24),
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
            "${skills.length} habilidades",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: skills.map((skill) => _buildSkillRow(skill)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillRow(UserSkillModel skill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  skill.skillName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getLevelColor(skill.level),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${skill.level}/10",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: skill.level / 10,
              minHeight: 8,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor(skill.level)),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // ðŸ“ˆ TAB 3: ANÃLISIS
  // ========================================
  Widget _buildAnalysisTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        const Text(
          "Dashboard de Habilidades",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Radar chart
        _buildModernCard(
          title: "AnÃ¡lisis de Competencias",
          icon: Icons.radar,
          color: Colors.cyan.shade400,
          child: SizedBox(
            height: 300,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    dataEntries: _generarRadarData(),
                    fillColor: Colors.blue.withValues(alpha: 0.5),
                    borderColor: Colors.cyan.shade400,
                    borderWidth: 3,
                    entryRadius: 4,
                  )
                ],
                radarBackgroundColor: Colors.transparent,
                titleTextStyle: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                getTitle: (index, _) => RadarChartTitle(text: categorias.keys.elementAt(index)),
                tickCount: 6,
                ticksTextStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                tickBorderData: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                gridBorderData: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
            ),
          ),
        ),

        // Desglose por categorÃ­a
        const SizedBox(height: 20),
        const Text(
          "Desglose por CategorÃ­a",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        ...categorias.entries.map((entry) {
          final promedio = entry.value.map((s) => user!.habilidades[s] ?? 0).fold(0, (a, b) => a + b) / entry.value.length;
          return _buildCategoryProgressCard(entry.key, promedio);
        }),
      ],
    );
  }

  List<RadarEntry> _generarRadarData() {
    return categorias.entries.map((entry) {
      final subSkills = entry.value;
      final promedio = subSkills.map((s) => user!.habilidades[s] ?? 0).fold(0, (a, b) => a + b) / subSkills.length;
      return RadarEntry(value: promedio.toDouble());
    }).toList();
  }

  Widget _buildCategoryProgressCard(String category, double value) {
    final color = _getCategoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "${value.toStringAsFixed(1)}/5",
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value / 5,
              minHeight: 10,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Cognitivas":
        return Colors.blue.shade400;
      case "Organizativas":
        return Colors.green.shade400;
      case "Creativas":
        return Colors.purple.shade400;
      case "Interpersonales":
        return Colors.orange.shade400;
      case "Adaptativas":
        return Colors.cyan.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  // ========================================
  // ðŸŽ¨ WIDGETS REUTILIZABLES
  // ========================================
  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    if (level <= 3) return Colors.orange.shade600;
    if (level <= 6) return Colors.blue.shade600;
    if (level <= 8) return Colors.purple.shade600;
    return Colors.green.shade600;
  }

  double _getAverageLevel() {
    if (_professionalSkills.isEmpty) return 0.0;
    final sum = _professionalSkills.fold<int>(0, (sum, skill) => sum + skill.level);
    return sum / _professionalSkills.length;
  }

  IconData _getSectorIcon(String sector) {
    final sectorLower = sector.toLowerCase();
    if (sectorLower.contains('programaciÃ³n') || sectorLower.contains('programacion')) {
      return Icons.code;
    } else if (sectorLower.contains('cloud')) {
      return Icons.cloud;
    } else if (sectorLower.contains('frontend')) {
      return Icons.web;
    } else if (sectorLower.contains('backend')) {
      return Icons.storage;
    } else if (sectorLower.contains('mobile') || sectorLower.contains('mÃ³vil')) {
      return Icons.phone_android;
    } else if (sectorLower.contains('design') || sectorLower.contains('diseÃ±o')) {
      return Icons.design_services;
    } else if (sectorLower.contains('data') || sectorLower.contains('datos')) {
      return Icons.analytics;
    }
    return Icons.category;
  }
}

class _DashboardStatData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? description;
  final double? progress;

  const _DashboardStatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.description,
    this.progress,
  });
}

// ========================================
// ðŸ“Œ STICKY TAB BAR DELEGATE
// ========================================
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar child;

  _StickyTabBarDelegate(this.child);

  @override
  double get minExtent => 60.0;
  @override
  double get maxExtent => 60.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black.withValues(alpha: 0.95),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}


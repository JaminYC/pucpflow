// 🎨 CONFIGURACIÓN Y PREFERENCIAS MODERNAS - profile_preferences_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pucpflow/global/common/toast.dart';

class ProfilePreferencesPage extends StatefulWidget {
  final String userId;

  const ProfilePreferencesPage({super.key, required this.userId});

  @override
  _ProfilePreferencesPageState createState() => _ProfilePreferencesPageState();
}

class _ProfilePreferencesPageState extends State<ProfilePreferencesPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoading = true;
  int _selectedIndex = 0;

  // ========================================
  // 🎯 VARIABLES DE PREFERENCIAS PERSONALES
  // ========================================
  String _selectedOccupation = 'Estudiante';
  String _selectedSleepHours = '6-7 horas';
  String _selectedExerciseFrequency = '3-4 veces por semana';
  String _selectedRecreationalTime = '30-60 minutos';
  String _selectedShortTermGoal = 'Mejorar salud física';
  String _selectedLongTermGoal = 'Estabilidad financiera';

  // ========================================
  // 🔔 VARIABLES DE NOTIFICACIONES
  // ========================================
  bool _briefingDiarioEnabled = true;
  String _briefingTime = '08:00';
  bool _tareasVencenEnabled = true;
  bool _nuevaAsignacionEnabled = true;
  bool _recordatorioProyectosEnabled = true;

  // ========================================
  // 🎨 VARIABLES DE PERSONALIZACIÓN
  // ========================================
  String _selectedTheme = 'Sistema';
  String _selectedLanguage = 'Español';
  bool _mostrarPomodoroEnHeader = true;
  bool _mostrarCalendarioEnHeader = true;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception("El documento del usuario no existe en Firestore.");
      }

      final data = docSnapshot.data()!;

      setState(() {
        // Preferencias personales
        _selectedOccupation = data['occupation'] ?? _selectedOccupation;
        _selectedSleepHours = data['daily_routines']?['sleep_hours'] ?? _selectedSleepHours;
        _selectedExerciseFrequency = data['daily_routines']?['exercise_frequency'] ?? _selectedExerciseFrequency;
        _selectedRecreationalTime = data['daily_routines']?['recreational_time'] ?? _selectedRecreationalTime;
        _selectedShortTermGoal = data['goals']?['short_term'] ?? _selectedShortTermGoal;
        _selectedLongTermGoal = data['goals']?['long_term'] ?? _selectedLongTermGoal;

        // Notificaciones
        _briefingDiarioEnabled = data['notifications']?['briefing_enabled'] ?? true;
        _briefingTime = data['notifications']?['briefing_time'] ?? '08:00';
        _tareasVencenEnabled = data['notifications']?['tareas_vencen'] ?? true;
        _nuevaAsignacionEnabled = data['notifications']?['nueva_asignacion'] ?? true;
        _recordatorioProyectosEnabled = data['notifications']?['recordatorio_proyectos'] ?? true;

        // Personalización
        _selectedTheme = data['preferences']?['theme'] ?? 'Sistema';
        _selectedLanguage = data['preferences']?['language'] ?? 'Español';
        _mostrarPomodoroEnHeader = data['preferences']?['show_pomodoro_header'] ?? true;
        _mostrarCalendarioEnHeader = data['preferences']?['show_calendar_header'] ?? true;
      });
    } catch (e) {
      showToast(message: "Error al cargar las preferencias: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserPreferences() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

      await docRef.set({
        'occupation': _selectedOccupation,
        'daily_routines': {
          'sleep_hours': _selectedSleepHours,
          'exercise_frequency': _selectedExerciseFrequency,
          'recreational_time': _selectedRecreationalTime,
        },
        'goals': {
          'short_term': _selectedShortTermGoal,
          'long_term': _selectedLongTermGoal,
        },
        'notifications': {
          'briefing_enabled': _briefingDiarioEnabled,
          'briefing_time': _briefingTime,
          'tareas_vencen': _tareasVencenEnabled,
          'nueva_asignacion': _nuevaAsignacionEnabled,
          'recordatorio_proyectos': _recordatorioProyectosEnabled,
        },
        'preferences': {
          'theme': _selectedTheme,
          'language': _selectedLanguage,
          'show_pomodoro_header': _mostrarPomodoroEnHeader,
          'show_calendar_header': _mostrarCalendarioEnHeader,
        },
      }, SetOptions(merge: true));

      showToast(message: "✅ Preferencias guardadas exitosamente");
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      showToast(message: "❌ Error al guardar las preferencias: $e");
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Configuración",
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.grey.shade900,
                    Colors.black,
                  ],
                ),
              ),
              child: Form(
                key: _formKey,
                child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
              ),
            ),
    );
  }

  // ========================================
  // 📱 LAYOUT MÓVIL (VERTICAL)
  // ========================================
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Navegación horizontal con scroll
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _buildNavChip(0, Icons.person_outline, "Personal"),
              _buildNavChip(1, Icons.notifications_outlined, "Notificaciones"),
              _buildNavChip(2, Icons.palette_outlined, "Apariencia"),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildContent(_selectedIndex),
          ),
        ),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildNavChip(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.shade600
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.blue.shade400
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade400,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade400,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // 💻 LAYOUT DESKTOP (HORIZONTAL)
  // ========================================
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar izquierdo
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(
              right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.purple.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.settings, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Preferencias",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Personaliza tu experiencia",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildSidebarItem(0, Icons.person_outline, "Personal", "Información y rutinas"),
                    _buildSidebarItem(1, Icons.notifications_outlined, "Notificaciones", "Alertas y recordatorios"),
                    _buildSidebarItem(2, Icons.palette_outlined, "Apariencia", "Tema e idioma"),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Contenido principal
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: _buildContent(_selectedIndex),
                  ),
                ),
              ),
              _buildSaveButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title, String subtitle) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.shade900.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.blue.shade400.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.shade400.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.blue.shade300 : Colors.grey.shade500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade400,
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.chevron_right, color: Colors.blue.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // 📄 CONTENIDO SEGÚN SECCIÓN
  // ========================================
  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return _buildPersonalTab();
      case 1:
        return _buildNotificationsTab();
      case 2:
        return _buildAppearanceTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ========================================
  // 👤 TAB 1: PREFERENCIAS PERSONALES
  // ========================================
  Widget _buildPersonalTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.work_outline,
          title: "Información profesional",
          subtitle: "Define tu contexto laboral y académico",
        ),
        const SizedBox(height: 16),
        _buildModernDropdown(
          label: "Ocupación actual",
          value: _selectedOccupation,
          icon: Icons.badge_outlined,
          items: const ["Estudiante", "Empleado", "Independiente", "Desempleado"],
          onChanged: (value) => setState(() => _selectedOccupation = value!),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader(
          icon: Icons.self_improvement,
          title: "Rutinas diarias",
          subtitle: "Optimiza tu tiempo y energía",
        ),
        const SizedBox(height: 16),
        _buildModernDropdown(
          label: "Horas de sueño promedio",
          value: _selectedSleepHours,
          icon: Icons.bedtime_outlined,
          items: const ["Menos de 5 horas", "6-7 horas", "8 horas o más"],
          onChanged: (value) => setState(() => _selectedSleepHours = value!),
        ),
        const SizedBox(height: 16),
        _buildModernDropdown(
          label: "Frecuencia de ejercicio",
          value: _selectedExerciseFrequency,
          icon: Icons.fitness_center_outlined,
          items: const [
            "Nunca",
            "1-2 veces por semana",
            "3-4 veces por semana",
            "5 o más veces por semana"
          ],
          onChanged: (value) => setState(() => _selectedExerciseFrequency = value!),
        ),
        const SizedBox(height: 16),
        _buildModernDropdown(
          label: "Tiempo recreativo diario",
          value: _selectedRecreationalTime,
          icon: Icons.beach_access_outlined,
          items: const ["Menos de 30 minutos", "30-60 minutos", "Más de 1 hora"],
          onChanged: (value) => setState(() => _selectedRecreationalTime = value!),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader(
          icon: Icons.flag_outlined,
          title: "Metas y objetivos",
          subtitle: "Define tus prioridades",
        ),
        const SizedBox(height: 16),
        _buildModernDropdown(
          label: "Meta a corto plazo",
          value: _selectedShortTermGoal,
          icon: Icons.trending_up_outlined,
          items: const [
            "Mejorar salud física",
            "Aprender una nueva habilidad",
            "Ahorrar dinero",
            "Completar un proyecto importante",
          ],
          onChanged: (value) => setState(() => _selectedShortTermGoal = value!),
        ),
        const SizedBox(height: 16),
        _buildModernDropdown(
          label: "Meta a largo plazo",
          value: _selectedLongTermGoal,
          icon: Icons.emoji_events_outlined,
          items: const [
            "Estabilidad financiera",
            "Viajar por el mundo",
            "Lograr equilibrio personal",
            "Desarrollo profesional",
          ],
          onChanged: (value) => setState(() => _selectedLongTermGoal = value!),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ========================================
  // 🔔 TAB 2: NOTIFICACIONES
  // ========================================
  Widget _buildNotificationsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.wb_sunny_outlined,
          title: "Briefing Diario",
          subtitle: "Comienza tu día organizado",
        ),
        const SizedBox(height: 16),
        _buildModernSwitch(
          label: "Activar Briefing Diario",
          subtitle: "Recibe tu resumen de tareas cada mañana",
          value: _briefingDiarioEnabled,
          icon: Icons.event_note,
          onChanged: (value) => setState(() => _briefingDiarioEnabled = value),
        ),
        if (_briefingDiarioEnabled) ...[
          const SizedBox(height: 16),
          _buildTimeSelector(
            label: "Hora del Briefing",
            value: _briefingTime,
            icon: Icons.access_time,
            onChanged: (value) => setState(() => _briefingTime = value),
          ),
        ],
        const SizedBox(height: 32),
        _buildSectionHeader(
          icon: Icons.task_outlined,
          title: "Recordatorios de tareas",
          subtitle: "Mantente al día con tus compromisos",
        ),
        const SizedBox(height: 16),
        _buildModernSwitch(
          label: "Tareas próximas a vencer",
          subtitle: "Te avisaremos 24 horas antes del deadline",
          value: _tareasVencenEnabled,
          icon: Icons.alarm,
          onChanged: (value) => setState(() => _tareasVencenEnabled = value),
        ),
        const SizedBox(height: 16),
        _buildModernSwitch(
          label: "Nueva asignación de tarea",
          subtitle: "Notificación cuando te asignen una nueva tarea",
          value: _nuevaAsignacionEnabled,
          icon: Icons.assignment_turned_in_outlined,
          onChanged: (value) => setState(() => _nuevaAsignacionEnabled = value),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader(
          icon: Icons.folder_outlined,
          title: "Proyectos",
          subtitle: "Seguimiento de proyectos activos",
        ),
        const SizedBox(height: 16),
        _buildModernSwitch(
          label: "Recordatorios de proyectos",
          subtitle: "Mantente informado del progreso de tus proyectos",
          value: _recordatorioProyectosEnabled,
          icon: Icons.business_center_outlined,
          onChanged: (value) => setState(() => _recordatorioProyectosEnabled = value),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ========================================
  // 🎨 TAB 3: APARIENCIA Y PERSONALIZACIÓN
  // ========================================
  Widget _buildAppearanceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.color_lens_outlined,
          title: "Tema visual",
          subtitle: "Personaliza la apariencia de FLOW",
        ),
        const SizedBox(height: 16),
        _buildModernDropdown(
          label: "Tema de la aplicación",
          value: _selectedTheme,
          icon: Icons.brightness_6_outlined,
          items: const ["Sistema", "Claro", "Oscuro"],
          onChanged: (value) => setState(() => _selectedTheme = value!),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader(
          icon: Icons.language_outlined,
          title: "Idioma y región",
          subtitle: "Configura tu experiencia local",
        ),
        const SizedBox(height: 16),
        _buildModernDropdown(
          label: "Idioma de la aplicación",
          value: _selectedLanguage,
          icon: Icons.translate,
          items: const ["Español", "English", "Português"],
          onChanged: (value) => setState(() => _selectedLanguage = value!),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader(
          icon: Icons.dashboard_customize_outlined,
          title: "Barra de navegación",
          subtitle: "Personaliza los accesos rápidos",
        ),
        const SizedBox(height: 16),
        _buildModernSwitch(
          label: "Mostrar Pomodoro en header",
          subtitle: "Acceso rápido al temporizador Pomodoro",
          value: _mostrarPomodoroEnHeader,
          icon: Icons.timer_outlined,
          onChanged: (value) => setState(() => _mostrarPomodoroEnHeader = value),
        ),
        const SizedBox(height: 16),
        _buildModernSwitch(
          label: "Mostrar Calendario en header",
          subtitle: "Acceso rápido a tus eventos",
          value: _mostrarCalendarioEnHeader,
          icon: Icons.calendar_today_outlined,
          onChanged: (value) => setState(() => _mostrarCalendarioEnHeader = value),
        ),
        const SizedBox(height: 32),
        _buildDangerZone(),
        const SizedBox(height: 20),
      ],
    );
  }

  // ========================================
  // 🎨 WIDGETS REUTILIZABLES
  // ========================================
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900.withValues(alpha: 0.3),
            Colors.purple.shade900.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade700.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade400.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue.shade300, size: 24),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required String value,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue.shade300, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade300,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DropdownButtonFormField<String>(
              value: value,
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
              dropdownColor: Colors.grey.shade900,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSwitch({
    required String label,
    required String subtitle,
    required bool value,
    required IconData icon,
    required void Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? Colors.blue.shade400.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: value
                  ? Colors.blue.shade400.withValues(alpha: 0.2)
                  : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: value ? Colors.blue.shade300 : Colors.grey.shade500,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue.shade400,
            activeTrackColor: Colors.blue.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required String value,
    required IconData icon,
    required void Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade400.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade400.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue.shade300, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: int.parse(value.split(':')[0]),
                  minute: int.parse(value.split(':')[1]),
                ),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: Colors.blue.shade400,
                        surface: Colors.grey.shade900,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                onChanged(formatted);
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.shade900.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.blue.shade300,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit, color: Colors.blue.shade300, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade700.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.red.shade400, size: 24),
              const SizedBox(width: 12),
              const Text(
                "Zona de peligro",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey.shade900,
                    title: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.orange.shade400),
                        const SizedBox(width: 12),
                        const Text(
                          "Cerrar sesión",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    content: const Text(
                      "¿Estás seguro que deseas cerrar sesión?",
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancelar"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                        ),
                        child: const Text("Cerrar sesión"),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              },
              icon: Icon(Icons.logout, color: Colors.orange.shade400),
              label: const Text("Cerrar sesión"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade400,
                side: BorderSide(color: Colors.orange.shade400.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey.shade900,
                    title: Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red.shade400),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: Text(
                            "Eliminar cuenta",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    content: const Text(
                      "⚠️ ADVERTENCIA: Esta acción es irreversible. Se eliminarán todos tus datos, proyectos y tareas permanentemente.\n\n¿Estás completamente seguro?",
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancelar"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                        ),
                        child: const Text("Eliminar cuenta"),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    // Eliminar datos del usuario en Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .delete();

                    // Eliminar cuenta de Firebase Auth
                    await FirebaseAuth.instance.currentUser?.delete();

                    if (mounted) {
                      showToast(message: "Cuenta eliminada exitosamente");
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  } catch (e) {
                    showToast(message: "Error al eliminar la cuenta: $e");
                  }
                }
              },
              icon: Icon(Icons.delete_forever, color: Colors.red.shade400),
              label: const Text("Eliminar cuenta"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                side: BorderSide(color: Colors.red.shade400.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveUserPreferences,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined, size: 20),
          label: Text(
            _isSaving ? "Guardando..." : "Guardar cambios",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

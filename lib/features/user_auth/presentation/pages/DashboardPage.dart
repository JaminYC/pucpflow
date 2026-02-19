
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pucpflow/features/user_auth/Usuario/UserModel.dart';
import 'package:pucpflow/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:pucpflow/features/user_auth/tarea_service.dart';
import 'package:pucpflow/utils/notificaciones_bell_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loadingTasks = true;
  bool _loadingUser = true;
  UserModel? _userData;
  final TareaService _tareaService = TareaService();

  List<_TaskCompletion> _taskCompletions = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCompletedTasks();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingUser = false);
      return;
    }

    try {
      // Sincronizar tareas primero
      await _tareaService.sincronizarTareasDeUsuario(uid);

      // Cargar datos del usuario
      final userData = await FirebaseAuthService().getUserFromFirestore(uid);
      if (mounted) {
        setState(() {
          _userData = userData;
          _loadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingUser = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF050915),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Mi Progreso Integral',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
        actions: [
          const NotificacionesBell(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadUserData();
              _loadCompletedTasks();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(theme),
              const SizedBox(height: 24),
              _buildQuickStats(),
              const SizedBox(height: 24),
              _buildSectionHeader('Progreso de tareas', 'Días y horas en que cierras pendientes'),
              const SizedBox(height: 12),
              _buildTaskProgress(),
              const SizedBox(height: 28),
              _buildSectionHeader('Análisis de Productividad', 'Descubre tus mejores días y horarios'),
              const SizedBox(height: 12),
              _buildProductivityAnalysis(),
              const SizedBox(height: 32),
              _buildSectionHeader('Timeline de Tareas', 'Historial de tareas completadas'),
              const SizedBox(height: 12),
              _buildTaskTimeline(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    if (_loadingUser || _userData == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF133E87), Color(0xFF0B192F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Calcular progreso basado en tareas completadas
    final totalTareas = _userData!.tareasAsignadas.length +
                        _userData!.tareasHechas.length +
                        _userData!.tareasPorHacer.length;
    final wellbeing = totalTareas == 0 ? 0.0 : _userData!.tareasHechas.length / totalTareas;

    // Obtener mensaje personalizado
    String mensaje = 'Comienza a completar tareas para ver tu progreso.';
    if (wellbeing >= 0.8) {
      mensaje = '¡Excelente! Estás completando tus tareas de manera efectiva. Mantén el ritmo.';
    } else if (wellbeing >= 0.5) {
      mensaje = 'Buen progreso. Continúa enfocándote en tus prioridades para mejorar tu productividad.';
    } else if (wellbeing > 0) {
      mensaje = 'Tienes varias tareas pendientes. Prioriza las más importantes para avanzar.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF133E87), Color(0xFF0B192F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildDonutIndicator(theme, wellbeing),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progreso de Productividad',
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  mensaje,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '✔ ${_userData!.tareasHechas.length} tareas completadas | ${_userData!.puntosTotales} puntos',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutIndicator(ThemeData theme, double wellbeing) {
    return SizedBox(
      height: 170,
      width: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 170,
            width: 170,
            child: Transform.rotate(
              angle: -3.14 / 2,
              child: CustomPaint(
                painter: _DonutPainter(progress: wellbeing, color: const Color(0xFF5BE4A8)),
              ),
            ),
          ),
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1730),
              borderRadius: BorderRadius.circular(120),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(wellbeing * 100).round()}%',
                  style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Tareas completadas', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_loadingUser || _userData == null) {
      return const SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final items = [
      _QuickStat(
        icon: Icons.assignment_outlined,
        label: 'Asignadas',
        value: '${_userData!.tareasAsignadas.length}',
        description: 'Tareas pendientes',
      ),
      _QuickStat(
        icon: Icons.check_circle_outline,
        label: 'Completadas',
        value: '${_userData!.tareasHechas.length}',
        description: 'Entregas validadas',
      ),
      _QuickStat(
        icon: Icons.star_rate_rounded,
        label: 'Puntos',
        value: '${_userData!.puntosTotales}',
        description: 'Nivel de progreso',
      ),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final item = items[index];
          return Container(
            width: 170,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1B2D),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(item.icon, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(item.label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(item.description, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskProgress() {
    final activeDays = _taskCompletions.map((e) => e.day).toSet().length;
    final totalWeek = _taskCompletions.length;
    final lateCount = _taskCompletions.where((e) => e.late).length;
    final bestHour = _bestHourLabel();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1B2D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24.withOpacity(0.12)),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _taskStatChip('Dias activos', '$activeDays/7', Icons.today, Colors.cyanAccent),
              _taskStatChip('Cerradas semana', '$totalWeek', Icons.check_circle, Colors.greenAccent),
              _taskStatChip('Hora pico', bestHour, Icons.access_time, Colors.amberAccent),
              _taskStatChip('Marcadas tarde', '$lateCount', Icons.flag, Colors.pinkAccent),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _aiReadyCard(),
      ],
    );
  }

  Widget _aiReadyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.cyanAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Listo para analisis IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Historial de cierre con hora y dia para detectar patrones y sugerir bloques de enfoque.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTimeline() {
    if (_loadingTasks) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_taskCompletions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1B2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Icon(Icons.timeline_outlined, color: Colors.white.withOpacity(0.3), size: 48),
            const SizedBox(height: 12),
            const Text(
              'No hay tareas completadas aún.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Completa tareas para ver tu historial aquí',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Las tareas ya están ordenadas por timestamp (más recientes primero)
    final sortedTasks = _taskCompletions;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1B2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con contador de tareas
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 4),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.white.withOpacity(0.7), size: 18),
                const SizedBox(width: 8),
                Text(
                  '${sortedTasks.length} tarea${sortedTasks.length != 1 ? 's' : ''} completada${sortedTasks.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Timeline items
          for (int i = 0; i < sortedTasks.length; i++)
            _timelineItem(sortedTasks[i], isLast: i == sortedTasks.length - 1),
        ],
      ),
    );
  }

  Widget _timelineItem(_TaskCompletion item, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna de la línea de tiempo (izquierda)
          Column(
            children: [
              // Punto del timeline
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item.late ? Colors.orangeAccent : Colors.greenAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (item.late ? Colors.orangeAccent : Colors.greenAccent).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Línea vertical (solo si no es el último)
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Contenido de la tarea (derecha)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: item.late
                    ? Colors.orangeAccent.withOpacity(0.2)
                    : Colors.greenAccent.withOpacity(0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con hora y día
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.time} • ${item.day}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      // Badge de estado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.late
                            ? Colors.orangeAccent.withOpacity(0.15)
                            : Colors.greenAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.late ? Icons.access_time : Icons.check_circle,
                              size: 12,
                              color: item.late ? Colors.orangeAccent : Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.late ? 'Tarde' : 'A tiempo',
                              style: TextStyle(
                                color: item.late ? Colors.orangeAccent : Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Título de la tarea
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Nombre del proyecto
                  Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.project,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskStatChip(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  String _bestHourLabel() {
    final hourCounts = <int, int>{};
    for (final item in _taskCompletions) {
      final hour = int.tryParse(item.time.split(':').first) ?? 0;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    if (hourCounts.isEmpty) return '--';
    final best = hourCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final label = best.toString().padLeft(2, '0');
    return '$label:00';
  }

  Future<void> _loadCompletedTasks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _taskCompletions = [];
        _loadingTasks = false;
      });
      return;
    }

    try {
      final query = await FirebaseFirestore.instance.collection('proyectos').get();
      final List<_TaskCompletion> collected = [];

      for (final doc in query.docs) {
        final data = doc.data();
        final projectName = (data['nombre'] ?? data['titulo'] ?? 'Proyecto').toString();

        final tareasSnapshot = await FirebaseFirestore.instance.collection('proyectos').doc(doc.id).collection('tareas').get();
        for (final tareaDoc in tareasSnapshot.docs) {
          final tareaJson = tareaDoc.data();
          final responsables = List<String>.from(tareaJson['responsables'] ?? []);
          final completado = tareaJson['completado'] == true;
          if (!completado || !responsables.contains(uid)) continue;

          final titulo = (tareaJson['titulo'] ?? 'Sin titulo').toString();

          // Leer la fecha de completado (no la fecha límite)
          final fechaCompletadaRaw = tareaJson['fechaCompletada'];
          DateTime? fechaCompletada;
          if (fechaCompletadaRaw is Timestamp) {
            fechaCompletada = fechaCompletadaRaw.toDate();
          } else if (fechaCompletadaRaw is String) {
            fechaCompletada = DateTime.tryParse(fechaCompletadaRaw);
          }

          // Si no hay fechaCompletada, usar la fecha límite como fallback (para tareas antiguas)
          if (fechaCompletada == null) {
            final fechaRaw = tareaJson['fecha'];
            if (fechaRaw is Timestamp) {
              fechaCompletada = fechaRaw.toDate();
            } else if (fechaRaw is String) {
              fechaCompletada = DateTime.tryParse(fechaRaw);
            }
          }

          final day = fechaCompletada != null ? _formatDay(fechaCompletada) : '--';
          final time = fechaCompletada != null ? _formatHour(fechaCompletada) : '--';

          // Verificar si se completó tarde comparando con la fecha límite
          final fechaLimiteRaw = tareaJson['fecha'];
          DateTime? fechaLimite;
          if (fechaLimiteRaw is Timestamp) {
            fechaLimite = fechaLimiteRaw.toDate();
          } else if (fechaLimiteRaw is String) {
            fechaLimite = DateTime.tryParse(fechaLimiteRaw);
          }
          final late = (fechaCompletada != null && fechaLimite != null)
              ? fechaCompletada.isAfter(fechaLimite)
              : false;

          collected.add(_TaskCompletion(
            day: day,
            time: time,
            title: titulo,
            project: projectName,
            late: late,
            timestamp: fechaCompletada,
          ));
        }
      }

      // Ordenar por timestamp (más recientes primero)
      collected.sort((a, b) {
        if (a.timestamp == null && b.timestamp == null) return 0;
        if (a.timestamp == null) return 1;
        if (b.timestamp == null) return -1;
        return b.timestamp!.compareTo(a.timestamp!); // Descendente (más recientes primero)
      });

      setState(() {
        _taskCompletions = collected;
        _loadingTasks = false;
      });
    } catch (e) {
      setState(() {
        _taskCompletions = [];
        _loadingTasks = false;
      });
    }
  }

  String _formatDay(DateTime date) {
    const days = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    return days[date.weekday % 7];
  }

  String _formatHour(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }

  Widget _buildProductivityAnalysis() {
    if (_loadingTasks || _taskCompletions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1B2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Center(
          child: Text(
            'Completa tareas para ver tu análisis de productividad',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Análisis por día de la semana
    final Map<String, int> tareasPorDia = {};
    final List<String> diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

    for (var dia in diasSemana) {
      tareasPorDia[dia] = 0;
    }

    for (var tarea in _taskCompletions) {
      tareasPorDia[tarea.day] = (tareasPorDia[tarea.day] ?? 0) + 1;
    }

    // Encontrar el mejor día
    String mejorDia = diasSemana[0];
    int maxTareas = 0;
    tareasPorDia.forEach((dia, cantidad) {
      if (cantidad > maxTareas) {
        maxTareas = cantidad;
        mejorDia = dia;
      }
    });

    // Análisis por hora
    final Map<int, int> tareasPorHora = {};
    for (var tarea in _taskCompletions) {
      final hora = int.tryParse(tarea.time.split(':').first) ?? 0;
      tareasPorHora[hora] = (tareasPorHora[hora] ?? 0) + 1;
    }

    int mejorHora = 0;
    int maxTareasHora = 0;
    tareasPorHora.forEach((hora, cantidad) {
      if (cantidad > maxTareasHora) {
        maxTareasHora = cantidad;
        mejorHora = hora;
      }
    });

    return Column(
      children: [
        // Mejores días
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1B2D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.cyan.shade400, size: 22),
                  const SizedBox(width: 12),
                  const Text(
                    'Mejores Días de la Semana',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...diasSemana.map((dia) {
                final cantidad = tareasPorDia[dia] ?? 0;
                final porcentaje = maxTareas == 0 ? 0.0 : cantidad / maxTareas;
                final esMejor = dia == mejorDia && cantidad > 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                dia,
                                style: TextStyle(
                                  color: esMejor ? Colors.cyan.shade400 : Colors.white,
                                  fontWeight: esMejor ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                              if (esMejor) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.star, color: Colors.amber.shade400, size: 16),
                              ],
                            ],
                          ),
                          Text(
                            '$cantidad tareas',
                            style: TextStyle(
                              color: esMejor ? Colors.cyan.shade400 : Colors.white70,
                              fontWeight: esMejor ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: porcentaje,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation(
                            esMejor ? Colors.cyan.shade400 : Colors.blue.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Mejores horas
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1B2D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange.shade400, size: 22),
                  const SizedBox(width: 12),
                  const Text(
                    'Horarios Más Productivos',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHourStat('Mañana\n(6-12)', _countTasksInRange(6, 12), Icons.wb_sunny, Colors.orange.shade400),
                  _buildHourStat('Tarde\n(12-18)', _countTasksInRange(12, 18), Icons.wb_twilight, Colors.amber.shade400),
                  _buildHourStat('Noche\n(18-24)', _countTasksInRange(18, 24), Icons.nights_stay, Colors.indigo.shade400),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade400.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade400.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange.shade400),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tu hora pico: ${mejorHora.toString().padLeft(2, '0')}:00 con $maxTareasHora tareas',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _countTasksInRange(int start, int end) {
    return _taskCompletions.where((tarea) {
      final hora = int.tryParse(tarea.time.split(':').first) ?? 0;
      return hora >= start && hora < end;
    }).length;
  }

  Widget _buildHourStat(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TaskCompletion {
  final String day;
  final String time;
  final String title;
  final String project;
  final bool late;
  final DateTime? timestamp; // Para ordenar por fecha de completado

  const _TaskCompletion({
    required this.day,
    required this.time,
    required this.title,
    required this.project,
    required this.late,
    this.timestamp,
  });
}

class _QuickStat {
  final IconData icon;
  final String label;
  final String value;
  final String description;

  const _QuickStat({required this.icon, required this.label, required this.value, required this.description});
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final Color color;

  _DonutPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 16.0;
    final rect = Offset.zero & size;

    final backgroundPaint = Paint()
      ..color = const Color(0xFF1F2741)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final foregroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);
    final sweepAngle = 2 * 3.14159265359 * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0, sweepAngle, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

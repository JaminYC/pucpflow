import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'briefing_models.dart';
import 'briefing_service.dart';
import '../calendar_events_page.dart';

class BriefingDiarioPage extends StatefulWidget {
  const BriefingDiarioPage({super.key});

  @override
  State<BriefingDiarioPage> createState() => _BriefingDiarioPageState();
}

class _BriefingDiarioPageState extends State<BriefingDiarioPage> {
  final BriefingService _briefingService = BriefingService();
  bool _isLoading = true;
  BriefingDiario? _briefing;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarBriefing();
  }

  Future<void> _cargarBriefing() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'No hay usuario autenticado';
          _isLoading = false;
        });
        return;
      }

      final briefing = await _briefingService.generarBriefing(
        userId: user.uid,
        incluirEventosGoogle: true,
      );

      setState(() {
        _briefing = briefing;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el briefing: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050915),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildBriefingContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BE4A8)),
          ),
          SizedBox(height: 20),
          Text(
            'Preparando tu briefing del día...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              _error ?? 'Error desconocido',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _cargarBriefing,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BE4A8),
                foregroundColor: const Color(0xFF050915),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBriefingContent() {
    if (_briefing == null) return const SizedBox();

    return CustomScrollView(
      slivers: [
        // AppBar con gradiente
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: const Color(0xFF050915),
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              'Briefing del Día',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF5BE4A8).withOpacity(0.1),
                    const Color(0xFF050915),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _cargarBriefing,
            ),
          ],
        ),

        // Contenido
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card con saludo y métricas
                _buildHeaderCard(),
                const SizedBox(height: 24),

                // Insights (si existen)
                if (_briefing!.insights.isNotEmpty) ...[
                  _buildInsightsSection(),
                  const SizedBox(height: 24),
                ],

                // Conflictos (si existen)
                if (_briefing!.conflictos.isNotEmpty) ...[
                  _buildConflictosSection(),
                  const SizedBox(height: 24),
                ],

                // Tarea más crítica (destacada)
                if (_briefing!.tareaMasCritica != null) ...[
                  _buildTareaCriticaCard(),
                  const SizedBox(height: 24),
                ],

                // Tareas prioritarias
                if (_briefing!.tareasPrioritarias.isNotEmpty) ...[
                  _buildSectionHeader('⚡ Tareas Prioritarias', ''),
                  const SizedBox(height: 12),
                  ..._briefing!.tareasPrioritarias.map(_buildTareaCard),
                  const SizedBox(height: 24),
                ],

                // Otras tareas
                if (_briefing!.tareasNormales.isNotEmpty) ...[
                  _buildSectionHeader('📝 Otras Tareas del Día', ''),
                  const SizedBox(height: 12),
                  ..._briefing!.tareasNormales.map(_buildTareaCard),
                  const SizedBox(height: 24),
                ],

                // Eventos de Google Calendar
                if (_briefing!.eventos.isNotEmpty) ...[
                  _buildSectionHeader('📅 Eventos del Calendario', ''),
                  const SizedBox(height: 12),
                  ..._briefing!.eventos.map(_buildEventoCard),
                  const SizedBox(height: 24),
                ],

                // Estado vacío
                if (_briefing!.tareasPrioritarias.isEmpty &&
                    _briefing!.tareasNormales.isEmpty &&
                    _briefing!.eventos.isEmpty)
                  _buildEmptyState(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    final metrics = _briefing!.metrics;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E2A3A),
            const Color(0xFF0F1923),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5BE4A8).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saludo
          Text(
            _briefing!.saludo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Fecha
          Text(
            _formatearFecha(_briefing!.fecha),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          // Métricas en grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.assignment,
                  value: '${metrics.totalTareas}',
                  label: 'tareas',
                  color: const Color(0xFF5BE4A8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.priority_high,
                  value: '${metrics.tareasPrioritarias}',
                  label: 'altas',
                  color: const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.access_time,
                  value: metrics.tiempoFormateado,
                  label: 'estimado',
                  color: const Color(0xFF5CC4FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.local_fire_department,
                  value: '${(metrics.cargaDelDia * 100).round()}%',
                  label: 'carga',
                  color: metrics.colorCarga,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF9B6BFF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9B6BFF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B6BFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Color(0xFF9B6BFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Insights y Recomendaciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._briefing!.insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        color: Color(0xFF9B6BFF),
                        fontSize: 16,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildConflictosSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Conflictos de Horario',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._briefing!.conflictos.map((conflicto) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '⚠️ ${conflicto.descripcion}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTareaCriticaCard() {
    final tarea = _briefing!.tareaMasCritica!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B6B).withOpacity(0.2),
            const Color(0xFFFF6B6B).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '🎯 Tarea Más Crítica del Día',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTareaContent(tarea, esDestacada: true),
        ],
      ),
    );
  }

  Widget _buildTareaCard(TareaBriefing tarea) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tarea.colorPrioridad.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: _buildTareaContent(tarea),
    );
  }

  Widget _buildTareaContent(TareaBriefing tarea, {bool esDestacada = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hora y título
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tarea.horaFormateada != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: tarea.colorPrioridad.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tarea.horaFormateada!,
                  style: TextStyle(
                    color: tarea.colorPrioridad,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                tarea.titulo,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: esDestacada ? 18 : 16,
                  fontWeight: esDestacada ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tarea.colorPrioridad.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tarea.textoPrioridad,
                style: TextStyle(
                  color: tarea.colorPrioridad,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Proyecto y detalles
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildChip(
              icon: Icons.folder,
              label: tarea.proyectoNombre,
              color: const Color(0xFF5CC4FF),
            ),
            _buildChip(
              icon: Icons.access_time,
              label: tarea.duracionFormateada,
              color: const Color(0xFFFFA851),
            ),
            if (tarea.fasePMI != null)
              _buildChip(
                icon: Icons.analytics,
                label: tarea.fasePMI!,
                color: const Color(0xFF9B6BFF),
              ),
            if (tarea.responsables.isNotEmpty)
              _buildChip(
                icon: Icons.people,
                label: tarea.responsables.length == 1
                    ? tarea.responsables.first
                    : '${tarea.responsables.length} personas',
                color: const Color(0xFF5BE4A8),
              ),
          ],
        ),

        // Motivo de prioridad
        if (tarea.motivoPrioridad.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA851).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFFFFA851),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tarea.motivoPrioridad,
                    style: const TextStyle(
                      color: Color(0xFFFFA851),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Dependencias bloqueadas
        if (tarea.tieneDependenciasPendientes) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lock,
                  color: Color(0xFFFF6B6B),
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bloqueada por dependencias pendientes',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventoCard(CalendarEvent evento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5CC4FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5CC4FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.event,
              color: Color(0xFF5CC4FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (evento.fecha != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatearHoraEvento(evento.fecha!),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
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

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(
              Icons.celebration,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              '¡Sin tareas pendientes!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Disfruta tu día libre o planifica nuevas tareas',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];

    final diaSemana = dias[fecha.weekday - 1];
    final dia = fecha.day;
    final mes = meses[fecha.month - 1];
    final anio = fecha.year;

    return '$diaSemana, $dia de $mes $anio';
  }

  String _formatearHoraEvento(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }
}

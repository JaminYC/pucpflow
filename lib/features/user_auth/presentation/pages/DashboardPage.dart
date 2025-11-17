
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedView = 'stats';

  final List<_WellnessMetric> _metrics = const [
    _WellnessMetric(
      title: 'Energía diaria',
      icon: Icons.flash_on,
      value: 0.78,
      description: 'Horas de sueño reparador',
      color: Color(0xFF5BE4A8),
    ),
    _WellnessMetric(
      title: 'Mindfulness',
      icon: Icons.self_improvement,
      value: 0.62,
      description: 'Sesiones de respiración y foco',
      color: Color(0xFF9B6BFF),
    ),
    _WellnessMetric(
      title: 'Social',
      icon: Icons.people_alt_outlined,
      value: 0.55,
      description: 'Interacciones significativas',
      color: Color(0xFFFFA851),
    ),
    _WellnessMetric(
      title: 'Movimiento',
      icon: Icons.directions_run,
      value: 0.82,
      description: 'Actividad física semanal',
      color: Color(0xFF5CC4FF),
    ),
  ];

  final List<_WellnessEvent> _history = const [
    _WellnessEvent(day: 'Lunes', highlights: ['Yoga mañanero', 'Reunión con mentor', 'Diario de gratitud']),
    _WellnessEvent(day: 'Martes', highlights: ['Meditación', '15 min de journaling']),
    _WellnessEvent(day: 'Miércoles', highlights: ['Entrenamiento funcional', 'Café con equipo de innovación']),
    _WellnessEvent(day: 'Jueves', highlights: ['Revisión de metas', 'Sesión de respiración guiada']),
    _WellnessEvent(day: 'Viernes', highlights: ['Running 5K', 'Retro con squad', 'Cena larga con amigos']),
  ];

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
              const SizedBox(height: 32),
              _buildSectionHeader('Panel de bienestar', 'Visualiza la tendencia de tus hábitos'),
              const SizedBox(height: 12),
              _buildSegmentedControl(),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedView == 'stats' ? _buildMetricsGrid() : _buildHistoryTimeline(),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Sugerencias rápidas', 'Acciones cortas para continuar con buena racha'),
              const SizedBox(height: 12),
              _buildTips(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    const wellbeing = 0.76;

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
                Text('Balance saludable', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  'Tu energía semanal está por encima del promedio. Mantén la constancia en descanso y socialización para sostener la curva.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('✔ 4 hábitos completados hoy', style: TextStyle(color: Colors.white)),
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
                Text('Equilibrio general', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final items = [
      _QuickStat(icon: Icons.bedtime, label: 'Sueño', value: '7h 15m', description: 'Ritmo estable'),
      _QuickStat(icon: Icons.monitor_heart, label: 'Frecuencia', value: '68 bpm', description: 'Reposo promedio'),
      _QuickStat(icon: Icons.water_drop, label: 'Hidratación', value: '6 vasos', description: 'Meta del día 80%'),
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

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1B2D),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildSegmentButton('stats', 'Indicadores'),
          _buildSegmentButton('history', 'Rutina semanal'),
        ],
      ),
    );
  }

  Expanded _buildSegmentButton(String value, String label) {
    final isSelected = _selectedView == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF133E87) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.builder(
      key: const ValueKey('stats'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _metrics.length,
      itemBuilder: (_, index) {
        final metric = _metrics[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1B2D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: metric.color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: Icon(metric.icon, color: metric.color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(metric.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(metric.description, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: metric.value,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(metric.color),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text('${(metric.value * 100).round()}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTimeline() {
    return Column(
      key: const ValueKey('history'),
      children: _history
          .map(
            (event) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1B2D),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(color: Color(0xFF5BE4A8), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.day, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ...event.highlights.map(
                          (highlight) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text('• $highlight', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTips() {
    final tips = [
      {'icon': Icons.alarm_add, 'text': 'Agenda recordatorios de micro descansos cada 90 minutos.'},
      {'icon': Icons.waves, 'text': 'Prueba una serie de respiraciones cuadradas antes de dormir.'},
      {'icon': Icons.public, 'text': 'Sal 10 minutos a tomar sol, ayuda a regular tu energía.'},
    ];

    return Column(
      children: tips
          .map(
            (tip) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1B2D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Row(
                children: [
                  Icon(tip['icon'] as IconData, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tip['text'] as String, style: const TextStyle(color: Colors.white70))),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _WellnessMetric {
  final String title;
  final IconData icon;
  final double value;
  final String description;
  final Color color;

  const _WellnessMetric({required this.title, required this.icon, required this.value, required this.description, required this.color});
}

class _WellnessEvent {
  final String day;
  final List<String> highlights;

  const _WellnessEvent({required this.day, required this.highlights});
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

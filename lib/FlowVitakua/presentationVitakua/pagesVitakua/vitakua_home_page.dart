import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class VitakuaHomePage extends StatefulWidget {
  const VitakuaHomePage({Key? key}) : super(key: key);

  @override
  State<VitakuaHomePage> createState() => _VitakuaHomePageState();
}

class _VitakuaHomePageState extends State<VitakuaHomePage>
    with TickerProviderStateMixin {
  // Estados simulados
  double waterLevel = 67.0;
  double dailyConsumption = 240.0;
  bool isValveOpen = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Datos simulados para el gráfico semanal
  List<FlSpot> weeklyConsumption = [
    FlSpot(0, 180),
    FlSpot(1, 220),
    FlSpot(2, 190),
    FlSpot(3, 240),
    FlSpot(4, 210),
    FlSpot(5, 185),
    FlSpot(6, 240),
  ];

  List<String> weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset(
              'assets/logovastoria.png',
              height: 32,
              width: 32,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3D7C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'FlowVitakua',
              style: TextStyle(
                color: Color(0xFF1A3D7C),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1A3D7C)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF1A3D7C)),
            onPressed: () {},
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _animation.value)),
            child: Opacity(
              opacity: _animation.value,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado con estado general
                    _buildHeaderSection(),
                    const SizedBox(height: 20),
                    
                    // Métricas principales
                    _buildMetricsSection(),
                    const SizedBox(height: 20),
                    
                    // Gráfico de consumo semanal
                    _buildWeeklyChart(),
                    const SizedBox(height: 20),
                    
                    // Dashboard visual de la red
                    _buildNetworkDashboard(),
                    const SizedBox(height: 20),
                    
                    // Control de válvula
                    _buildValveControl(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3D7C), Color(0xFF2E5A94)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sistema de Gestión Inteligente',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Monitoreo en tiempo real',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 8),
                    SizedBox(width: 6),
                    Text(
                      'Sistema Activo',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Nivel de Agua',
            value: '${waterLevel.toInt()}%',
            icon: Icons.water,
            color: Colors.blue,
            subtitle: 'Reservorio Principal',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Consumo Diario',
            value: '${dailyConsumption.toInt()} L',
            icon: Icons.home,
            color: Colors.teal,
            subtitle: 'Vivienda Actual',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                if (title == 'Nivel de Agua')
                  Icon(
                    waterLevel > 50 ? Icons.trending_up : Icons.trending_down,
                    color: waterLevel > 50 ? Colors.green : Colors.orange,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3D7C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consumo Semanal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A3D7C),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < weekDays.length) {
                            return Text(
                              weekDays[value.toInt()],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}L',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 150,
                  maxY: 280,
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklyConsumption,
                      isCurved: true,
                      color: const Color(0xFF1A3D7C),
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFF1A3D7C),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF1A3D7C).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkDashboard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Red FlowVitakua',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A3D7C),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: CustomPaint(
                painter: NetworkDashboardPainter(isValveOpen: isValveOpen),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValveControl() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Control de Válvula',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A3D7C),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isValveOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isValveOpen ? Colors.green : Colors.red,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isValveOpen ? Icons.water : Icons.block,
                          size: 48,
                          color: isValveOpen ? Colors.green : Colors.red,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isValveOpen ? 'ABIERTA' : 'CERRADA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isValveOpen ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isValveOpen ? 'Flujo activo' : 'Flujo detenido',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isValveOpen = !isValveOpen;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3D7C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isValveOpen ? 'CERRAR' : 'ABRIR',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NetworkDashboardPainter extends CustomPainter {
  final bool isValveOpen;

  NetworkDashboardPainter({required this.isValveOpen});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    // Reservorio (tanque de agua)
    final reservoirRect = Rect.fromLTWH(size.width * 0.1, size.height * 0.2, 80, 60);
    paint.color = const Color(0xFF1A3D7C);
    fillPaint.color = Colors.blue.withOpacity(0.3);
    canvas.drawRRect(RRect.fromRectAndRadius(reservoirRect, const Radius.circular(8)), fillPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(reservoirRect, const Radius.circular(8)), paint);

    // Texto reservorio
    final reservoirText = TextPainter(
      text: const TextSpan(
        text: 'Reservorio\n67%',
        style: TextStyle(color: Color(0xFF1A3D7C), fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    reservoirText.layout();
    reservoirText.paint(canvas, Offset(reservoirRect.center.dx - reservoirText.width / 2, reservoirRect.center.dy - reservoirText.height / 2));

    // Sensor
    final sensorCenter = Offset(size.width * 0.5, size.height * 0.3);
    paint.color = Colors.orange;
    fillPaint.color = Colors.orange.withOpacity(0.3);
    canvas.drawCircle(sensorCenter, 20, fillPaint);
    canvas.drawCircle(sensorCenter, 20, paint);

    // Texto sensor
    final sensorText = TextPainter(
      text: const TextSpan(
        text: 'Sensor',
        style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    sensorText.layout();
    sensorText.paint(canvas, Offset(sensorCenter.dx - sensorText.width / 2, sensorCenter.dy - sensorText.height / 2));

    // Casas
    final house1 = Offset(size.width * 0.7, size.height * 0.15);
    final house2 = Offset(size.width * 0.8, size.height * 0.45);
    final house3 = Offset(size.width * 0.6, size.height * 0.7);

    for (final house in [house1, house2, house3]) {
      paint.color = const Color(0xFF1A3D7C);
      fillPaint.color = Colors.teal.withOpacity(0.3);
      final houseRect = Rect.fromCenter(center: house, width: 40, height: 30);
      canvas.drawRRect(RRect.fromRectAndRadius(houseRect, const Radius.circular(4)), fillPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(houseRect, const Radius.circular(4)), paint);
    }

    // Líneas de conexión (tuberías)
    paint.color = isValveOpen ? Colors.blue : Colors.grey;
    paint.strokeWidth = 4;

    // Reservorio a sensor
    canvas.drawLine(
      Offset(reservoirRect.right, reservoirRect.center.dy),
      Offset(sensorCenter.dx - 20, sensorCenter.dy),
      paint,
    );

    // Sensor a casas
    canvas.drawLine(sensorCenter, house1, paint);
    canvas.drawLine(sensorCenter, house2, paint);
    canvas.drawLine(sensorCenter, house3, paint);

    // Válvula
    final valveCenter = Offset((reservoirRect.right + sensorCenter.dx - 20) / 2, reservoirRect.center.dy);
    paint.color = isValveOpen ? Colors.green : Colors.red;
    fillPaint.color = isValveOpen ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3);
    canvas.drawCircle(valveCenter, 12, fillPaint);
    canvas.drawCircle(valveCenter, 12, paint);

    // Icono de válvula
    final valveText = TextPainter(
      text: TextSpan(
        text: isValveOpen ? '🔓' : '🔒',
        style: const TextStyle(fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    valveText.layout();
    valveText.paint(canvas, Offset(valveCenter.dx - valveText.width / 2, valveCenter.dy - valveText.height / 2));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:pucpflow/Cafillari/core/theme.dart';

/// Dashboard Principal del Sistema Ciber-Físico de Secado de Café
/// Integra monitoreo en tiempo real, control de actuadores y trazabilidad
class CafillariHomePage extends StatefulWidget {
  const CafillariHomePage({Key? key}) : super(key: key);

  @override
  State<CafillariHomePage> createState() => _CafillariHomePageState();
}

class _CafillariHomePageState extends State<CafillariHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _dataTimer;

  // Variables de sensores (simuladas - conectar a Firebase/MQTT)
  double _tempAmbiente = 28.5;
  double _humedadAmbiente = 65.0;
  double _tempLechoSuperior = 32.1;
  double _tempLechoMedio = 30.8;
  double _flujoAire = 1.2;

  // Estados de actuadores
  bool _ventilador1 = true;
  bool _ventilador2 = false;
  bool _resistencia1 = true;
  bool _resistencia2 = false;
  bool _motorRastrillo = true;

  // Modo de control
  bool _modoAutomatico = true;

  // Datos históricos para gráficos
  List<FlSpot> _tempHistory = [];
  List<FlSpot> _humHistory = [];

  // Alertas activas
  List<Map<String, dynamic>> _alertas = [];

  // Lote actual
  String _loteActual = 'LOTE-2024-001';
  DateTime _inicioSecado = DateTime.now().subtract(const Duration(hours: 8));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeData();
    _startDataSimulation();
  }

  void _initializeData() {
    // Inicializar datos históricos
    final random = Random();
    for (int i = 0; i < 20; i++) {
      _tempHistory.add(FlSpot(i.toDouble(), 28 + random.nextDouble() * 8));
      _humHistory.add(FlSpot(i.toDouble(), 60 + random.nextDouble() * 20));
    }

    // Alertas de ejemplo
    _alertas = [
      {
        'tipo': 'warning',
        'mensaje': 'Humedad alta detectada',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
        'valor': '78%',
      },
      {
        'tipo': 'info',
        'mensaje': 'Ventilador 2 activado automáticamente',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 45)),
        'valor': '-',
      },
    ];
  }

  void _startDataSimulation() {
    _dataTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          final random = Random();
          // Simular variaciones en sensores
          _tempAmbiente += (random.nextDouble() - 0.5) * 0.5;
          _humedadAmbiente += (random.nextDouble() - 0.5) * 2;
          _tempLechoSuperior += (random.nextDouble() - 0.5) * 0.3;
          _tempLechoMedio += (random.nextDouble() - 0.5) * 0.3;

          // Mantener en rangos realistas
          _tempAmbiente = _tempAmbiente.clamp(20.0, 45.0);
          _humedadAmbiente = _humedadAmbiente.clamp(40.0, 95.0);
          _tempLechoSuperior = _tempLechoSuperior.clamp(25.0, 50.0);
          _tempLechoMedio = _tempLechoMedio.clamp(25.0, 50.0);

          // Actualizar histórico
          if (_tempHistory.length > 30) {
            _tempHistory.removeAt(0);
            _humHistory.removeAt(0);
          }
          _tempHistory.add(FlSpot(_tempHistory.length.toDouble(), _tempAmbiente));
          _humHistory.add(FlSpot(_humHistory.length.toDouble(), _humedadAmbiente));

          // Control automático
          if (_modoAutomatico) {
            _controlAutomatico();
          }
        });
      }
    });
  }

  void _controlAutomatico() {
    // Lógica de control automático basada en umbrales
    if (_humedadAmbiente > 75) {
      _ventilador2 = true;
    } else if (_humedadAmbiente < 60) {
      _ventilador2 = false;
    }

    if (_tempAmbiente < 30) {
      _resistencia2 = true;
    } else if (_tempAmbiente > 38) {
      _resistencia2 = false;
    }
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CafillariTheme.backgroundDark,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMonitoreoTab(),
                _buildControlTab(),
                _buildTrazabilidadTab(),
                _buildAlertasTab(),
                _buildConfiguracionTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CafillariTheme.primaryBrown,
            CafillariTheme.darkBrown,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.coffee,
                  color: CafillariTheme.coffeeGold,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Título
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CAFILLARI',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Sistema Ciber-Físico de Secado de Café',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Estado del sistema
              _buildStatusIndicator(),
              const SizedBox(width: 16),
              // Botón volver
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Info del lote actual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderInfo('Lote Activo', _loteActual),
                _buildHeaderDivider(),
                _buildHeaderInfo('Tiempo Secado', _formatDuration(DateTime.now().difference(_inicioSecado))),
                _buildHeaderDivider(),
                _buildHeaderInfo('Modo', _modoAutomatico ? 'AUTOMÁTICO' : 'MANUAL'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final isOnline = true; // Conectar a estado real
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline ? CafillariTheme.success.withOpacity(0.2) : CafillariTheme.danger.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? CafillariTheme.success : CafillariTheme.danger,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? CafillariTheme.success : CafillariTheme.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'EN LÍNEA' : 'DESCONECTADO',
            style: TextStyle(
              color: isOnline ? CafillariTheme.success : CafillariTheme.danger,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: CafillariTheme.coffeeGold,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: CafillariTheme.backgroundCard,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: CafillariTheme.coffeeGold,
        indicatorWeight: 3,
        labelColor: CafillariTheme.coffeeGold,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.monitor_heart), text: 'Monitoreo'),
          Tab(icon: Icon(Icons.settings_remote), text: 'Control'),
          Tab(icon: Icon(Icons.history), text: 'Trazabilidad'),
          Tab(icon: Icon(Icons.notifications_active), text: 'Alertas'),
          Tab(icon: Icon(Icons.settings), text: 'Config'),
        ],
      ),
    );
  }

  // ========== TAB 1: MONITOREO EN TIEMPO REAL ==========
  Widget _buildMonitoreoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPIs principales
          _buildSectionTitle('Variables Críticas', Icons.sensors),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSensorCard(
                'Temperatura Ambiente',
                _tempAmbiente,
                '°C',
                CafillariTheme.temperature,
                Icons.thermostat,
                minVal: 20,
                maxVal: 45,
                alertHigh: 40,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildSensorCard(
                'Humedad Relativa',
                _humedadAmbiente,
                '%',
                CafillariTheme.humidity,
                Icons.water_drop,
                minVal: 40,
                maxVal: 95,
                alertHigh: 85,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSensorCard(
                'T° Lecho Superior',
                _tempLechoSuperior,
                '°C',
                const Color(0xFFFF7043),
                Icons.layers,
                minVal: 25,
                maxVal: 50,
                alertHigh: 45,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildSensorCard(
                'T° Lecho Medio',
                _tempLechoMedio,
                '°C',
                const Color(0xFFFFB74D),
                Icons.layers_outlined,
                minVal: 25,
                maxVal: 50,
                alertHigh: 45,
              )),
            ],
          ),
          const SizedBox(height: 12),
          _buildSensorCard(
            'Flujo de Aire',
            _flujoAire,
            'm³/s',
            CafillariTheme.airflow,
            Icons.air,
            minVal: 0,
            maxVal: 3,
            alertLow: 0.5,
          ),

          const SizedBox(height: 24),

          // Gráfico de temperatura
          _buildSectionTitle('Histórico de Temperatura', Icons.show_chart),
          const SizedBox(height: 12),
          _buildTemperatureChart(),

          const SizedBox(height: 24),

          // Gráfico de humedad
          _buildSectionTitle('Histórico de Humedad', Icons.waves),
          const SizedBox(height: 12),
          _buildHumidityChart(),

          const SizedBox(height: 24),

          // KPI del proceso
          _buildSectionTitle('KPIs del Proceso', Icons.analytics),
          const SizedBox(height: 12),
          _buildKPIRow(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: CafillariTheme.coffeeGold, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSensorCard(
    String label,
    double value,
    String unit,
    Color color,
    IconData icon, {
    double minVal = 0,
    double maxVal = 100,
    double? alertHigh,
    double? alertLow,
  }) {
    final isAlert = (alertHigh != null && value > alertHigh) ||
        (alertLow != null && value < alertLow);
    final percentage = ((value - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CafillariTheme.backgroundCard,
            CafillariTheme.backgroundCard.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlert
            ? CafillariTheme.danger.withValues(alpha: 0.5)
            : color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAlert ? CafillariTheme.danger : color).withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.3),
                      color.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (isAlert)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CafillariTheme.danger.withValues(alpha: 0.3),
                        CafillariTheme.danger.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: CafillariTheme.danger.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_rounded, color: CafillariTheme.danger, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'ALERTA',
                        style: TextStyle(
                          color: CafillariTheme.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: isAlert ? CafillariTheme.danger : Colors.white,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de progreso elegante
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAlert
                          ? [
                              CafillariTheme.danger,
                              CafillariTheme.danger.withValues(alpha: 0.7),
                            ]
                          : [
                              color,
                              color.withValues(alpha: 0.7),
                            ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (isAlert ? CafillariTheme.danger : color).withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${minVal.toInt()}$unit',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(percentage * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${maxVal.toInt()}$unit',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart() {
    const double tempOptima = 35.0; // Temperatura óptima de secado
    final double valorActual = _tempHistory.isNotEmpty ? _tempHistory.last.y : 0;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CafillariTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Valor actual prominente
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: CafillariTheme.temperature,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Actual: ${valorActual.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CafillariTheme.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CafillariTheme.success.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Óptimo: ${tempOptima.toStringAsFixed(0)}°C',
                  style: TextStyle(
                    color: CafillariTheme.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Gráfico
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 5,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}°C',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    // Línea de valor óptimo
                    HorizontalLine(
                      y: tempOptima,
                      color: CafillariTheme.success,
                      strokeWidth: 2,
                      dashArray: [8, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: TextStyle(
                          color: CafillariTheme.success,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        labelResolver: (line) => 'ÓPTIMO',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _tempHistory,
                    isCurved: true,
                    color: CafillariTheme.temperature,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        // Solo mostrar punto en el último valor
                        if (index == _tempHistory.length - 1) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: CafillariTheme.temperature,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: CafillariTheme.temperature.withValues(alpha: 0.15),
                    ),
                  ),
                ],
                minY: 20,
                maxY: 50,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityChart() {
    const double humedadOptima = 60.0; // Humedad óptima para secado
    final double valorActual = _humHistory.isNotEmpty ? _humHistory.last.y : 0;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CafillariTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Valor actual prominente
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: CafillariTheme.humidity,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Actual: ${valorActual.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CafillariTheme.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CafillariTheme.success.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Óptimo: ${humedadOptima.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: CafillariTheme.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Gráfico
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 10,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    // Línea de valor óptimo
                    HorizontalLine(
                      y: humedadOptima,
                      color: CafillariTheme.success,
                      strokeWidth: 2,
                      dashArray: [8, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: TextStyle(
                          color: CafillariTheme.success,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        labelResolver: (line) => 'ÓPTIMO',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _humHistory,
                    isCurved: true,
                    color: CafillariTheme.humidity,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        // Solo mostrar punto en el último valor
                        if (index == _humHistory.length - 1) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: CafillariTheme.humidity,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: CafillariTheme.humidity.withValues(alpha: 0.15),
                    ),
                  ),
                ],
                minY: 30,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIRow() {
    final deltaTemp = (_tempLechoSuperior - _tempLechoMedio).abs();
    final isUniform = deltaTemp < 2;

    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'ΔT Lechos',
            '${deltaTemp.toStringAsFixed(1)}°C',
            isUniform ? 'Uniforme' : 'Revisar',
            isUniform ? CafillariTheme.success : CafillariTheme.warning,
            Icons.compare_arrows,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            'Tiempo Operación',
            _formatDuration(DateTime.now().difference(_inicioSecado)),
            'Activo',
            CafillariTheme.info,
            Icons.timer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            'Eficiencia',
            '87%',
            'Óptimo',
            CafillariTheme.success,
            Icons.speed,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, String status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CafillariTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ========== TAB 2: CONTROL DE ACTUADORES ==========
  Widget _buildControlTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de modo
          _buildModeSelector(),
          const SizedBox(height: 24),

          // Ventiladores
          _buildSectionTitle('Ventilación', Icons.air),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActuatorCard(
                'Ventilador 1',
                'Principal',
                _ventilador1,
                Icons.wind_power,
                (val) => setState(() => _ventilador1 = val),
                enabled: !_modoAutomatico,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildActuatorCard(
                'Ventilador 2',
                'Auxiliar',
                _ventilador2,
                Icons.wind_power,
                (val) => setState(() => _ventilador2 = val),
                enabled: !_modoAutomatico,
              )),
            ],
          ),
          const SizedBox(height: 24),

          // Calefacción
          _buildSectionTitle('Calefacción', Icons.whatshot),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActuatorCard(
                'Resistencia 1',
                '500W',
                _resistencia1,
                Icons.electric_bolt,
                (val) => setState(() => _resistencia1 = val),
                enabled: !_modoAutomatico,
                isHeating: true,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildActuatorCard(
                'Resistencia 2',
                '500W',
                _resistencia2,
                Icons.electric_bolt,
                (val) => setState(() => _resistencia2 = val),
                enabled: !_modoAutomatico,
                isHeating: true,
              )),
            ],
          ),
          const SizedBox(height: 24),

          // Motor rastrillo
          _buildSectionTitle('Sistema Mecánico', Icons.settings),
          const SizedBox(height: 12),
          _buildActuatorCard(
            'Motor Rastrillo',
            'Volteo automático',
            _motorRastrillo,
            Icons.rotate_right,
            (val) => setState(() => _motorRastrillo = val),
            enabled: !_modoAutomatico,
            isMotor: true,
          ),

          const SizedBox(height: 24),

          // Estado general de actuadores
          _buildActuatorSummary(),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: CafillariTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _modoAutomatico
              ? CafillariTheme.success.withOpacity(0.5)
              : CafillariTheme.coffeeGold.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _modoAutomatico ? Icons.auto_mode : Icons.touch_app,
            color: _modoAutomatico ? CafillariTheme.success : CafillariTheme.coffeeGold,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _modoAutomatico ? 'MODO AUTOMÁTICO' : 'MODO MANUAL',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _modoAutomatico
                      ? 'El sistema controla los actuadores según umbrales'
                      : 'Control manual de todos los actuadores',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _modoAutomatico,
            onChanged: (val) => setState(() => _modoAutomatico = val),
            activeColor: CafillariTheme.success,
            activeTrackColor: CafillariTheme.success.withOpacity(0.3),
            inactiveThumbColor: CafillariTheme.coffeeGold,
            inactiveTrackColor: CafillariTheme.coffeeGold.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildActuatorCard(
    String name,
    String subtitle,
    bool isOn,
    IconData icon,
    Function(bool) onChanged, {
    bool enabled = true,
    bool isHeating = false,
    bool isMotor = false,
  }) {
    final Color activeColor = isHeating
        ? CafillariTheme.temperature
        : isMotor
            ? CafillariTheme.coffeeGold
            : CafillariTheme.airflow;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CafillariTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOn ? activeColor.withOpacity(0.5) : Colors.white.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: isOn
            ? [
                BoxShadow(
                  color: activeColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOn ? activeColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isOn ? activeColor : Colors.white.withOpacity(0.5),
                  size: 28,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isOn ? 'ON' : 'OFF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOn ? activeColor : Colors.white.withOpacity(0.5),
                    ),
                  ),
                  if (!enabled)
                    Text(
                      'AUTO',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: FittedBox(
              child: Switch(
                value: isOn,
                onChanged: enabled ? onChanged : null,
                activeColor: activeColor,
                activeTrackColor: activeColor.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActuatorSummary() {
    final activeCount = [_ventilador1, _ventilador2, _resistencia1, _resistencia2, _motorRastrillo]
        .where((e) => e)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CafillariTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Activos', '$activeCount/5', CafillariTheme.success),
          _buildSummaryItem('Ventilación', '${(_ventilador1 ? 1 : 0) + (_ventilador2 ? 1 : 0)}/2', CafillariTheme.airflow),
          _buildSummaryItem('Calefacción', '${(_resistencia1 ? 1 : 0) + (_resistencia2 ? 1 : 0)}/2', CafillariTheme.temperature),
          _buildSummaryItem('Mecánico', _motorRastrillo ? '1/1' : '0/1', CafillariTheme.coffeeGold),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // ========== TAB 3: TRAZABILIDAD ==========
  Widget _buildTrazabilidadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Lote Actual', Icons.inventory_2),
          const SizedBox(height: 12),
          _buildLoteCard(),
          const SizedBox(height: 24),

          _buildSectionTitle('Historial de Lotes', Icons.history),
          const SizedBox(height: 12),
          _buildLoteHistoryList(),
        ],
      ),
    );
  }

  Widget _buildLoteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: CafillariTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CafillariTheme.coffeeGold.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.coffee, color: CafillariTheme.coffeeGold, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loteActual,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Café Arábica - Cajamarca',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CafillariTheme.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'EN PROCESO',
                  style: TextStyle(
                    color: CafillariTheme.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLoteInfo('Peso Inicial', '50 kg'),
              _buildLoteInfo('Peso Actual', '35 kg'),
              _buildLoteInfo('Humedad Grano', '28%'),
              _buildLoteInfo('Tiempo', _formatDuration(DateTime.now().difference(_inicioSecado))),
            ],
          ),
          const SizedBox(height: 20),
          // Barra de progreso del secado
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso de Secado',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                  ),
                  const Text(
                    '65%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: CafillariTheme.coffeeGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.65,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(CafillariTheme.coffeeGold),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoteInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6)),
        ),
      ],
    );
  }

  Widget _buildLoteHistoryList() {
    final lotes = [
      {'id': 'LOTE-2024-001', 'fecha': '15 Nov 2024', 'peso': '48 kg', 'estado': 'En Proceso'},
      {'id': 'LOTE-2024-000', 'fecha': '10 Nov 2024', 'peso': '52 kg', 'estado': 'Completado'},
      {'id': 'LOTE-2023-045', 'fecha': '28 Oct 2024', 'peso': '45 kg', 'estado': 'Completado'},
      {'id': 'LOTE-2023-044', 'fecha': '15 Oct 2024', 'peso': '50 kg', 'estado': 'Completado'},
    ];

    return Column(
      children: lotes.map((lote) => _buildLoteHistoryItem(lote)).toList(),
    );
  }

  Widget _buildLoteHistoryItem(Map<String, String> lote) {
    final isActive = lote['estado'] == 'En Proceso';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CafillariTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? CafillariTheme.coffeeGold.withOpacity(0.5) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive
                  ? CafillariTheme.coffeeGold.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.inventory_2,
              color: isActive ? CafillariTheme.coffeeGold : Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lote['id']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${lote['fecha']} • ${lote['peso']}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? CafillariTheme.success.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              lote['estado']!,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? CafillariTheme.success : Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  // ========== TAB 4: ALERTAS ==========
  Widget _buildAlertasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Alertas Activas', Icons.warning_amber),
          const SizedBox(height: 12),
          if (_alertas.isEmpty)
            _buildNoAlerts()
          else
            ..._alertas.map((alerta) => _buildAlertCard(alerta)),
          const SizedBox(height: 24),
          _buildSectionTitle('Umbrales de Alerta', Icons.tune),
          const SizedBox(height: 12),
          _buildThresholdsCard(),
        ],
      ),
    );
  }

  Widget _buildNoAlerts() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: CafillariTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: CafillariTheme.success),
            const SizedBox(height: 16),
            const Text(
              'Sin alertas activas',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              'El sistema opera dentro de parámetros normales',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alerta) {
    final isWarning = alerta['tipo'] == 'warning';
    final color = isWarning ? CafillariTheme.warning : CafillariTheme.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CafillariTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isWarning ? Icons.warning_amber : Icons.info_outline,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerta['mensaje'],
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(alerta['timestamp']),
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          if (alerta['valor'] != '-')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                alerta['valor'],
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThresholdsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CafillariTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildThresholdRow('Temperatura máxima', '40°C', CafillariTheme.temperature),
          const Divider(color: Colors.white12),
          _buildThresholdRow('Humedad máxima', '85%', CafillariTheme.humidity),
          const Divider(color: Colors.white12),
          _buildThresholdRow('ΔT máximo lechos', '2°C', CafillariTheme.warning),
          const Divider(color: Colors.white12),
          _buildThresholdRow('Flujo aire mínimo', '0.5 m³/s', CafillariTheme.airflow),
        ],
      ),
    );
  }

  Widget _buildThresholdRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ========== TAB 5: CONFIGURACIÓN ==========
  Widget _buildConfiguracionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Sistema', Icons.info_outline),
          const SizedBox(height: 12),
          _buildSystemInfoCard(),
          const SizedBox(height: 24),

          _buildSectionTitle('Prototipo', Icons.build),
          const SizedBox(height: 12),
          _buildPrototypeInfoCard(),
          const SizedBox(height: 24),

          _buildSectionTitle('Conexión', Icons.wifi),
          const SizedBox(height: 12),
          _buildConnectionCard(),
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CafillariTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow('Versión del sistema', 'v1.0.0'),
          const Divider(color: Colors.white12),
          _buildInfoRow('ESP32', 'DevKit V1'),
          const Divider(color: Colors.white12),
          _buildInfoRow('Sensores', 'SHT31, DS18B20'),
          const Divider(color: Colors.white12),
          _buildInfoRow('Protocolo', 'MQTT / Firebase'),
          const Divider(color: Colors.white12),
          _buildInfoRow('Intervalo muestreo', '3 segundos'),
        ],
      ),
    );
  }

  Widget _buildPrototypeInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CafillariTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow('Dimensiones', '2.0 × 1.2 × 2.2 m'),
          const Divider(color: Colors.white12),
          _buildInfoRow('Capacidad', '50 kg café pergamino'),
          const Divider(color: Colors.white12),
          _buildInfoRow('Ventiladores', '2 × AC 220V'),
          const Divider(color: Colors.white12),
          _buildInfoRow('Calefacción', '2 × 500W'),
          const Divider(color: Colors.white12),
          _buildInfoRow('Motor rastrillo', 'DC 12V'),
        ],
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CafillariTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estado', style: TextStyle(color: Colors.white70)),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: CafillariTheme.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Conectado',
                    style: TextStyle(color: CafillariTheme.success, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white12),
          _buildInfoRow('WiFi SSID', 'CAFILLARI_IOT'),
          const Divider(color: Colors.white12),
          _buildInfoRow('IP Local', '192.168.1.100'),
          const Divider(color: Colors.white12),
          _buildInfoRow('Última sincronización', 'Hace 3 seg'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7))),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ========== HELPERS ==========
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} horas';
    } else {
      return 'Hace ${diff.inDays} días';
    }
  }
}

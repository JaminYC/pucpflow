import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DataVisualizationScreen extends StatelessWidget {
  const DataVisualizationScreen({Key? key}) : super(key: key);

  List<FlSpot> _generarDatosTemperatura() {
    return const [
      FlSpot(0, 35),
      FlSpot(1, 36),
      FlSpot(2, 37),
      FlSpot(3, 38),
      FlSpot(4, 37),
      FlSpot(5, 36),
    ];
  }

  List<FlSpot> _generarDatosHumedad() {
    return const [
      FlSpot(0, 60),
      FlSpot(1, 58),
      FlSpot(2, 62),
      FlSpot(3, 65),
      FlSpot(4, 63),
      FlSpot(5, 61),
    ];
  }

  List<FlSpot> _generarDatosFlujo() {
    return const [
      FlSpot(0, 1.5),
      FlSpot(1, 1.4),
      FlSpot(2, 1.3),
      FlSpot(3, 1.2),
      FlSpot(4, 1.4),
      FlSpot(5, 1.5),
    ];
  }

  LineChartData _buildLineChartData(List<FlSpot> spots, String title, Color color) {
    return LineChartData(
      backgroundColor: const Color(0xFFFAF9F6),
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 4,
          belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
        ),
      ],
    lineTouchData: LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text('Visualización de Datos'),
        backgroundColor: const Color(0xFF6B4226),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Temperatura (\u00b0C)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 200,
              child: LineChart(_buildLineChartData(_generarDatosTemperatura(), 'Temperatura', const Color(0xFF1976D2))),
            ),
            const SizedBox(height: 30),
            const Text(
              'Humedad Relativa (%)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 200,
              child: LineChart(_buildLineChartData(_generarDatosHumedad(), 'Humedad', Colors.green)),
            ),
            const SizedBox(height: 30),
            const Text(
              'Flujo de Aire (m³/s)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 200,
              child: LineChart(_buildLineChartData(_generarDatosFlujo(), 'Flujo de Aire', Colors.orange)),
            ),
          ],
        ),
      ),
    );
  }
}

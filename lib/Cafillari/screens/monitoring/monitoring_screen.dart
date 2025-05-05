import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MonitoringScreen extends StatelessWidget {
  final double temperatura = 37.5; // Valor simulado
  final double humedad = 58.0; // Valor simulado
  final double flujoAire = 1.2; // Valor simulado

  MonitoringScreen({Key? key}) : super(key: key);

  String evaluarEstado() {
    if (temperatura > 45 || humedad > 70) {
      return "Crítico";
    } else {
      return "Óptimo";
    }
  }

  Color colorEstado() {
    return evaluarEstado() == "Crítico" ? Colors.red : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text('Monitoreo en Tiempo Real'),
        backgroundColor: const Color(0xFF6B4226),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildVariableCard('Temperatura (°C)', temperatura, Icons.thermostat),
            _buildVariableCard('Humedad Relativa (%)', humedad, Icons.water_drop),
            _buildVariableCard('Flujo de Aire (m³/s)', flujoAire, Icons.air),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.warning, color: colorEstado(), size: 36),
                title: Text(
                  'Estado General: ${evaluarEstado()}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorEstado()),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Histórico de Temperatura (simulado)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 200, child: _SimpleLineChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildVariableCard(String nombre, double valor, IconData icono) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icono, color: const Color(0xFF1976D2), size: 36),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          valor.toString(),
          style: const TextStyle(fontSize: 20, color: Colors.black87),
        ),
      ),
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        backgroundColor: const Color(0xFFFAF9F6),
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 36),
              FlSpot(1, 37),
              FlSpot(2, 38),
              FlSpot(3, 39),
              FlSpot(4, 37),
              FlSpot(5, 36),
            ],
            isCurved: true,

            barWidth: 4,
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

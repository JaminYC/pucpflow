import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficoConsumo extends StatelessWidget {
  const GraficoConsumo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                  return Text(
                    dias[value.toInt() % dias.length],
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, interval: 50),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              barWidth: 3,
              color: Colors.blueAccent,
              spots: [
                FlSpot(0, 150),
                FlSpot(1, 180),
                FlSpot(2, 170),
                FlSpot(3, 140),
                FlSpot(4, 120),
                FlSpot(5, 130),
                FlSpot(6, 160),
              ],
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

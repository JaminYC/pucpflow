import 'package:flutter/material.dart';

class ConsumoCard extends StatelessWidget {
  final int porcentaje;
  final int litros;

  const ConsumoCard({
    Key? key,
    required this.porcentaje,
    required this.litros,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop, size: 30, color: Colors.blue),
                const SizedBox(width: 10),
                Text(
                  '$porcentaje%',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Text('Nivel de reserva', style: TextStyle(fontSize: 14)),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 26),
                const SizedBox(width: 10),
                Text(
                  '$litros L',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                const Text('Consumo hoy', style: TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

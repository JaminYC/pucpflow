import 'package:flutter/material.dart';

class TraceabilityScreen extends StatelessWidget {
  TraceabilityScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> historialDatos = [
    {
      'hora': '08:00',
      'temperatura': 35.5,
      'humedad': 60.0,
      'estado': 'Óptimo',
    },
    {
      'hora': '09:00',
      'temperatura': 36.2,
      'humedad': 59.0,
      'estado': 'Óptimo',
    },
    {
      'hora': '10:00',
      'temperatura': 45.5,
      'humedad': 75.0,
      'estado': 'Crítico',
    },
    {
      'hora': '11:00',
      'temperatura': 39.0,
      'humedad': 65.0,
      'estado': 'Óptimo',
    },
    {
      'hora': '12:00',
      'temperatura': 41.0,
      'humedad': 68.0,
      'estado': 'Óptimo',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text('Trazabilidad del Proceso'),
        backgroundColor: const Color(0xFF6B4226),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Histórico de Variables',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: historialDatos.length,
                itemBuilder: (context, index) {
                  final dato = historialDatos[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(
                        dato['estado'] == 'Óptimo' ? Icons.check_circle : Icons.warning,
                        color: dato['estado'] == 'Óptimo' ? Colors.green : Colors.red,
                        size: 36,
                      ),
                      title: Text(
                        '${dato['hora']} - Temp: ${dato['temperatura']}°C / Hum: ${dato['humedad']}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Estado: ${dato['estado']}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

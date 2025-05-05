import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  AlertsScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> listaAlertas = [
    {
      'hora': '10:15',
      'tipo': 'Temperatura Crítica',
      'mensaje': 'Temperatura excedió los 45°C.',
      'nivel': 'Alta',
    },
    {
      'hora': '11:00',
      'tipo': 'Humedad Alta',
      'mensaje': 'Humedad relativa superior al 70%.',
      'nivel': 'Media',
    },
    {
      'hora': '12:30',
      'tipo': 'Flujo de Aire Bajo',
      'mensaje': 'Flujo por debajo de 1.0 m³/s.',
      'nivel': 'Baja',
    },
  ];

  Color obtenerColor(String nivel) {
    switch (nivel) {
      case 'Alta':
        return Colors.red;
      case 'Media':
        return Colors.orange;
      case 'Baja':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData obtenerIcono(String nivel) {
    switch (nivel) {
      case 'Alta':
        return Icons.error;
      case 'Media':
        return Icons.warning;
      case 'Baja':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text('Alertas Inteligentes'),
        backgroundColor: const Color(0xFF6B4226),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Últimas Alertas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: listaAlertas.length,
                itemBuilder: (context, index) {
                  final alerta = listaAlertas[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(
                        obtenerIcono(alerta['nivel']),
                        color: obtenerColor(alerta['nivel']),
                        size: 36,
                      ),
                      title: Text(
                        '${alerta['hora']} - ${alerta['tipo']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(alerta['mensaje']),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: obtenerColor(alerta['nivel']).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          alerta['nivel'],
                          style: TextStyle(
                            color: obtenerColor(alerta['nivel']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

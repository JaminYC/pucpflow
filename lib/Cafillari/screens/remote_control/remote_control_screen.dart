import 'package:flutter/material.dart';

class RemoteControlScreen extends StatefulWidget {
  const RemoteControlScreen({Key? key}) : super(key: key);

  @override
  _RemoteControlScreenState createState() => _RemoteControlScreenState();
}

class _RemoteControlScreenState extends State<RemoteControlScreen> {
  bool ventiladorEncendido = false;
  bool calentadorEncendido = false;
  bool modoAutomatico = true;

  double temperaturaObjetivo = 37.0;
  double humedadObjetivo = 60.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text('Control Remoto'),
        backgroundColor: const Color(0xFF6B4226),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modo de Operación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: const Text('Automático'),
              value: modoAutomatico,
              onChanged: (value) {
                setState(() {
                  modoAutomatico = value;
                });
              },
            ),
            const Divider(height: 30),
            const Text(
              'Control de Equipos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: const Text('Ventilador Principal'),
              value: ventiladorEncendido,
              onChanged: modoAutomatico ? null : (value) {
                setState(() {
                  ventiladorEncendido = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Calentador de Secado'),
              value: calentadorEncendido,
              onChanged: modoAutomatico ? null : (value) {
                setState(() {
                  calentadorEncendido = value;
                });
              },
            ),
            const Divider(height: 30),
            const Text(
              'Ajuste de Setpoints',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Temperatura Objetivo: ${temperaturaObjetivo.toStringAsFixed(1)} °C'),
            Slider(
              value: temperaturaObjetivo,
              min: 30,
              max: 50,
              divisions: 20,
              label: temperaturaObjetivo.toStringAsFixed(1),
              onChanged: modoAutomatico ? null : (value) {
                setState(() {
                  temperaturaObjetivo = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Text('Humedad Objetivo: ${humedadObjetivo.toStringAsFixed(1)} %'),
            Slider(
              value: humedadObjetivo,
              min: 40,
              max: 80,
              divisions: 20,
              label: humedadObjetivo.toStringAsFixed(1),
              onChanged: modoAutomatico ? null : (value) {
                setState(() {
                  humedadObjetivo = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

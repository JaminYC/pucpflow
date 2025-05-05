import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text('Reportes Automáticos'),
        backgroundColor: const Color(0xFF6B4226),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.description, size: 100, color: Color(0xFF1976D2)),
            SizedBox(height: 20),
            Text(
              'Funcionalidad en desarrollo',
              style: TextStyle(fontSize: 20, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

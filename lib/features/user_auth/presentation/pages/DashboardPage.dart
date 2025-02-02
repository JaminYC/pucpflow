
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Dashboard de Bienestar"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildRadialProgress(),
          const SizedBox(height: 20),
          _buildTabs(),
          const SizedBox(height: 20),
          Expanded(
            child: _currentIndex == 0
                ? _buildStats()
                : _buildHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildRadialProgress() {
    return Center(
      child: SizedBox(
        height: 200,
        width: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: 0.75, // Ejemplo: 75% de bienestar general
              strokeWidth: 10,
              color: Colors.green,
              backgroundColor: Colors.green.withOpacity(0.2),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "75%",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  "Bienestar General",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = 0;
            });
          },
          child: Text(
            "Stats",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _currentIndex == 0 ? Colors.green : Colors.grey,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = 1;
            });
          },
          child: Text(
            "History",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _currentIndex == 1 ? Colors.green : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        ListTile(
          leading: Icon(Icons.directions_run, color: Colors.green),
          title: Text("Ejercicio"),
          subtitle: Text("Completado 5 días esta semana"),
        ),
        ListTile(
          leading: Icon(Icons.self_improvement, color: Colors.green),
          title: Text("Meditación"),
          subtitle: Text("20 minutos promedio por sesión"),
        ),
        ListTile(
          leading: Icon(Icons.people, color: Colors.green),
          title: Text("Interacciones Sociales"),
          subtitle: Text("Conectaste con 3 personas esta semana"),
        ),
        ListTile(
          leading: Icon(Icons.book, color: Colors.green),
          title: Text("Diario de Gratitud"),
          subtitle: Text("Escribiste en tu diario 4 días esta semana"),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        ListTile(
          title: Text("Lunes"),
          subtitle: Text("Ejercicio, Meditación, Llamada a un amigo"),
        ),
        ListTile(
          title: Text("Martes"),
          subtitle: Text("Meditación, Diario de Gratitud"),
        ),
        ListTile(
          title: Text("Miércoles"),
          subtitle: Text("Ejercicio, Llamada a un amigo"),
        ),
        ListTile(
          title: Text("Jueves"),
          subtitle: Text("Meditación, Diario de Gratitud"),
        ),
        ListTile(
          title: Text("Viernes"),
          subtitle: Text("Ejercicio, Meditación"),
        ),
      ],
    );
  }
}

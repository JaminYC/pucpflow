import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardVisual extends StatefulWidget {
  final String userId;

  const DashboardVisual({Key? key, required this.userId}) : super(key: key);

  @override
  State<DashboardVisual> createState() => _DashboardVisualState();
}

class _DashboardVisualState extends State<DashboardVisual> {
  late Map<String, dynamic> _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          _userData = userSnapshot.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se encontraron datos para este usuario.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar datos: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Extraer datos del usuario
    int totalPoints = _userData['total_points'] ?? 0;
    int completedSections = _userData['completed_sections'] ?? 0;
    Map<String, dynamic> progressByCategory = _userData['progress_by_category'] ?? {};
    List<dynamic> recentActivities = _userData['recent_activities'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("🎯 Dashboard Visual"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Animación en la parte superior
            Lottie.asset(
              'assets/animation.json',
              height: 150,
              width: 150,
              fit: BoxFit.cover,
            ),

            // Encabezado con puntos totales
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                children: [
                  Text(
                    "¡Hola, ${_userData['name'] ?? 'Usuario'}! 🌟",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Puntos Totales: $totalPoints",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Progreso general
            const Text(
              "Progreso General:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: completedSections / 4,
              color: Colors.purple,
              backgroundColor: Colors.purple.shade100,
            ),
            const SizedBox(height: 20),

            // Gráficos de progreso por categoría
            const Text(
              "Progreso por Categoría:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: progressByCategory.entries.map((entry) {
                    String category = entry.key;
                    double progress = entry.value.toDouble();
                    return PieChartSectionData(
                      value: progress * 100,
                      title: "$category\n${(progress * 100).toInt()}%",
                      color: _getCategoryColor(category),
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Actividades recientes
            const Text(
              "Actividades Recientes:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...recentActivities.map((activity) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  title: Text(activity['title']),
                  subtitle: Text(activity['date']),
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),

            // Botón de misiones diarias
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pronto: Misiones Diarias 🌟")),
                );
              },
              icon: const Icon(Icons.task),
              label: const Text("Ver Misiones Diarias"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                minimumSize: const Size.fromHeight(50),
              ),
            ),

            const SizedBox(height: 20),

            // Mensaje motivador
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Text(
                "💡 Recuerda: El progreso no se mide solo por los resultados, sino por el esfuerzo constante que pones en mejorar cada día.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.purple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Asigna colores a las categorías
  Color _getCategoryColor(String category) {
    switch (category) {
      case "Físico":
        return Colors.blue;
      case "Emocional":
        return Colors.pink;
      case "Intelectual":
        return Colors.green;
      case "Social":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

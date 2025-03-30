import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/animation.dart';

class DashboardVisual extends StatefulWidget {
  final String userId;

  const DashboardVisual({Key? key, required this.userId}) : super(key: key);

  @override
  State<DashboardVisual> createState() => _DashboardVisualState();
}

class _DashboardVisualState extends State<DashboardVisual> with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _userData;
  bool _isLoading = true;
  late AnimationController _buttonController;
  Animation<double>? _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _buttonController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _initializeButtonAnimation();
  }

  void _initializeButtonAnimation() {
    setState(() {
      _buttonAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
      );
      _buttonController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
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

    int totalPoints = _userData['total_points'] ?? 0;
    int completedSections = _userData['completed_sections'] ?? 0;
    Map<String, dynamic> progressByCategory = _userData['progress_by_category'] ?? {};
    List<dynamic> recentActivities = _userData['recent_activities'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("🎯 Dashboard Visual"),
        backgroundColor: Colors.black,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: SingleChildScrollView(
          key: ValueKey(_isLoading),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  children: [
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(seconds: 1),
                      child: Text(
                        "¡Hola, ${_userData['name'] ?? 'Usuario'}! 🌟",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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

              const Text(
                "Progreso General:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: completedSections / 4),
                duration: const Duration(seconds: 1),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  color: Colors.purple,
                  backgroundColor: Colors.purple.shade100,
                ),
              ),
              const SizedBox(height: 20),

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

              if (_buttonAnimation != null)
                ScaleTransition(
                  scale: _buttonAnimation!,
                  child: ElevatedButton.icon(
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
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

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

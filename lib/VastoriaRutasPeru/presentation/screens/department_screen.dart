import 'package:flutter/material.dart';

import '../../data/firestore_repository.dart';
import '../../data/models/department.dart';
import '../../data/models/route_model.dart';
import '../../data/models/signal_model.dart';

class DepartmentScreen extends StatelessWidget {
  const DepartmentScreen({super.key, required this.deptId});

  final String deptId;

  @override
  Widget build(BuildContext context) {
    final repository = FirestoreRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Departamento'),
      ),
      backgroundColor: const Color(0xFF0A0E27),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          StreamBuilder<Department>(
            stream: repository.watchDepartment(deptId),
            builder: (context, snapshot) {
              final dept = snapshot.data ?? Department.placeholder(deptId);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dept.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _tag('region: ${dept.region}'),
                      ...dept.tags.map(_tag),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Rutas',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<RouteModel>>(
            stream: repository.watchRoutes(deptId),
            builder: (context, snapshot) {
              final routes = snapshot.data ?? const [];
              if (routes.isEmpty) {
                return const Text('No hay rutas aun.', style: TextStyle(color: Colors.white60));
              }
              return Column(
                children: routes.map(_routeTile).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Senales',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          StreamBuilder<SignalModel>(
            stream: repository.watchSignal(deptId),
            builder: (context, snapshot) {
              final signal = snapshot.data ?? SignalModel.placeholder();
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signal.weatherSummary,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    if (signal.alerts.isEmpty)
                      const Text('Sin alertas.', style: TextStyle(color: Colors.white60))
                    else
                      ...signal.alerts.map(
                        (alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('- $alert', style: const TextStyle(color: Colors.white70)),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _routeTile(RouteModel route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.map, color: Color(0xFF8B5CF6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${route.durationDays} dias - ${route.difficulty}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }
}

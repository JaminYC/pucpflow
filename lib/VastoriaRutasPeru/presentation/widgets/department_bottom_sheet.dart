import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firestore_repository.dart';
import '../../data/models/department.dart';
import '../../data/models/department_stats.dart';
import '../../data/models/route_model.dart';
import 'tourist_attractions_sheet.dart';

class DepartmentBottomSheet extends StatelessWidget {
  const DepartmentBottomSheet({
    super.key,
    required this.deptId,
    required this.repository,
    required this.onExplore,
  });

  final String deptId;
  final FirestoreRepository repository;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121933),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _pill('region: ${dept.region}'),
                            ...dept.tags.map(_pill),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                StreamBuilder<DepartmentStats>(
                  stream: repository.watchStats(deptId),
                  builder: (context, snapshot) {
                    final stats = snapshot.data ?? DepartmentStats.placeholder();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KPIs',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _kpiTile('Rutas', stats.routesCount.toString()),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _kpiTile('Lugares', stats.placesCount.toString()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _kpiTile('Temporada', stats.recommendedSeason),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _kpiTile(
                                'Actualizado',
                                _formatTimestamp(stats.lastUpdated),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _featuredRoute(stats.featuredRouteId),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                const Text(
                  'Rutas destacadas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<RouteModel>>(
                  stream: repository.watchTopRoutes(deptId, limit: 3),
                  builder: (context, snapshot) {
                    final routes = snapshot.data ?? const [];
                    if (routes.isEmpty) {
                      return const Text(
                        'Sin rutas por ahora.',
                        style: TextStyle(color: Colors.white60),
                      );
                    }
                    return Column(
                      children: routes
                          .map((route) => _routeCard(route))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                StreamBuilder<Department>(
                  stream: repository.watchDepartment(deptId),
                  builder: (context, snapshot) {
                    final dept = snapshot.data ?? Department.placeholder(deptId);
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openAttractionsSheet(context, dept),
                        icon: const Icon(Icons.checklist),
                        label: const Text('Checklist de lugares'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF57C0FF),
                          side: const BorderSide(color: Color(0xFF57C0FF), width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onExplore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF57C0FF),
                      foregroundColor: const Color(0xFF0B1020),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Explorar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _featuredRoute(String routeId) {
    if (routeId.isEmpty) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<RouteModel?>(
      stream: repository.watchRoute(routeId),
      builder: (context, snapshot) {
        final route = snapshot.data;
        if (route == null) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              const Icon(Icons.route, color: Color(0xFF57C0FF)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ruta destacada',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      route.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAttractionsSheet(BuildContext context, Department dept) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return TouristAttractionsSheet(
          departmentId: dept.id,
          departmentName: dept.name,
          onNavigateTo: (_, __) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La navegacion se inicia desde el mapa.'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _kpiTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeCard(RouteModel route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF57C0FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.map_outlined, color: Color(0xFF57C0FF)),
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

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '--';
    final date = timestamp.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

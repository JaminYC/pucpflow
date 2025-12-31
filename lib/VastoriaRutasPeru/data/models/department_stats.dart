import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentStats {
  final int routesCount;
  final int placesCount;
  final String featuredRouteId;
  final String recommendedSeason;
  final Timestamp? lastUpdated;

  const DepartmentStats({
    required this.routesCount,
    required this.placesCount,
    required this.featuredRouteId,
    required this.recommendedSeason,
    required this.lastUpdated,
  });

  factory DepartmentStats.fromMap(Map<String, dynamic> data) {
    return DepartmentStats(
      routesCount: (data['routesCount'] ?? 0) as int,
      placesCount: (data['placesCount'] ?? 0) as int,
      featuredRouteId: (data['featuredRouteId'] ?? '').toString(),
      recommendedSeason: (data['recommendedSeason'] ?? '--').toString(),
      lastUpdated: data['lastUpdated'] as Timestamp?,
    );
  }

  static DepartmentStats placeholder() {
    return const DepartmentStats(
      routesCount: 0,
      placesCount: 0,
      featuredRouteId: '',
      recommendedSeason: '--',
      lastUpdated: null,
    );
  }
}

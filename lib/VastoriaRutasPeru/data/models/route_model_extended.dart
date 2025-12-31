import 'package:latlong2/latlong.dart';
import 'day_itinerary_model.dart';
import 'waypoint_model.dart';

/// Modelo extendido de ruta con itinerario completo
class RouteModelExtended {
  final String id;
  final String deptId;
  final String name;
  final int durationDays;
  final String difficulty; // baja, media, alta
  final String summary;
  final List<String> tags;

  // Datos de itinerario
  final LatLng startPoint;
  final LatLng endPoint;
  final double estimatedDistanceKm;
  final String transportMode; // bus, auto, trekking, mixto
  final List<WaypointModel> waypoints;
  final Map<int, DayItineraryModel> dailyPlan; // key = dayNumber

  // Información de temporada y demanda
  final String recommendedSeason; // ene-mar, abr-jun, jul-sep, oct-dic
  final Map<String, int> demandByMonth; // month -> demand level (1-5)
  final List<String> weatherWarnings;
  final double? averageCostPerPerson; // en USD

  const RouteModelExtended({
    required this.id,
    required this.deptId,
    required this.name,
    required this.durationDays,
    required this.difficulty,
    required this.summary,
    required this.tags,
    required this.startPoint,
    required this.endPoint,
    required this.estimatedDistanceKm,
    required this.transportMode,
    this.waypoints = const [],
    this.dailyPlan = const {},
    this.recommendedSeason = '',
    this.demandByMonth = const {},
    this.weatherWarnings = const [],
    this.averageCostPerPerson,
  });

  factory RouteModelExtended.fromMap(String id, Map<String, dynamic> data) {
    // Parse waypoints
    final waypointsData = data['waypoints'] as List<dynamic>? ?? [];
    final waypoints = waypointsData
        .asMap()
        .entries
        .map((entry) => WaypointModel.fromMap(
              '${id}_wp_${entry.key}',
              entry.value as Map<String, dynamic>,
            ))
        .toList();

    // Parse daily plan
    final dailyPlanData = data['dailyPlan'] as Map<String, dynamic>? ?? {};
    final dailyPlan = <int, DayItineraryModel>{};
    dailyPlanData.forEach((key, value) {
      final dayNumber = int.tryParse(key) ?? 0;
      if (dayNumber > 0) {
        dailyPlan[dayNumber] = DayItineraryModel.fromMap(
          dayNumber,
          value as Map<String, dynamic>,
        );
      }
    });

    // Parse demand by month
    final demandData = data['demandByMonth'] as Map<String, dynamic>? ?? {};
    final demandByMonth = <String, int>{};
    demandData.forEach((key, value) {
      demandByMonth[key] = (value as num).toInt();
    });

    return RouteModelExtended(
      id: id,
      deptId: (data['deptId'] ?? '').toString(),
      name: (data['name'] ?? id).toString(),
      durationDays: (data['durationDays'] ?? 1) as int,
      difficulty: (data['difficulty'] ?? 'media').toString(),
      summary: (data['summary'] ?? '').toString(),
      tags: List<String>.from(data['tags'] ?? const <String>[]),
      startPoint: LatLng(
        ((data['startLatitude'] ?? -12.0) as num).toDouble(),
        ((data['startLongitude'] ?? -77.0) as num).toDouble(),
      ),
      endPoint: LatLng(
        ((data['endLatitude'] ?? -12.0) as num).toDouble(),
        ((data['endLongitude'] ?? -77.0) as num).toDouble(),
      ),
      estimatedDistanceKm: ((data['estimatedDistanceKm'] ?? 0.0) as num).toDouble(),
      transportMode: (data['transportMode'] ?? 'mixto').toString(),
      waypoints: waypoints,
      dailyPlan: dailyPlan,
      recommendedSeason: (data['recommendedSeason'] ?? '').toString(),
      demandByMonth: demandByMonth,
      weatherWarnings: List<String>.from(data['weatherWarnings'] ?? const <String>[]),
      averageCostPerPerson: (data['averageCostPerPerson'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deptId': deptId,
      'name': name,
      'durationDays': durationDays,
      'difficulty': difficulty,
      'summary': summary,
      'tags': tags,
      'startLatitude': startPoint.latitude,
      'startLongitude': startPoint.longitude,
      'endLatitude': endPoint.latitude,
      'endLongitude': endPoint.longitude,
      'estimatedDistanceKm': estimatedDistanceKm,
      'transportMode': transportMode,
      'waypoints': waypoints.map((w) => w.toMap()).toList(),
      'dailyPlan': dailyPlan.map((key, value) => MapEntry(key.toString(), value.toMap())),
      'recommendedSeason': recommendedSeason,
      'demandByMonth': demandByMonth,
      'weatherWarnings': weatherWarnings,
      if (averageCostPerPerson != null) 'averageCostPerPerson': averageCostPerPerson,
    };
  }

  /// Obtiene el nivel de demanda para un mes específico (1-12)
  int getDemandForMonth(int month) {
    final monthNames = ['ene', 'feb', 'mar', 'abr', 'may', 'jun',
                        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    if (month < 1 || month > 12) return 3; // demanda media por defecto
    return demandByMonth[monthNames[month - 1]] ?? 3;
  }

  /// Verifica si la fecha es recomendada para este viaje
  bool isRecommendedDate(DateTime date) {
    final month = date.month;
    final demand = getDemandForMonth(month);

    // Si la demanda es muy alta (5), no es recomendado
    if (demand >= 5) return false;

    // Verificar si está en la temporada recomendada
    if (recommendedSeason.isNotEmpty) {
      final seasonMap = {
        'ene-mar': [1, 2, 3],
        'abr-jun': [4, 5, 6],
        'jul-sep': [7, 8, 9],
        'oct-dic': [10, 11, 12],
      };
      final recommendedMonths = seasonMap[recommendedSeason] ?? [];
      return recommendedMonths.contains(month);
    }

    return true;
  }

  /// Obtiene mensaje sobre la demanda en una fecha
  String getDemandMessage(DateTime date) {
    final demand = getDemandForMonth(date.month);
    switch (demand) {
      case 1:
        return '✅ Temporada baja - Excelente disponibilidad';
      case 2:
        return '✅ Demanda moderada - Buena disponibilidad';
      case 3:
        return '⚠️ Temporada media - Reservar con anticipación';
      case 4:
        return '⚠️ Alta demanda - Reservar con 2-3 semanas de anticipación';
      case 5:
        return '🚫 Temporada alta - Muy difícil conseguir disponibilidad';
      default:
        return 'ℹ️ Sin información de demanda';
    }
  }
}

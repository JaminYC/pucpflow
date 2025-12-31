/// Plan detallado de un día del itinerario
class DayItineraryModel {
  final int dayNumber;
  final String title;
  final List<String> waypointIds; // IDs de waypoints en orden
  final String? accommodationName;
  final String? accommodationPlaceId;
  final List<String> mealSuggestions; // IDs o nombres de restaurantes
  final String notes;
  final double estimatedDistanceKm;
  final double estimatedDurationHours;

  const DayItineraryModel({
    required this.dayNumber,
    required this.title,
    required this.waypointIds,
    this.accommodationName,
    this.accommodationPlaceId,
    this.mealSuggestions = const [],
    this.notes = '',
    this.estimatedDistanceKm = 0.0,
    this.estimatedDurationHours = 0.0,
  });

  factory DayItineraryModel.fromMap(int dayNumber, Map<String, dynamic> data) {
    return DayItineraryModel(
      dayNumber: dayNumber,
      title: (data['title'] ?? 'Día $dayNumber').toString(),
      waypointIds: List<String>.from(data['waypointIds'] ?? const <String>[]),
      accommodationName: data['accommodationName']?.toString(),
      accommodationPlaceId: data['accommodationPlaceId']?.toString(),
      mealSuggestions: List<String>.from(data['mealSuggestions'] ?? const <String>[]),
      notes: (data['notes'] ?? '').toString(),
      estimatedDistanceKm: ((data['estimatedDistanceKm'] ?? 0.0) as num).toDouble(),
      estimatedDurationHours: ((data['estimatedDurationHours'] ?? 0.0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'waypointIds': waypointIds,
      if (accommodationName != null) 'accommodationName': accommodationName,
      if (accommodationPlaceId != null) 'accommodationPlaceId': accommodationPlaceId,
      'mealSuggestions': mealSuggestions,
      'notes': notes,
      'estimatedDistanceKm': estimatedDistanceKm,
      'estimatedDurationHours': estimatedDurationHours,
    };
  }
}

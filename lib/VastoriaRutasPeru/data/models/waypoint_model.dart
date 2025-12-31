import 'package:latlong2/latlong.dart';

/// Modelo de un punto de parada en el itinerario
class WaypointModel {
  final String id;
  final String name;
  final LatLng location;
  final String description;
  final int dayNumber;
  final String type; // restaurant, hotel, attraction, viewpoint, transport
  final double estimatedTimeHours;
  final List<String> photoUrls;
  final String? placeId; // Google Places ID
  final double? rating;
  final String? priceLevel; // $, $$, $$$
  final Map<String, String>? openingHours;

  const WaypointModel({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.dayNumber,
    required this.type,
    required this.estimatedTimeHours,
    this.photoUrls = const [],
    this.placeId,
    this.rating,
    this.priceLevel,
    this.openingHours,
  });

  factory WaypointModel.fromMap(String id, Map<String, dynamic> data) {
    return WaypointModel(
      id: id,
      name: (data['name'] ?? '').toString(),
      location: LatLng(
        (data['latitude'] ?? 0.0) as double,
        (data['longitude'] ?? 0.0) as double,
      ),
      description: (data['description'] ?? '').toString(),
      dayNumber: (data['dayNumber'] ?? 1) as int,
      type: (data['type'] ?? 'attraction').toString(),
      estimatedTimeHours: ((data['estimatedTimeHours'] ?? 1.0) as num).toDouble(),
      photoUrls: List<String>.from(data['photoUrls'] ?? const <String>[]),
      placeId: data['placeId']?.toString(),
      rating: (data['rating'] as num?)?.toDouble(),
      priceLevel: data['priceLevel']?.toString(),
      openingHours: data['openingHours'] != null
          ? Map<String, String>.from(data['openingHours'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'description': description,
      'dayNumber': dayNumber,
      'type': type,
      'estimatedTimeHours': estimatedTimeHours,
      'photoUrls': photoUrls,
      if (placeId != null) 'placeId': placeId,
      if (rating != null) 'rating': rating,
      if (priceLevel != null) 'priceLevel': priceLevel,
      if (openingHours != null) 'openingHours': openingHours,
    };
  }

  String getTypeIcon() {
    switch (type) {
      case 'restaurant':
        return '🍽️';
      case 'hotel':
        return '🏨';
      case 'attraction':
        return '🎯';
      case 'viewpoint':
        return '🏔️';
      case 'transport':
        return '🚌';
      default:
        return '📍';
    }
  }
}

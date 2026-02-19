import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Servicio para integración con Google Maps APIs
class GoogleRoutesService {
  // Google Maps API Key (configurado en AndroidManifest y Info.plist)
  static const String _apiKey = ''; // Clave eliminada — configurar en entorno seguro
  static const String _directionsBaseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Calcula ruta entre múltiples waypoints
  Future<RouteDirections> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
    String mode = 'driving', // driving, walking, transit
  }) async {
    try {
      final waypointsParam = waypoints.isEmpty
          ? ''
          : '&waypoints=${waypoints.map((w) => '${w.latitude},${w.longitude}').join('|')}';

      final url = '$_directionsBaseUrl?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}'
          '$waypointsParam&'
          'mode=$mode&'
          'language=es&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['routes'] is List && (data['routes'] as List).isNotEmpty) {
          return RouteDirections.fromGoogleMapsJson(data['routes'][0]);
        } else {
          throw Exception('No se encontró ruta: ${data['status']}');
        }
      } else {
        throw Exception('Error en la petición: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener direcciones: $e');
    }
  }

  /// Autocomplete de búsqueda (Places Autocomplete API)
  Future<List<PlaceResult>> searchPlaces({
    required String query,
    LatLng? location,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      // Usar Places Autocomplete para búsqueda más inteligente
      final locationBias = location != null
          ? '&location=${location.latitude},${location.longitude}&radius=500000'
          : '&components=country:pe'; // Restringir a Perú

      final url = '$_placesBaseUrl/autocomplete/json?'
          'input=$query'
          '$locationBias&'
          'language=es&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;

          // Para cada predicción, obtener detalles para tener coordenadas
          final results = <PlaceResult>[];
          for (var prediction in predictions.take(5)) {
            final placeId = prediction['place_id'] as String;
            final details = await getPlaceDetails(placeId);
            if (details != null) {
              results.add(PlaceResult(
                placeId: placeId,
                name: prediction['structured_formatting']['main_text'] ?? '',
                location: details.location,
                vicinity: prediction['description'],
                rating: details.rating,
              ));
            }
          }
          return results;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Busca lugares cercanos a una ubicación
  Future<List<PlaceResult>> searchNearbyPlaces({
    required LatLng location,
    required String type, // restaurant, lodging, tourist_attraction
    int radius = 5000, // metros
  }) async {
    try {
      final url = '$_placesBaseUrl/nearbysearch/json?'
          'location=${location.latitude},${location.longitude}&'
          'radius=$radius&'
          'type=$type&'
          'language=es&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results
              .map((place) => PlaceResult.fromJson(place))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Obtiene detalles de un lugar por Place ID
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = '$_placesBaseUrl/details/json?'
          'place_id=$placeId&'
          'language=es&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        }
      }
      return null;
    } catch (e) {
      print('Error obteniendo detalles del lugar: $e');
      return null;
    }
  }

  /// Calcula matriz de distancias entre múltiples orígenes y destinos
  Future<DistanceMatrix> getDistanceMatrix({
    required List<LatLng> origins,
    required List<LatLng> destinations,
    String mode = 'driving',
  }) async {
    try {
      final originsParam = origins
          .map((o) => '${o.latitude},${o.longitude}')
          .join('|');
      final destinationsParam = destinations
          .map((d) => '${d.latitude},${d.longitude}')
          .join('|');

      final url = 'https://maps.googleapis.com/maps/api/distancematrix/json?'
          'origins=$originsParam&'
          'destinations=$destinationsParam&'
          'mode=$mode&'
          'language=es&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DistanceMatrix.fromJson(data);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al calcular distancias: $e');
    }
  }
}

/// Resultado de la petición de direcciones
class RouteDirections {
  final String summary;
  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> polylinePoints;
  final List<RouteStep> steps;

  const RouteDirections({
    required this.summary,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polylinePoints,
    required this.steps,
  });

  factory RouteDirections.fromGoogleMapsJson(Map<String, dynamic> route) {
    final legs = route['legs'] as List;
    final firstLeg = legs.first;

    // Decodificar polyline
    final polyline = route['overview_polyline']['points'] as String;
    final points = _decodePolyline(polyline);

    // Extraer steps
    final stepsData = firstLeg['steps'] as List;
    final steps = stepsData
        .map((step) => RouteStep.fromJson(step))
        .toList();

    return RouteDirections(
      summary: route['summary'] ?? '',
      distanceMeters: (firstLeg['distance']['value'] as num).toDouble(),
      durationSeconds: (firstLeg['duration']['value'] as num).toDouble(),
      polylinePoints: points,
      steps: steps,
    );
  }

  double get distanceKm => distanceMeters / 1000;
  double get durationHours => durationSeconds / 3600;

  /// Decodifica polyline de Google Maps
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}

/// Paso individual de una ruta
class RouteStep {
  final String instructions;
  final double distanceMeters;
  final double durationSeconds;
  final LatLng startLocation;
  final LatLng endLocation;

  const RouteStep({
    required this.instructions,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startLocation,
    required this.endLocation,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final startLoc = json['start_location'];
    final endLoc = json['end_location'];

    return RouteStep(
      instructions: _stripHtml(json['html_instructions'] ?? ''),
      distanceMeters: (json['distance']['value'] as num).toDouble(),
      durationSeconds: (json['duration']['value'] as num).toDouble(),
      startLocation: LatLng(startLoc['lat'], startLoc['lng']),
      endLocation: LatLng(endLoc['lat'], endLoc['lng']),
    );
  }

  static String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}

/// Resultado de búsqueda de lugar
class PlaceResult {
  final String placeId;
  final String name;
  final LatLng location;
  final double? rating;
  final String? vicinity;
  final List<String> types;

  const PlaceResult({
    required this.placeId,
    required this.name,
    required this.location,
    this.rating,
    this.vicinity,
    this.types = const [],
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']['location'];
    return PlaceResult(
      placeId: json['place_id'],
      name: json['name'],
      location: LatLng(geometry['lat'], geometry['lng']),
      rating: (json['rating'] as num?)?.toDouble(),
      vicinity: json['vicinity'],
      types: List<String>.from(json['types'] ?? []),
    );
  }
}

/// Detalles completos de un lugar
class PlaceDetails {
  final String placeId;
  final String name;
  final LatLng location;
  final String? formattedAddress;
  final String? formattedPhoneNumber;
  final double? rating;
  final List<String> photoReferences;
  final Map<String, String>? openingHours;

  const PlaceDetails({
    required this.placeId,
    required this.name,
    required this.location,
    this.formattedAddress,
    this.formattedPhoneNumber,
    this.rating,
    this.photoReferences = const [],
    this.openingHours,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final photos = json['photos'] as List? ?? [];
    final photoRefs = photos
        .map((p) => p['photo_reference'] as String)
        .toList();

    final geometry = json['geometry']['location'];

    return PlaceDetails(
      placeId: json['place_id'],
      name: json['name'],
      location: LatLng(geometry['lat'], geometry['lng']),
      formattedAddress: json['formatted_address'],
      formattedPhoneNumber: json['formatted_phone_number'],
      rating: (json['rating'] as num?)?.toDouble(),
      photoReferences: photoRefs,
    );
  }
}

/// Matriz de distancias
class DistanceMatrix {
  final List<List<DistanceElement>> rows;

  const DistanceMatrix({required this.rows});

  factory DistanceMatrix.fromJson(Map<String, dynamic> json) {
    final rowsData = json['rows'] as List;
    final rows = rowsData.map((row) {
      final elements = row['elements'] as List;
      return elements
          .map((el) => DistanceElement.fromJson(el))
          .toList();
    }).toList();

    return DistanceMatrix(rows: rows);
  }
}

class DistanceElement {
  final double distanceMeters;
  final double durationSeconds;
  final String status;

  const DistanceElement({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.status,
  });

  factory DistanceElement.fromJson(Map<String, dynamic> json) {
    if (json['status'] != 'OK') {
      return DistanceElement(
        distanceMeters: 0,
        durationSeconds: 0,
        status: json['status'],
      );
    }

    return DistanceElement(
      distanceMeters: (json['distance']['value'] as num).toDouble(),
      durationSeconds: (json['duration']['value'] as num).toDouble(),
      status: json['status'],
    );
  }

  double get distanceKm => distanceMeters / 1000;
  double get durationHours => durationSeconds / 3600;
}

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../services/location_service.dart';
import '../../services/google_routes_service.dart';
import 'search_bar_widget.dart';
import 'tourist_attractions_sheet.dart';
import 'vastoria_ai_chat_widget.dart';

/// Mapa 3D espectacular para VASTORIA
///
/// Características premium:
/// - Terreno 3D real de los Andes
/// - Departamentos con extrusión (altura 3D)
/// - Pitch dinámico (45-60°) para vista oblicua
/// - Animaciones de cámara cinematográficas
/// - Efectos de iluminación y sombras
/// - Transiciones suaves tipo "fly-to"
class PeruMap extends StatefulWidget {
  const PeruMap({
    super.key,
    required this.onDeptSelected,
    this.enableSelection = true,
  });

  final ValueChanged<String> onDeptSelected;
  final bool enableSelection;

  @override
  State<PeruMap> createState() => _PeruMapState();
}

class _PeruMapState extends State<PeruMap> with TickerProviderStateMixin {
  // IDs de capas y fuentes
  static const _sourceId = 'peru_departments';
  static const _fillExtrusionLayerId = 'departments_3d';
  static const _highlightLayerId = 'departments_highlight_3d';
  static const _tapLayerId = 'departments_tap';
  static const _markerSourceId = 'peru_departments_markers';
  static const _markerLayerId = 'departments_markers';
  static const _labelLayerId = 'departments_labels';

  // Token de Mapbox
  static const _fallbackToken = '';

  MapboxMap? _mapboxMap;
  bool _styleReady = false;
  String? _selectedDeptId;
  final List<_DeptPolygon> _departmentPolygons = [];

  // Animación de cámara
  AnimationController? _cameraAnimController;
  Animation<double>? _pitchAnimation;

  // Location service
  final LocationService _locationService = LocationService();
  ll.LatLng? _currentLocation;
  bool _isLoadingLocation = false;

  // Search results
  final List<PlaceResult> _searchMarkers = [];

  @override
  void initState() {
    super.initState();
    const token = String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');
    final resolvedToken = token.isNotEmpty ? token : _fallbackToken;
    if (resolvedToken.isNotEmpty) {
      MapboxOptions.setAccessToken(resolvedToken);
    }

    _loadDepartmentPolygons();


    // Configurar animación de entrada
    _cameraAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pitchAnimation = Tween<double>(begin: 0, end: 55).animate(
      CurvedAnimation(parent: _cameraAnimController!, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _cameraAnimController?.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    debugPrint('🎨 Mapbox 3D style loaded - Configurando terreno y capas...');

    // 1. HABILITAR TERRENO 3D (Montañas de los Andes)
    await _enableTerrain();

    // 2. Cargar GeoJSON de departamentos
    final geojson = await rootBundle.loadString('assets/peru_departments.geojson');
    if (_departmentPolygons.isEmpty) {
      _cacheDepartmentPolygons(geojson);
    }

    await _mapboxMap?.style.addSource(GeoJsonSource(
      id: _sourceId,
      data: geojson,
    ));

    await _mapboxMap?.style.addSource(GeoJsonSource(
      id: _markerSourceId,
      data: jsonEncode(_buildMarkerGeoJson()),
    ));

    // 3. Marcadores visibles para seleccionar departamentos (sin poligonos)
    await _mapboxMap?.style.addLayer(_createMarkerLayer());
    await _mapboxMap?.style.addLayer(_createLabelLayer());

    // 4. Habilitar edificios 3D (si hay en la zona urbana)
    await _enable3DBuildings();

    _styleReady = true;
    debugPrint('✅ Mapa 3D configurado');

    // Animar entrada con pitch
    _cameraAnimController?.forward();
    _pitchAnimation?.addListener(() {
      _updateCameraPitch(_pitchAnimation!.value);
    });
  }

  /// Habilita el terreno 3D de Mapbox (elevación real)
  Future<void> _enableTerrain() async {
    try {
      // Agregar source de terreno DEM (Digital Elevation Model)
      await _mapboxMap?.style.addSource(RasterDemSource(
        id: 'mapbox-dem',
        url: 'mapbox://mapbox.terrain-rgb',
        tileSize: 512,
        maxzoom: 14,
      ));

      // Configurar terreno con exageración para efecto dramático
      // En Mapbox Flutter SDK, setStyleTerrain recibe String JSON
      await _mapboxMap?.style.setStyleTerrain(
        '{"source": "mapbox-dem", "exaggeration": 1.5}',
      );

      debugPrint('✅ Terreno 3D habilitado (exageración: 1.5x)');
    } catch (e) {
      debugPrint('⚠️ Error habilitando terreno: $e');
    }
  }

  /// Habilita edificios 3D en zonas urbanas
  Future<void> _enable3DBuildings() async {
    try {
      // Mapbox Standard ya incluye edificios 3D
      // La iluminación se configura automáticamente con el estilo
      debugPrint('✅ Edificios 3D incluidos en Mapbox Standard');
    } catch (e) {
      debugPrint('⚠️ Error configurando edificios 3D: $e');
    }
  }

  /// Capa 3D con extrusión (departamentos con altura)
  /// Altura dinámica basada en routesCount
  FillExtrusionLayer _create3DFillExtrusionLayer() {
    return FillExtrusionLayer(
      id: _fillExtrusionLayerId,
      sourceId: _sourceId,

      // Color base por región
      fillExtrusionColor: _buildRegionColorExpression(),

      // Altura de extrusión (más rutas = más alto)
      // Rango: 5,000m - 50,000m (escala exagerada para visibilidad)
      fillExtrusionHeight: _buildHeightExpression(),

      // Base de extrusión (nivel del suelo)
      fillExtrusionBase: 0,

      // Opacity moderada para ver el terreno debajo
      fillExtrusionOpacity: 0.75,

      // Vertical gradient para efecto de profundidad
      fillExtrusionVerticalGradient: true,
    );
  }

  /// Expresión de color por región (retorna int color value)
  int _buildRegionColorExpression() {
    // En producción, usar expression engine de Mapbox
    // Por ahora, color base cyan VASTORIA
    return 0xFF57C0FF;
  }

  /// Expresión de altura 3D
  double _buildHeightExpression() {
    // Altura base de 10,000 metros para visibilidad
    return 10000.0;
  }

  /// Capa de highlight 3D para departamento seleccionado
  FillExtrusionLayer _create3DHighlightLayer(String? deptId) {
    return FillExtrusionLayer(
      id: _highlightLayerId,
      sourceId: _sourceId,
      filter: _buildDeptFilter(deptId),

      // Color highlight brillante
      fillExtrusionColor: 0xFFFFD700, // Dorado

      // Altura extra para destacar
      fillExtrusionHeight: 60000.0, // Más alto que el resto

      fillExtrusionBase: 0,
      fillExtrusionOpacity: 0.9,
      fillExtrusionVerticalGradient: true,
    );
  }

  /// Capa invisible para detectar taps en departamentos
  FillLayer _createTapLayer() {
    return FillLayer(
      id: _tapLayerId,
      sourceId: _sourceId,
      fillColor: 0x00000000,
      fillOpacity: 0.01,
    );
  }

  CircleLayer _createMarkerLayer() {
    return CircleLayer(
      id: _markerLayerId,
      sourceId: _markerSourceId,
      circleRadius: 8.0,
      circleColor: 0xFF57C0FF,
      circleOpacity: 0.9,
      circleStrokeWidth: 2.0,
      circleStrokeColor: 0xFFFFFFFF,
    );
  }

  SymbolLayer _createLabelLayer() {
    return SymbolLayer(
      id: _labelLayerId,
      sourceId: _markerSourceId,
      textField: '{name}',
      textSize: 11.0,
      textColor: 0xFFFFFFFF,
      textHaloColor: 0xCC0A0E27,
      textHaloWidth: 1.5,
      textOffset: [0.0, 1.2],
      textAnchor: TextAnchor.TOP,
      textAllowOverlap: true,
      textIgnorePlacement: true,
    );
  }

  List<Object> _buildDeptFilter(String? deptId) {
    final id = deptId ?? '';
    return [
      '==',
      ['get', 'id'],
      id,
    ];
  }

  Future<void> _loadDepartmentPolygons() async {
    try {
      final geojson =
          await rootBundle.loadString('assets/peru_departments.geojson');
      _cacheDepartmentPolygons(geojson);
    } catch (e) {
      debugPrint('Error cargando departamentos: $e');
    }
  }

  Map<String, dynamic> _buildMarkerGeoJson() {
    return {
      'type': 'FeatureCollection',
      'features': _departmentPolygons.map((dept) {
        final center = _calculateCentroid(dept.points);
        return {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [center.longitude, center.latitude],
          },
          'properties': {
            'id': dept.id,
            'name': dept.name,
          },
        };
      }).toList(),
    };
  }

  void _cacheDepartmentPolygons(String geojsonString) {
    _departmentPolygons.clear();

    final geojson = jsonDecode(geojsonString);
    final features = geojson['features'] as List? ?? [];

    for (final feature in features) {
      if (feature is! Map) continue;
      final props = feature['properties'] as Map?;
      final geometry = feature['geometry'] as Map?;
      if (props == null || geometry == null) continue;
      if (geometry['type'] != 'Polygon') continue;

      final id = props['id']?.toString() ?? '';
      final name = props['name']?.toString() ?? id;
      if (id.isEmpty) continue;

      final coordinates = geometry['coordinates'] as List?;
      if (coordinates == null || coordinates.isEmpty) continue;

      final coordArray = coordinates[0] is List && (coordinates[0] as List).isNotEmpty
          ? coordinates[0] as List
          : coordinates;

      final points = <ll.LatLng>[];
      for (final coord in coordArray) {
        if (coord is! List || coord.length < 2) continue;
        final lng = (coord[0] as num).toDouble();
        final lat = (coord[1] as num).toDouble();
        points.add(ll.LatLng(lat, lng));
      }

      if (points.isNotEmpty) {
        _departmentPolygons.add(_DeptPolygon(id: id, name: name, points: points));
      }
    }
  }

  ll.LatLng _calculateCentroid(List<ll.LatLng> points) {
    double sumLat = 0;
    double sumLng = 0;
    for (final point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }
    return ll.LatLng(sumLat / points.length, sumLng / points.length);
  }

  _DeptPolygon? _findDepartmentByPoint(ll.LatLng point) {
    for (final dept in _departmentPolygons) {
      if (_isPointInPolygon(point, dept.points)) {
        return dept;
      }
    }
    return null;
  }

  bool _isPointInPolygon(ll.LatLng point, List<ll.LatLng> polygon) {
    int intersections = 0;
    for (int i = 0; i < polygon.length - 1; i++) {
      final p1 = polygon[i];
      final p2 = polygon[i + 1];

      if (_rayIntersectsSegment(point, p1, p2)) {
        intersections++;
      }
    }
    return intersections % 2 == 1;
  }

  bool _rayIntersectsSegment(ll.LatLng point, ll.LatLng a, ll.LatLng b) {
    final px = point.longitude;
    final py = point.latitude;
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;

    if (ay > by) {
      return _rayIntersectsSegmentHelper(px, py, bx, by, ax, ay);
    }
    return _rayIntersectsSegmentHelper(px, py, ax, ay, bx, by);
  }

  bool _rayIntersectsSegmentHelper(
    double px,
    double py,
    double ax,
    double ay,
    double bx,
    double by,
  ) {
    if (py == ay || py == by) py += 0.00001;
    if (py < ay || py > by) return false;
    if (px >= ax && px >= bx) return false;
    if (px < ax && px < bx) return true;

    final m = (by - ay) / (bx - ax);
    final x = (py - ay) / m + ax;
    return px < x;
  }

  /// Actualiza el pitch de la cámara (animación de entrada)
  Future<void> _updateCameraPitch(double pitch) async {
    if (_mapboxMap == null) return;

    try {
      await _mapboxMap?.setCamera(CameraOptions(
        pitch: pitch,
      ));
    } catch (e) {
      // Ignorar errores durante animación
    }
  }

  /// Actualiza highlight y vuela al departamento
  Future<void> _updateHighlight(String deptId) async {
    _selectedDeptId = deptId;
    if (_mapboxMap == null) return;

    if (_styleReady) {
      try {
        await _mapboxMap?.style.updateLayer(_create3DHighlightLayer(deptId));
      } catch (_) {
        // Highlight no disponible cuando se ocultan poligonos.
      }
    }

    await _flyToDepartment(deptId);
  }

  /// Animación tipo "fly-to" cinematográfica
  /// Vista oblicua con pitch alto para apreciar el 3D
  Future<void> _flyToDepartment(String deptId) async {
    try {
      final features = await _mapboxMap?.querySourceFeatures(
        _sourceId,
        SourceQueryOptions(
          sourceLayerIds: [],
          filter: '["==", ["get", "id"], "$deptId"]',
        ),
      );

      if (features == null || features.isEmpty) return;

      final queriedFeature = features.first;
      if (queriedFeature == null) return;

      final featureMap = queriedFeature.queriedFeature.feature as Map<String, dynamic>;
      final geometry = featureMap['geometry'] as Map<String, dynamic>?;
      if (geometry == null) return;

      if (geometry['type'] == 'Polygon') {
        final coordinates = geometry['coordinates'] as List?;
        if (coordinates == null || coordinates.isEmpty) return;
        final coords = coordinates[0] as List;

        // Calcular centro del polígono
        double sumLat = 0, sumLng = 0;
        for (var coord in coords) {
          sumLng += (coord[0] as num).toDouble();
          sumLat += (coord[1] as num).toDouble();
        }
        final centerLat = sumLat / coords.length;
        final centerLng = sumLng / coords.length;

        // FLY TO con configuración cinematográfica
        await _mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(centerLng, centerLat)),
            zoom: 9.0,      // Zoom más cercano en 3D
            pitch: 60.0,    // Pitch alto para vista oblicua dramática
            bearing: 30.0,  // Rotación ligera para dinamismo
            padding: MbxEdgeInsets(
              top: 100,
              left: 50,
              bottom: 350,
              right: 50,
            ),
          ),
          MapAnimationOptions(
            duration: 2500,  // 2.5s: suave y cinematográfico
            startDelay: 0,
          ),
        );

        debugPrint('✈️ Volando a $deptId con vista 3D');
      }
    } catch (e) {
      debugPrint('Error en fly-to: $e');
    }
  }

  /// Reset de cámara a vista general de Perú
  Future<void> _resetCamera() async {
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(-75.2, -9.2)),
        zoom: 5.5,
        pitch: 45.0,    // Pitch moderado para overview 3D
        bearing: 0.0,
        padding: MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
      ),
      MapAnimationOptions(
        duration: 2000,
        startDelay: 0,
      ),
    );
  }

  /// Obtiene y muestra la ubicación actual del usuario
  Future<void> _getUserLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        setState(() => _currentLocation = location);

        // Volar MUY CERCA a la ubicación del usuario (como videojuego)
        await _mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(location.longitude, location.latitude)),
            zoom: 16.5,     // MUCHO más cerca (antes era 12.0)
            pitch: 65.0,    // Inclinación más dramática
            bearing: 0.0,
          ),
          MapAnimationOptions(
            duration: 2500,
            startDelay: 0,
          ),
        );

        // Agregar marcador de punto azul para la ubicación del usuario
        await _addUserLocationMarker(location);

        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  /// Agrega un marcador circular azul en la ubicación del usuario (estilo videojuego)
  Future<void> _addUserLocationMarker(ll.LatLng location) async {
    try {
      // Crear source para el marcador del usuario
      await _mapboxMap?.style.addSource(GeoJsonSource(
        id: 'user_location_source',
        data: '''
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [${location.longitude}, ${location.latitude}]
          }
        }
        ''',
      ));

      // Capa de círculo exterior (pulso)
      await _mapboxMap?.style.addLayer(CircleLayer(
        id: 'user_location_outer',
        sourceId: 'user_location_source',
        circleRadius: 20.0,
        circleColor: 0xFF3B82F6, // Azul
        circleOpacity: 0.2,
        circleBlur: 0.5,
      ));

      // Capa de círculo interior (punto sólido)
      await _mapboxMap?.style.addLayer(CircleLayer(
        id: 'user_location_inner',
        sourceId: 'user_location_source',
        circleRadius: 8.0,
        circleColor: 0xFF3B82F6, // Azul
        circleOpacity: 1.0,
        circleStrokeWidth: 3.0,
        circleStrokeColor: 0xFFFFFFFF, // Borde blanco
      ));

      debugPrint('📍 Marcador de ubicación agregado');
    } catch (e) {
      // El source/layer ya existe, remover y recrear
      try {
        await _mapboxMap?.style.removeStyleLayer('user_location_inner');
        await _mapboxMap?.style.removeStyleLayer('user_location_outer');
        await _mapboxMap?.style.removeStyleSource('user_location_source');

        // Recrear con nueva posición
        await _addUserLocationMarker(location);
      } catch (updateError) {
        debugPrint('Error actualizando marcador: $updateError');
      }
    }
  }

  /// Muestra checklist de atracciones turísticas del departamento
  void _showDepartmentInfo(String deptId, String deptName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TouristAttractionsSheet(
        departmentId: deptId,
        departmentName: deptName,
        userLocation: _currentLocation,
        onNavigateTo: _navigateToPlace,
      ),
    );
  }

  /// Navega a un lugar específico y traza la ruta
  Future<void> _navigateToPlace(ll.LatLng destination, String placeName) async {
    // Cerrar el BottomSheet
    Navigator.pop(context);

    // MODO DEMO: Dibujar ruta directa sin Google API
    // Esto siempre funciona para que veas la línea azul
    debugPrint('🎯 Navegando a $placeName: ${destination.latitude}, ${destination.longitude}');

    if (_currentLocation == null) {
      // Mostrar mensaje
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Activa tu ubicación para ver la ruta completa'),
            backgroundColor: Color(0xFFF59E0B),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Volar al lugar
      await _flyToLocation(destination, placeName);
      return;
    }

    // Mostrar indicador
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Trazando ruta a $placeName...')),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF3B82F6),
        ),
      );
    }

    // RUTA DIRECTA (línea recta entre origen y destino)
    // Más adelante integraremos Google Directions API
    await _drawStraightRoute(_currentLocation!, destination, placeName);

    // Mensaje de éxito
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final distance = _calculateDistance(_currentLocation!, destination);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Ruta trazada a $placeName (${distance.toStringAsFixed(0)} km aprox)',
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    debugPrint('✅ Ruta dibujada correctamente');
  }

  /// Calcula distancia aproximada entre dos puntos (en km)
  double _calculateDistance(ll.LatLng from, ll.LatLng to) {
    const double earthRadius = 6371; // km

    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLat = (to.latitude - from.latitude) * math.pi / 180;
    final dLng = (to.longitude - from.longitude) * math.pi / 180;

    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  /// Dibuja una ruta directa (línea recta) entre origen y destino
  Future<void> _drawStraightRoute(ll.LatLng origin, ll.LatLng destination, String placeName) async {
    try {
      debugPrint('📍 ========================================');
      debugPrint('📍 INICIANDO DIBUJO DE RUTA');
      debugPrint('📍 Origen: ${origin.latitude}, ${origin.longitude}');
      debugPrint('📍 Destino: ${destination.latitude}, ${destination.longitude}');
      debugPrint('📍 Lugar: $placeName');
      debugPrint('📍 ========================================');

      // Remover capas anteriores
      try {
        await _mapboxMap?.style.removeStyleLayer('route_layer_outline');
        await _mapboxMap?.style.removeStyleLayer('route_layer');
        await _mapboxMap?.style.removeStyleSource('route_source');
        debugPrint('🗑️ Capas anteriores removidas');
      } catch (e) {
        debugPrint('ℹ️ No había capas anteriores: $e');
      }

      // Esperar un momento para asegurar que se removieron
      await Future.delayed(const Duration(milliseconds: 100));

      // Crear coordenadas de la línea (origen -> destino)
      final coordinates = [
        [origin.longitude, origin.latitude],
        [destination.longitude, destination.latitude],
      ];

      debugPrint('🎨 Coordenadas: ${coordinates[0]} -> ${coordinates[1]}');

      // Crear GeoJSON source
      final geoJsonData = {
        "type": "Feature",
        "geometry": {
          "type": "LineString",
          "coordinates": coordinates,
        },
        "properties": {
          "name": "Ruta a $placeName",
        }
      };

      debugPrint('📝 GeoJSON: $geoJsonData');

      // Agregar source
      await _mapboxMap?.style.addSource(GeoJsonSource(
        id: 'route_source',
        data: '''
        {
          "type": "Feature",
          "geometry": {
            "type": "LineString",
            "coordinates": [[${coordinates[0][0]}, ${coordinates[0][1]}], [${coordinates[1][0]}, ${coordinates[1][1]}]]
          },
          "properties": {
            "name": "Ruta a $placeName"
          }
        }
        ''',
      ));

      debugPrint('✅ Source "route_source" creado exitosamente');

      // Esperar para asegurar que el source está listo
      await Future.delayed(const Duration(milliseconds: 100));

      // PRIMERA CAPA: Outline (borde negro) para contraste
      await _mapboxMap?.style.addLayer(LineLayer(
        id: 'route_layer_outline',
        sourceId: 'route_source',
        lineColor: 0xFF000000, // Negro
        lineWidth: 14.0, // Más grueso que la línea principal
        lineOpacity: 0.5,
      ));

      debugPrint('✅ Layer outline creado');

      // SEGUNDA CAPA: Línea principal (amarillo brillante)
      await _mapboxMap?.style.addLayer(LineLayer(
        id: 'route_layer',
        sourceId: 'route_source',
        lineColor: 0xFFFFFF00, // AMARILLO BRILLANTE (más visible que rojo)
        lineWidth: 8.0,
        lineOpacity: 1.0,
        lineBlur: 0.0, // Sin blur para máxima visibilidad
      ));

      debugPrint('✅ Layer principal creado (AMARILLO, 8px)');

      // Agregar marcador en destino
      await _addDestinationMarker(destination, placeName);

      // Ajustar cámara para mostrar toda la ruta CON PADDING
      final minLat = origin.latitude < destination.latitude ? origin.latitude : destination.latitude;
      final maxLat = origin.latitude > destination.latitude ? origin.latitude : destination.latitude;
      final minLng = origin.longitude < destination.longitude ? origin.longitude : destination.longitude;
      final maxLng = origin.longitude > destination.longitude ? origin.longitude : destination.longitude;

      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;

      // Calcular zoom basado en la distancia
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

      double zoom = 10.0;
      if (maxDiff > 10) {
        zoom = 5.0;
      } else if (maxDiff > 5) {
        zoom = 6.5;
      } else if (maxDiff > 2) {
        zoom = 7.5;
      } else if (maxDiff > 1) {
        zoom = 8.5;
      } else if (maxDiff > 0.5) {
        zoom = 9.5;
      }

      debugPrint('📸 Bounds: lat[$minLat, $maxLat] lng[$minLng, $maxLng]');
      debugPrint('📸 Centro: ($centerLat, $centerLng)');
      debugPrint('📸 Zoom calculado: $zoom (diff: $maxDiff)');

      // Esperar un momento antes de mover la cámara
      await Future.delayed(const Duration(milliseconds: 200));

      // Volar a la ruta con pitch BAJO para ver la línea desde arriba
      await _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(centerLng, centerLat)),
          zoom: zoom,
          pitch: 30.0, // PITCH BAJO para ver la línea claramente
          bearing: 0.0,
          padding: MbxEdgeInsets(top: 150, left: 80, bottom: 400, right: 80),
        ),
        MapAnimationOptions(
          duration: 3000, // Animación más lenta para ver el proceso
          startDelay: 0,
        ),
      );

      debugPrint('✅ ¡RUTA COMPLETA DIBUJADA!');
      debugPrint('📍 ========================================');

      // Mostrar BottomSheet con información de la ruta
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showRouteInfoSheet(origin, destination, placeName);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR dibujando ruta: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Muestra BottomSheet con información detallada de la ruta
  void _showRouteInfoSheet(ll.LatLng origin, ll.LatLng destination, String placeName) {
    final distance = _calculateDistance(origin, destination);
    final estimatedHours = distance / 80; // Asumiendo 80 km/h promedio

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(bottom: 20),
            ),

            // Header con ícono
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.route,
                    color: Color(0xFF10B981),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ruta Trazada',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'a $placeName',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Info cards
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.straighten,
                    label: 'Distancia',
                    value: '${distance.toStringAsFixed(0)} km',
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.access_time,
                    label: 'Tiempo est.',
                    value: '${estimatedHours.toStringAsFixed(1)}h',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Itinerario simplificado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Itinerario Simplificado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildItineraryStep(
                    number: '1',
                    text: 'Partida desde tu ubicación',
                    isFirst: true,
                  ),
                  _buildItineraryStep(
                    number: '2',
                    text: 'Ruta directa por carretera principal',
                  ),
                  _buildItineraryStep(
                    number: '3',
                    text: 'Llegada a $placeName',
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Nota
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF57C0FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF57C0FF).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF57C0FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta es una ruta directa estimada. Usa Google Maps para navegación detallada.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botón de cerrar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryStep({
    required String number,
    required String text,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isLast
                      ? const Color(0xFF10B981)
                      : const Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 30,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Vuela a una ubicación específica
  Future<void> _flyToLocation(ll.LatLng location, String name) async {
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(location.longitude, location.latitude)),
        zoom: 14.0,
        pitch: 60.0,
        bearing: 30.0,
      ),
      MapAnimationOptions(
        duration: 2500,
        startDelay: 0,
      ),
    );

    // Agregar marcador
    await _addDestinationMarker(location, name);
  }

  /// Agrega un marcador de destino
  Future<void> _addDestinationMarker(ll.LatLng location, String name) async {
    try {
      const sourceId = 'destination_marker';
      const layerId = 'destination_marker_layer';

      // Remover marcador anterior si existe
      try {
        await _mapboxMap?.style.removeStyleLayer(layerId);
        await _mapboxMap?.style.removeStyleSource(sourceId);
      } catch (e) {
        // No existe
      }

      // Crear source para el marcador
      await _mapboxMap?.style.addSource(GeoJsonSource(
        id: sourceId,
        data: '''
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [${location.longitude}, ${location.latitude}]
          },
          "properties": {
            "name": "$name"
          }
        }
        ''',
      ));

      // Capa de círculo (marcador verde brillante para destino)
      await _mapboxMap?.style.addLayer(CircleLayer(
        id: layerId,
        sourceId: sourceId,
        circleRadius: 14.0,
        circleColor: 0xFF10B981, // Verde brillante
        circleOpacity: 1.0,
        circleStrokeWidth: 4.0,
        circleStrokeColor: 0xFFFFFFFF, // Borde blanco
      ));

      debugPrint('📍 Marcador de destino agregado: $name');
    } catch (e) {
      debugPrint('Error agregando marcador de destino: $e');
    }
  }

  /// Maneja selección de lugar desde el buscador
  void _onPlaceSelected(PlaceResult place) {
    // Agregar marcador a la lista
    setState(() {
      _searchMarkers.add(place);
    });

    // Volar al lugar seleccionado
    _flyToPlace(place);

    HapticFeedback.mediumImpact();
  }

  /// Vuela a un lugar seleccionado
  Future<void> _flyToPlace(PlaceResult place) async {
    // Agregar marcador del lugar
    await _addPlaceMarker(place);

    // Volar al lugar con zoom cercano
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(place.location.longitude, place.location.latitude)),
        zoom: 15.5,  // Muy cerca para ver detalles
        pitch: 60.0,
        bearing: 30.0,
      ),
      MapAnimationOptions(
        duration: 2500,
        startDelay: 0,
      ),
    );
  }

  /// Agrega un marcador rojo para un lugar buscado
  Future<void> _addPlaceMarker(PlaceResult place) async {
    try {
      final sourceId = 'place_marker_${place.placeId}';
      final layerId = 'place_marker_layer_${place.placeId}';

      // Crear source para el marcador
      await _mapboxMap?.style.addSource(GeoJsonSource(
        id: sourceId,
        data: '''
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [${place.location.longitude}, ${place.location.latitude}]
          },
          "properties": {
            "name": "${place.name}"
          }
        }
        ''',
      ));

      // Capa de círculo (marcador rojo brillante)
      await _mapboxMap?.style.addLayer(CircleLayer(
        id: layerId,
        sourceId: sourceId,
        circleRadius: 12.0,
        circleColor: 0xFFEF4444, // Rojo brillante
        circleOpacity: 1.0,
        circleStrokeWidth: 3.0,
        circleStrokeColor: 0xFFFFFFFF, // Borde blanco
      ));

      debugPrint('📍 Marcador agregado para: ${place.name}');
    } catch (e) {
      debugPrint('Error agregando marcador: $e');
    }
  }

  /// Handler de tap en el mapa
  Future<void> _onMapTap(MapContentGestureContext context) async {
    if (!widget.enableSelection) return;
    if (context.gestureState == GestureState.changed) return;
    if (_mapboxMap == null) return;

    List<QueriedRenderedFeature?> results = [];
    if (_styleReady) {
      try {
        results = await _mapboxMap!.queryRenderedFeatures(
          RenderedQueryGeometry.fromScreenCoordinate(context.touchPosition),
          RenderedQueryOptions(layerIds: [_markerLayerId, _labelLayerId]),
        );
      } catch (_) {
        results = [];
      }

      if (results.isEmpty) {
        try {
          results = await _mapboxMap!.queryRenderedFeatures(
            RenderedQueryGeometry.fromScreenCoordinate(context.touchPosition),
            RenderedQueryOptions(
              layerIds: [_fillExtrusionLayerId, _highlightLayerId],
            ),
          );
        } catch (_) {
          results = [];
        }
      }
    }

    String? deptId;

    if (results.isNotEmpty) {
      final queriedFeature = results.first?.queriedFeature;
      if (queriedFeature != null) {
        final feature = queriedFeature.feature;
        final props = feature['properties'] as Map?;
        deptId = props?['id']?.toString();
      }
    }

    if (deptId == null || deptId.isEmpty) {
      if (_departmentPolygons.isEmpty) {
        await _loadDepartmentPolygons();
      }
      final point = ll.LatLng(
        context.point.coordinates.lat.toDouble(),
        context.point.coordinates.lng.toDouble(),
      );
      final fallbackDept = _findDepartmentByPoint(point);
      if (fallbackDept == null) return;
      deptId = fallbackDept.id;
    }

    // Feedback háptico
    HapticFeedback.mediumImpact();

    // Notificar
    widget.onDeptSelected(deptId);

    // Volar al departamento
    try {
      await _updateHighlight(deptId);
    } catch (e) {
      debugPrint('Error resaltando departamento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Mapa 3D
        MapWidget(
          key: const ValueKey('vastoria_3d_map'),
          styleUri: MapboxStyles.STANDARD,

          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(-75.2, -9.2)),
            zoom: 5.5,
            pitch: 0.0,    // Inicia plano, anima a 55°
            bearing: 0.0,
          ),

          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
          onTapListener: _onMapTap,
        ),

        // Barra de búsqueda (top)
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: SearchBarWidget(
            onPlaceSelected: _onPlaceSelected,
          ),
        ),

        // Botones de acción (sobre el chat)
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            children: [
              // Botón de mi ubicación
              FloatingActionButton.small(
                onPressed: _getUserLocation,
                heroTag: 'location_btn',
                backgroundColor: Colors.white,
                child: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF57C0FF),
                        ),
                      )
                    : const Icon(Icons.my_location, color: Color(0xFF57C0FF)),
              ),
              const SizedBox(height: 12),
              // Botón para reset de cámara
              FloatingActionButton.small(
                onPressed: _resetCamera,
                heroTag: 'reset_btn',
                backgroundColor: Colors.white,
                child: const Icon(Icons.home, color: Color(0xFF57C0FF)),
              ),
            ],
          ),
        ),

        // Indicador de modo 3D (bottom-left)
        Positioned(
          bottom: 100,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.terrain, color: Color(0xFF57C0FF), size: 16),
                const SizedBox(width: 6),
                const Text(
                  '3D MODE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Indicador de ubicación actual (si existe)
        if (_currentLocation != null)
          Positioned(
            bottom: 140,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ===== CHAT FLOTANTE DE IA =====
        Positioned(
          bottom: 20,
          right: 16,
          child: VastoriaAIChatWidget(
            departmentContext: _selectedDeptId,
            attractionsContext: _searchMarkers.map((m) => m.name).toList(),
          ),
        ),
      ],
    );
  }
}

class _DeptPolygon {
  final String id;
  final String name;
  final List<ll.LatLng> points;

  const _DeptPolygon({
    required this.id,
    required this.name,
    required this.points,
  });
}

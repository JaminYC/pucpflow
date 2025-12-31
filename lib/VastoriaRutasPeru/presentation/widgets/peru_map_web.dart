import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Implementación web del mapa de Perú usando flutter_map
/// Muestra departamentos desde GeoJSON y permite interacción
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

class _PeruMapState extends State<PeruMap> {
  final MapController _mapController = MapController();

  List<DepartmentPolygon> _departments = [];
  String? _selectedDeptId;
  String? _hoveredDeptId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadGeoJson() async {
    try {
      final geojsonString = await rootBundle.loadString('assets/peru_departments.geojson');
      final geojson = jsonDecode(geojsonString);

      final features = geojson['features'] as List;
      final departments = <DepartmentPolygon>[];

      for (var feature in features) {
        final props = feature['properties'] as Map;
        final geometry = feature['geometry'] as Map;

        final id = props['id']?.toString() ?? '';
        final name = props['name']?.toString() ?? '';
        final region = props['region']?.toString() ?? '';

        if (id.isEmpty || geometry['type'] != 'Polygon') continue;

        final coordinates = geometry['coordinates'] as List;
        final points = <LatLng>[];

        // Convertir coordenadas [lng, lat] a LatLng
        // El GeoJSON puede venir en formato directo o anidado
        final coordArray = coordinates[0] is List && (coordinates[0] as List)[0] is List
            ? coordinates[0] as List  // Formato anidado [[[]]]
            : coordinates;             // Formato directo [[]]

        for (var coord in coordArray) {
          final lng = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          points.add(LatLng(lat, lng));
        }

        departments.add(DepartmentPolygon(
          id: id,
          name: name,
          region: region,
          points: points,
        ));
      }

      setState(() {
        _departments = departments;
        _isLoading = false;
      });
      debugPrint('✅ GeoJSON cargado: ${departments.length} departamentos');
    } catch (e) {
      debugPrint('❌ Error cargando GeoJSON: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getRegionColor(String region) {
    switch (region.toLowerCase()) {
      case 'costa':
        return const Color(0xFF3B82F6); // Azul brillante
      case 'sierra':
        return const Color(0xFF10B981); // Verde brillante
      case 'selva':
        return const Color(0xFFF59E0B); // Naranja brillante
      default:
        return const Color(0xFF8B5CF6); // Púrpura brillante
    }
  }

  void _handleTap(LatLng point) {
    if (!widget.enableSelection) return;
    // Buscar qué departamento contiene este punto
    for (var dept in _departments) {
      if (_isPointInPolygon(point, dept.points)) {
        setState(() => _selectedDeptId = dept.id);
        widget.onDeptSelected(dept.id);
        break;
      }
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    // Algoritmo ray-casting para detectar si un punto está dentro de un polígono
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

  bool _rayIntersectsSegment(LatLng point, LatLng a, LatLng b) {
    final px = point.longitude;
    final py = point.latitude;
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;

    if (ay > by) {
      final tempX = ax;
      final tempY = ay;
      final ax2 = bx;
      final ay2 = by;
      final bx2 = tempX;
      final by2 = tempY;
      return _rayIntersectsSegmentHelper(px, py, ax2, ay2, bx2, by2);
    }
    return _rayIntersectsSegmentHelper(px, py, ax, ay, bx, by);
  }

  bool _rayIntersectsSegmentHelper(double px, double py, double ax, double ay, double bx, double by) {
    if (py == ay || py == by) py += 0.00001;
    if (py < ay || py > by) return false;
    if (px >= ax && px >= bx) return false;
    if (px < ax && px < bx) return true;

    final m = (by - ay) / (bx - ax);
    final x = (py - ay) / m + ax;
    return px < x;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFF0A0E27),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF57C0FF)),
              SizedBox(height: 16),
              Text(
                'Cargando mapa del Perú...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_departments.isEmpty) {
      return Container(
        color: const Color(0xFF0A0E27),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              SizedBox(height: 16),
              Text(
                'No se pudieron cargar los departamentos',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Verifica la consola para más detalles',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(-9.2, -75.2), // Centro de Perú
        initialZoom: 5.5,
        minZoom: 5.0,
        maxZoom: 8.0,
        onTap: (tapPosition, point) => _handleTap(point),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Mapa base oscuro
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.vastoria.pucpflow',
        ),

        // Polígonos de departamentos
        PolygonLayer(
          polygons: _departments.map((dept) {
            final isSelected = dept.id == _selectedDeptId;
            final isHovered = dept.id == _hoveredDeptId;

            return Polygon(
              points: dept.points,
              color: isSelected
                  ? const Color(0xFF57C0FF).withOpacity(0.7)
                  : isHovered
                      ? _getRegionColor(dept.region).withOpacity(0.8)
                      : _getRegionColor(dept.region).withOpacity(0.6),
              borderColor: isSelected
                  ? const Color(0xFF57C0FF)
                  : Colors.white,
              borderStrokeWidth: isSelected ? 3.0 : 2.0,
            );
          }).toList(),
        ),

        // Marcadores con nombres de departamentos
        MarkerLayer(
          markers: _departments.map((dept) {
            // Calcular centroide simple (promedio de puntos)
            double sumLat = 0;
            double sumLng = 0;
            for (var point in dept.points) {
              sumLat += point.latitude;
              sumLng += point.longitude;
            }
            final centerLat = sumLat / dept.points.length;
            final centerLng = sumLng / dept.points.length;

            return Marker(
              width: 120,
              height: 30,
              point: LatLng(centerLat, centerLng),
              child: GestureDetector(
                onTap: () {
                  if (!widget.enableSelection) return;
                  setState(() => _selectedDeptId = dept.id);
                  widget.onDeptSelected(dept.id);
                },
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredDeptId = dept.id),
                  onExit: (_) => setState(() => _hoveredDeptId = null),
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: dept.id == _selectedDeptId
                          ? const Color(0xFF57C0FF).withOpacity(0.9)
                          : Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: dept.id == _selectedDeptId
                            ? Colors.white
                            : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      dept.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: dept.id == _selectedDeptId
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Modelo para representar un departamento como polígono
class DepartmentPolygon {
  final String id;
  final String name;
  final String region;
  final List<LatLng> points;

  DepartmentPolygon({
    required this.id,
    required this.name,
    required this.region,
    required this.points,
  });
}

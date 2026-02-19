import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

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
  static const _sourceId = 'peru_departments';
  static const _fillLayerId = 'peru_departments_fill';
  static const _lineLayerId = 'peru_departments_line';
  static const _highlightLayerId = 'peru_departments_highlight';
  static const _fallbackToken = '';

  MapboxMap? _mapboxMap;
  bool _styleReady = false;
  String? _selectedDeptId;

  @override
  void initState() {
    super.initState();
    const token = String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');
    final resolvedToken = token.isNotEmpty ? token : _fallbackToken;
    if (resolvedToken.isNotEmpty) {
      MapboxOptions.setAccessToken(resolvedToken);
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    final geojson = await rootBundle.loadString('assets/peru_departments.geojson');
    await _mapboxMap?.style.addSource(GeoJsonSource(id: _sourceId, data: geojson));

    await _mapboxMap?.style.addLayer(
      FillLayer(
        id: _fillLayerId,
        sourceId: _sourceId,
        fillColor: const Color(0xFF1C243A).value,
        fillOpacity: 0.7,
      ),
    );

    await _mapboxMap?.style.addLayer(
      LineLayer(
        id: _lineLayerId,
        sourceId: _sourceId,
        lineColor: const Color(0xFF47516B).value,
        lineWidth: 1.2,
      ),
    );

    await _mapboxMap?.style.addLayer(
      _highlightLayer(_selectedDeptId),
    );

    _styleReady = true;
  }

  FillLayer _highlightLayer(String? deptId) {
    return FillLayer(
      id: _highlightLayerId,
      sourceId: _sourceId,
      fillColor: const Color(0xFF57C0FF).value,
      fillOpacity: 0.6,
      filter: _buildFilter(deptId),
    );
  }

  List<Object> _buildFilter(String? deptId) {
    final id = deptId ?? '';
    return [
      '==',
      ['get', 'id'],
      id,
    ];
  }

  Future<void> _updateHighlight(String deptId) async {
    _selectedDeptId = deptId;
    if (!_styleReady || _mapboxMap == null) return;
    await _mapboxMap?.style.updateLayer(_highlightLayer(deptId));
  }

  Future<void> _onMapTap(MapContentGestureContext context) async {
    if (!widget.enableSelection) return;
    if (context.gestureState != GestureState.ended) return;
    if (_mapboxMap == null) return;

    final results = await _mapboxMap!.queryRenderedFeatures(
      RenderedQueryGeometry.fromScreenCoordinate(context.touchPosition),
      RenderedQueryOptions(layerIds: [_fillLayerId]),
    );

    if (results.isEmpty) return;
    final feature = results.first?.queriedFeature.feature;
    final props = feature?['properties'] as Map?;
    final deptId = props?['id']?.toString();
    if (deptId == null || deptId.isEmpty) return;

    await _updateHighlight(deptId);
    widget.onDeptSelected(deptId);
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey('peru_map'),
      styleUri: MapboxStyles.STANDARD,
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(-75.2, -9.2)),
        zoom: 4.4,
      ),
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: _onStyleLoaded,
      onTapListener: _onMapTap,
    );
  }
}

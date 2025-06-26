import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class MapaDiqueTiempoReal extends StatefulWidget {
  const MapaDiqueTiempoReal({super.key});

  @override
  State<MapaDiqueTiempoReal> createState() => _MapaDiqueTiempoRealState();
}

class _MapaDiqueTiempoRealState extends State<MapaDiqueTiempoReal> {
  final TransformationController _controller = TransformationController();
  StreamSubscription<Position>? _posSubscription;

  final List<Offset> puntos = [];
  String zona = "";
  double x = 0, y = 0;

  @override
  void initState() {
    super.initState();
    _iniciarStreamUbicacion();
  }

  void _iniciarStreamUbicacion() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _posSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((pos) {
      final resultado = obtenerZonaYProgresiva(lat: pos.latitude, lon: pos.longitude);
      setState(() {
        x = resultado['x'];
        y = resultado['y'];
        zona = resultado['zona'];
        puntos.add(_convertirAMapa(x, y));
      });
    });
  }

  Offset _convertirAMapa(double x, double y) {
    const double origenXPx = 409.0;
    const double origenYPx = -3.0;
    const double factorX = 0.1811375;
    const double factorY = 0.1821771671;

    double xPx = origenXPx - x * factorX;
    double yPx = origenYPx + y * factorY;
    return Offset(xPx, yPx);
  }

  @override
  void dispose() {
    _posSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double imagenWidth = 6000.0;
    const double imagenHeight = 4000.0;

    return Scaffold(
      appBar: AppBar(title: const Text("Mapa Tiempo Real")),
      body: Column(
        children: [
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Zona: $zona", style: const TextStyle(color: Colors.white)),
                Text("x: ${x.toStringAsFixed(1)}", style: const TextStyle(color: Colors.white)),
                Text("y: ${y.toStringAsFixed(1)}", style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              transformationController: _controller,
              minScale: 0.2,
              maxScale: 8.0,
              boundaryMargin: const EdgeInsets.all(300),
              child: Stack(
                children: [
                  SizedBox(
                    width: imagenWidth,
                    height: imagenHeight,
                    child: Image.asset(
                      'assets/Talud_Linga.jpg',
                      fit: BoxFit.contain,
                      alignment: Alignment.topLeft,
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: RutaPainter(puntos),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RutaPainter extends CustomPainter {
  final List<Offset> puntos;
  RutaPainter(this.puntos);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < puntos.length - 1; i++) {
      canvas.drawLine(puntos[i], puntos[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

Map<String, dynamic> obtenerZonaYProgresiva({required double lat, required double lon}) {
  const double R = 6371008.8;
  const double lat0 = -16.61792680;
  const double lon0 = -71.59281259;
  const double latY = -16.62174618;
  const double lonY = -71.60130636;
  const double anguloRotacion = 0.14;

  List<double> geoAMetros(double lat1, double lon1, double lat2, double lon2) {
    double dLat = _toRad(lat2 - lat1);
    double dLon = _toRad(lon2 - lon1);
    double latProm = _toRad((lat1 + lat2) / 2);
    double dx = R * dLon * cos(latProm);
    double dy = R * dLat;
    return [dx, dy];
  }

  List<double> normalizar(List<double> v) {
    double norm = sqrt(v[0] * v[0] + v[1] * v[1]);
    return [v[0] / norm, v[1] / norm];
  }

  List<double> rotarVector(List<double> v, double angDeg) {
    double rad = _toRad(angDeg);
    return [
      v[0] * cos(rad) - v[1] * sin(rad),
      v[0] * sin(rad) + v[1] * cos(rad),
    ];
  }

  double _dot(List<double> a, List<double> b) => a[0] * b[0] + a[1] * b[1];

  final ejeY = geoAMetros(lat0, lon0, latY, lonY);
  final ejeYUnit = normalizar(ejeY);
  final ejeYRotado = rotarVector(ejeYUnit, anguloRotacion);
  final ejeXRotado = [ejeYRotado[1], -ejeYRotado[0]];
  final delta = geoAMetros(lat0, lon0, lat, lon);
  final x = _dot(delta, ejeXRotado);
  final y = _dot(delta, ejeYRotado);

  String zona;
  if (x < 0 || x > 2600) {
    zona = "Fuera del dique";
  } else if (x < 728.17) {
    zona = "Zona 4";
  } else if (x < 959.9) {
    zona = "Zona 3";
  } else if (x < 1191.73) {
    zona = "Zona 2";
  } else if (x < 1423.57) {
    zona = "Zona 1";
  } else if (x < 1689) {
    zona = "Zona 0";
  } else {
    zona = "Zona -1";
  }

  return {
    'zona': zona,
    'x': x,
    'y': y,
  };
}

double _toRad(double deg) => deg * pi / 180;


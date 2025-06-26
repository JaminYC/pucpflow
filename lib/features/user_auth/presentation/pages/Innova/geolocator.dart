import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/mapa_dique.dart';

Future<void> obtenerYProcesarUbicacion(BuildContext context) async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permiso de ubicación denegado")),
        );
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    double lat = position.latitude;
    double lon = position.longitude;

    final resultado = obtenerZonaYProgresiva(lat: lat, lon: lon);
    final zona = resultado['zona'];
    final mensaje = resultado['mensaje'];
    final double x = resultado['x'];
    final double y = resultado['y'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapaDique(
          x: x,
          y: y,
          zona: zona,
          progresiva: "${y.toStringAsFixed(2)} m",
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: ${e.toString()}")),
    );
  }
}

Map<String, dynamic> obtenerZonaYProgresiva({
  required double lat,
  required double lon,
}) {
  try {
    // Parámetros calibrados
    const double R = 6371008.8;
    const double lat0 = -16.61792680;
    const double lon0 = -71.59281259;
    const double latY = -16.62174618;
    const double lonY = -71.60130636;
    const double anguloRotacion = 0.14;

    // Función auxiliar
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

    double _dot(List<double> a, List<double> b) {
      return a[0] * b[0] + a[1] * b[1];
    }

    // Base cartesiana
    final ejeY = geoAMetros(lat0, lon0, latY, lonY);
    final ejeYUnit = normalizar(ejeY);
    final ejeYRotado = rotarVector(ejeYUnit, anguloRotacion);
    final ejeXRotado = [ejeYRotado[1], -ejeYRotado[0]];

    // Delta entre origen y punto
    final delta = geoAMetros(lat0, lon0, lat, lon);
    final x = _dot(delta, ejeXRotado);
    final y = _dot(delta, ejeYRotado);

    // Zona
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

    // Mensaje
    String mensaje = zona == "Fuera del dique"
        ? "Fuera del dique"
        : "Progresiva en X: ${x.toStringAsFixed(2)} m | Progresiva en Y: ${y.toStringAsFixed(2)} ";

    return {
      'zona': zona,
      'mensaje': mensaje,
      'x': x,
      'y': y,
    };
  } catch (e) {
    return {
      'zona': 'Error',
      'mensaje': 'Error inesperado: ${e.toString()}',
      'x': 0.0,
      'y': 0.0,
    };
  }
}

double _toRad(double deg) => deg * pi / 180;

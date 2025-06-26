import 'dart:math';
import 'package:flutter/material.dart';

class MapaDique extends StatefulWidget {
  final double x;
  final double y;
  final String zona;
  final String progresiva;
  final double? x2;
  final double? y2;

  const MapaDique({
    super.key,
    required this.x,
    required this.y,
    required this.zona,
    required this.progresiva,
    this.x2,
    this.y2,
  });

  @override
  State<MapaDique> createState() => _MapaDiqueState();
}

class _MapaDiqueState extends State<MapaDique> {
  final TransformationController _controller = TransformationController();

  late double xPx;
  late double yPx;
  double? x2Px;
  double? y2Px;
  String? pendientePorcentaje;

  @override
  void initState() {
    super.initState();

    // 📌 FACTORES de conversión
    const double factorX = 0.1811375;
    const double factorY = 0.1821771671;

    // 📌 Punto origen cartesiano calibrado (0,0) en la imagen
    const double origenXPx = 409.0;
    const double origenYPx = -3.0;

    // 📌 Conversión de metros a pixeles (X invertido, Y hacia abajo)
    xPx = origenXPx - widget.x * factorX;
    yPx = origenYPx + widget.y * factorY;

    if (widget.x2 != null && widget.y2 != null) {
      x2Px = origenXPx - widget.x2! * factorX;
      y2Px = origenYPx + widget.y2! * factorY;

      final deltaX = widget.x2! - widget.x;
      final deltaY = widget.y2! - widget.y;

      if (deltaX != 0) {
        final pendiente = (deltaY / deltaX) * 100;
        pendientePorcentaje = "${pendiente.toStringAsFixed(2)}%";
      } else {
        pendientePorcentaje = "Infinita (vertical)";
      }
    }

    // Zoom inicial centrado
    const double zoom = 2.0;
    _controller.value = Matrix4.identity()
      ..translate(-xPx * zoom + 200, -yPx * zoom + 300)
      ..scale(zoom);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double imagenWidth = 6000.0;
    const double imagenHeight = 4000.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Mapa del Dique"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 12,
              runSpacing: 10,
              children: [
                _infoBox("Zona", widget.zona),
                // _infoBox("Progresiva", widget.progresiva),
                _infoBox("Progresiva x", widget.x.toStringAsFixed(2)),
                _infoBox("Progresiva y", widget.y.toStringAsFixed(2)),
                // _infoBox("xPx", xPx.toStringAsFixed(1)),
                // _infoBox("yPx", yPx.toStringAsFixed(1)),
                if (pendientePorcentaje != null)
                  _infoBox("Pendiente", pendientePorcentaje!),
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
                  // Línea entre puntos
                  if (x2Px != null && y2Px != null)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: LinePainter(
                          start: Offset(xPx, yPx),
                          end: Offset(x2Px!, y2Px!),
                        ),
                      ),
                    ),
                  // Punto origen visual
                  const Positioned(
                    left: 409,
                    top: -3,
                    child: Column(
                      children: [
                        Icon(Icons.circle, size: 6, color: Colors.white),
                        SizedBox(height: 4),
                        Text(
                          'ORIGEN (0,0)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            backgroundColor: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Punto rojo fijo (prueba)
                  // const Positioned(
                  //   left: 60,
                  //   top: 90,
                  //   child: Icon(Icons.circle, color: Colors.red, size: 5),
                  // ),
                  // Punto inicial (verde)
                  Positioned(
                    left: xPx,
                    top: yPx,
                    child: _marcador(color: Colors.green),
                  ),
                  // Punto final (azul)
                  if (x2Px != null && y2Px != null)
                    Positioned(
                      left: x2Px!,
                      top: y2Px!,
                      child: _marcador(color: Colors.blueAccent),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _marcador({required Color color}) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color.fromARGB(255, 255, 0, 0), width: 0.5),
      ),
    );
  }

  Widget _infoBox(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: Color.fromARGB(180, 255, 255, 255), fontSize: 13),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class LinePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  LinePainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellowAccent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

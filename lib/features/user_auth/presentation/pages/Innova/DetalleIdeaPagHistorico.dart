import 'package:flutter/material.dart';

class DetalleIdeaPagHistorico extends StatelessWidget {
  final String nombreProyecto;
  final String resumenProblema;
  final List<String> causas;
  final String resumenSolucion;
  final List<String> responsables;

  const DetalleIdeaPagHistorico({
    super.key,
    required this.nombreProyecto,
    required this.resumenProblema,
    required this.causas,
    required this.resumenSolucion,
    required this.responsables,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Idea innovadora", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E1E), Colors.black],
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.6),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  nombreProyecto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildSeccion("Resumen del problema", resumenProblema),
                const SizedBox(height: 16),
                _buildTarjetas("Causa", causas),
                const SizedBox(height: 32),
                _buildSeccion("Resumen de la solución", resumenSolucion),
                const SizedBox(height: 16),
                _buildTarjetas("Responsable", responsables),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo, String contenido) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFB7894A),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          contenido,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  Widget _buildTarjetas(String titulo, List<String> elementos) {
    if (elementos.isEmpty) return const SizedBox();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: elementos.asMap().entries.map((entry) {
        final i = entry.key + 1;
        final texto = entry.value;
        return Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFB7894A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                "$titulo $i",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

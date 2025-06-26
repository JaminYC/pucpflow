// archivo: AnalisisIdeaPage.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/CrearProyectoDesdeIdeaPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/ReforzarIdeaPage.dart';

class AnalisisIdeaPage extends StatefulWidget {
  final String ideaId;

  const AnalisisIdeaPage({super.key, required this.ideaId});

  @override
  State<AnalisisIdeaPage> createState() => _AnalisisIdeaPageState();
}

class _AnalisisIdeaPageState extends State<AnalisisIdeaPage> {
  Map<String, dynamic>? resultadoIA;

  @override
  void initState() {
    super.initState();
    _recargarResultadoIA();
  }

  Future<void> _recargarResultadoIA() async {
    final doc = await FirebaseFirestore.instance.collection('ideas').doc(widget.ideaId).get();
    if (doc.exists) {
      setState(() => resultadoIA = doc.data()!['resultadoIA'] ?? {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (resultadoIA == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final resumenProblema = resultadoIA!["resumenProblema"] ?? "-";
    final resumenSolucion = resultadoIA!["resumenSolucion"] ?? "-";
    final evaluacion = resultadoIA!["evaluacion"] ?? "-";
    final madurez = resultadoIA!["madurez"]?.toString() ?? "—";
    final esfuerzo = resultadoIA!["esfuerzo"] ?? "—";
    final campoMejora = resultadoIA!["campo"] ?? "—";
    final riesgos = (resultadoIA!["riesgosDetectados"] is List)
        ? (resultadoIA!["riesgosDetectados"] as List).join('\n• ')
        : resultadoIA!["riesgosDetectados"]?.toString() ?? "-";

    final acciones = (resultadoIA!["accionesRecomendadas"] is List)
        ? (resultadoIA!["accionesRecomendadas"] as List).join('\n• ')
        : resultadoIA!["accionesRecomendadas"]?.toString() ?? "-";
        
    final tituloIdea = resultadoIA!["titulo"] ?? "Sin título";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Evaluación de la idea", style: TextStyle(color: Colors.amber)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.amber),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitulo(),

            const SizedBox(height: 20),

            _buildSeccion("📝 Título", [
              Text(tituloIdea, style: const TextStyle(color: Colors.white, fontSize: 18)),
            ]), 

            _buildSeccion("Evaluación", [
              Text(resumenProblema, style: _texto()),
              Text(resumenSolucion, style: _texto()),
              Text(evaluacion, style: _texto()),
              const SizedBox(height: 10),
              _buildEtiqueta("Madurez", madurez),
              _buildEtiqueta("Esfuerzo para Implementación", esfuerzo),
              _buildEtiqueta("Campo de mejora", campoMejora),
            ]),
            _buildSeccion("Riesgos detectados", [
              Text(riesgos, style: _texto()),
            ]),
            _buildSeccion("Acciones Recomendadas", [
              Text(acciones, style: _texto()),
              const SizedBox(height: 16),
              _buildBotonesInferiores(context),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTitulo() {
    return Column(
      children: const [
        Text(
          "Idea Innovadora",
          style: TextStyle(
            fontSize: 28,
            color: Colors.amber,
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
          ),
        ),
        Divider(color: Colors.amberAccent, thickness: 1),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> contenido) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...contenido,
        ],
      ),
    );
  }

  Widget _buildEtiqueta(String titulo, String valor) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text("$titulo: ", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          Text(valor, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildBotonesInferiores(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _botonAccion("Reforzar Idea", Icons.edit, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReforzarIdeaPage(
                    ideaId: widget.ideaId,
                    onRefuerzoCompleto: _recargarResultadoIA,
                  ),
                ),
              );
            }),

            _botonAccion("Guardar Idea", Icons.save, () async {
              try {
                await FirebaseFirestore.instance.collection('ideas').doc(widget.ideaId).update({
                  'titulo': resultadoIA!["titulo"] ?? '',
                  'resultadoIA': resultadoIA,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Idea guardada correctamente")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Error al guardar: $e")),
                );
              }
            }
          ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CrearProyectoDesdeIdeaPage(
                    ideaId: widget.ideaId,
                    resumenProblema: resultadoIA!["resumenProblema"] ?? '',
                    resumenSolucion: resultadoIA!["resumenSolucion"] ?? '',
                    comentarioFinal: resultadoIA!["comentarioFinal"] ?? '',
                    tituloz: resultadoIA!["titulo"] ?? '',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward, color: Colors.black),
            label: const Text("Siguiente Etapa", style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _botonAccion(String texto, IconData icono, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icono, color: Colors.black),
      label: Text(texto, style: const TextStyle(color: Colors.black)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  TextStyle _texto() => const TextStyle(color: Colors.white70, fontSize: 14);
}

// archivo: ReforzarIdeaPage.dart

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ReforzarIdeaPage extends StatefulWidget {
  final String ideaId;
  final VoidCallback? onRefuerzoCompleto;

  const ReforzarIdeaPage({super.key, required this.ideaId, this.onRefuerzoCompleto});

  @override
  State<ReforzarIdeaPage> createState() => _ReforzarIdeaPageState();
}

class _ReforzarIdeaPageState extends State<ReforzarIdeaPage> {
  final List<String> _preguntas = [
    "¿Cómo mejorarías la eficiencia del proceso?",
    "¿Qué recursos adicionales se necesitan?",
    "¿Qué otras soluciones considerarías?"
  ];
  final List<TextEditingController> _respuestas = [];
  final TextEditingController _comentariosAdicionales = TextEditingController();

  @override
  void initState() {
    super.initState();
    _respuestas.addAll(_preguntas.map((_) => TextEditingController()));
  }

  @override
  void dispose() {
    for (var c in _respuestas) {
      c.dispose();
    }
    _comentariosAdicionales.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Reforzando la idea", style: TextStyle(color: Colors.amber)),
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
            const Text(
              "Idea Innovadora",
              style: TextStyle(
                fontSize: 28,
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontFamily: 'Georgia',
              ),
            ),
            const Divider(color: Colors.amberAccent, thickness: 1),
            const SizedBox(height: 20),
            _buildSeccion("Preguntas de reforzamiento", [
              for (int i = 0; i < _preguntas.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _respuestas[i],
                    maxLines: null,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoracionCampo(_preguntas[i]),
                  ),
                ),
            ]),
            _buildSeccion("Comentarios Adicionales", [
              TextFormField(
                controller: _comentariosAdicionales,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: _decoracionCampo("Escribe tus comentarios..."),
              )
            ]),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _enviarReevaluacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Reevaluar idea", style: TextStyle(color: Colors.black)),
              ),
            )
          ],
        ),
      ),
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
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...contenido,
        ],
      ),
    );
  }

  InputDecoration _decoracionCampo(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.amberAccent),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.amber),
      ),
    );
  }



  void _enviarReevaluacion() async {
    final respuestas = <String, String>{};
    for (int i = 0; i < _preguntas.length; i++) {
      respuestas[_preguntas[i]] = _respuestas[i].text;
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('reforzarIdea');
      final result = await callable.call({
        'ideaId': widget.ideaId,
        'respuestas': respuestas,
        'comentariosAdicionales': _comentariosAdicionales.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Idea reevaluada con IA.")),
      );

      if (widget.onRefuerzoCompleto != null) widget.onRefuerzoCompleto!();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al reforzar: $e")),
      );
    }
  }

} 

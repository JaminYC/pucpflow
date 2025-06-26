import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/CrearProyectoDesdeIdeaPage.dart';

class VerIdeasPage extends StatelessWidget {
  const VerIdeasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("📚 Ideas Guardadas", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/FondoCoheteNegro2.jpg', fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0.5)),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ideas')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Text("No hay ideas registradas.", style: TextStyle(color: Colors.white)),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Expanded(
                              flex: 4,
                              child: Text("📝 Título de la Idea",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text("🚀 Acción",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white54, thickness: 1.5),
                        const SizedBox(height: 8),

                        ...docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final titulo = data['resultadoIA']?['titulo'] ?? "(Sin título)";
                          final resumenProblema = data['resultadoIA']?['resumenProblema'] ?? '';
                          final resumenSolucion = data['resultadoIA']?['resumenSolucion'] ?? '';
                          final comentarioFinal = data['resultadoIA']?['evaluacion'] ?? '';
                          final estado = data['estado'] ?? 'pendiente';

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 16)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 1,
                                      child: (estado == 'analizada' || estado == 'validada')
                                          ? ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => CrearProyectoDesdeIdeaPage(
                                                      ideaId: doc.id,
                                                      resumenProblema: resumenProblema,
                                                      resumenSolucion: resumenSolucion,
                                                      comentarioFinal: comentarioFinal,
                                                      tituloz: titulo,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.rocket_launch),
                                              label: const Text("Crear"),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.lightBlue[700],
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10)),
                                              ),
                                            )
                                          : const Text("N/A", style: TextStyle(color: Colors.grey)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

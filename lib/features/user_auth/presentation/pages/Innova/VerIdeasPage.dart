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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Expanded(flex: 3, child: Text("🧠 Problema", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Expanded(flex: 3, child: Text("💡 Solución", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text("📌 Estado", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text("🚀 Acción", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const Divider(color: Colors.white54, thickness: 1.5),
                    const SizedBox(height: 8),

                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final resumenProblema = data['resultadoIA']?['resumenProblema'] ?? "(Sin resumen)";
                      final resumenSolucion = data['resultadoIA']?['resumenSolucion'] ?? "(Sin solución)";
                      final estado = data['estado'] ?? 'pendiente';

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(resumenProblema, style: const TextStyle(color: Colors.white70)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Text(resumenSolucion, style: const TextStyle(color: Colors.white70)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: Text(estado, style: const TextStyle(color: Colors.white)),
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
                                              comentarioFinal: data['resultadoIA']?['evaluacion'] ?? 'Sin comentario',
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
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    )
                                  : const Text("N/A", style: TextStyle(color: Colors.grey)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );


            },
          ),
        ],
      ),
    );
  }
}

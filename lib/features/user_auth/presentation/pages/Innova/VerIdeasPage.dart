// 📄 VerIdeasPage.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VerIdeasPage extends StatelessWidget {
  const VerIdeasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📚 Ideas Guardadas"),
        backgroundColor: Colors.blue[900],
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            return const Center(child: Text("No hay ideas registradas."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final resumenProblema = data['resultadoIA']?['resumenProblema'] ?? "(Sin resumen)";
              final resumenSolucion = data['resultadoIA']?['resumenSolucion'] ?? "(Sin solución)";
              final estado = data['estado'] ?? 'pendiente';
              final iteracion = data['faseIteracion'];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['problema'] ?? 'Problema no especificado',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text("🧠 Problema: $resumenProblema"),
                      Text("💡 Solución: $resumenSolucion"),
                      Text("📌 Estado: $estado"),
                      if (iteracion != null) ...[
                        const SizedBox(height: 10),
                        const Text("🔄 Fase de Iteración", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("📊 Madurez: ${iteracion['madurez']}%"),
                        const SizedBox(height: 4),
                        const Text("❓ Preguntas IA:"),
                        ...List.from(iteracion['preguntasIterativas'] ?? []).map((q) => Text("• $q")),
                        const SizedBox(height: 4),
                        const Text("⚠️ Riesgos:"),
                        ...List.from(iteracion['riesgosDetectados'] ?? []).map((r) => Text("- $r")),
                        const SizedBox(height: 4),
                        const Text("✅ Acciones sugeridas:"),
                        ...List.from(iteracion['accionesRecomendadas'] ?? []).map((a) => Text("+ $a")),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

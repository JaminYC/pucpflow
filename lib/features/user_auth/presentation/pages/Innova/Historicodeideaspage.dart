import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/CrearProyectoDesdeIdeaPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/DetalleIdeaPagHistorico.dart';

class HistoricoDeIdeasPage extends StatefulWidget {
  const HistoricoDeIdeasPage({super.key});

  @override
  State<HistoricoDeIdeasPage> createState() => _HistoricoDeIdeasPageState();
}

class _HistoricoDeIdeasPageState extends State<HistoricoDeIdeasPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("📜 Histórico de Ideas", style: TextStyle(color: Color(0xFF6A4D1A))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF6A4D1A)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar ideas por título...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6A4D1A)),
                filled: true,
                fillColor: const Color(0xFFFFF3E0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Color(0xFF6A4D1A)),
              ),
              style: const TextStyle(color: Color(0xFF6A4D1A)),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ideas').snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final ideasFiltradas = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final titulo = data['titulo']?.toLowerCase() ?? '';
                  return titulo.contains(searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: ideasFiltradas.length,
                  itemBuilder: (context, index) {
                    final doc = ideasFiltradas[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final titulo = data['titulo'] ?? 'Idea sin título';
                    final estado = data['estado'] ?? 'pendiente';

                    return GestureDetector(
  onTap: () {
    final causasList = (data['causas'] is Iterable)
    ? List<String>.from(data['causas'])
    : (data['causas'] as String?)?.split(RegExp(r'[,\n]')).map((e) => e.trim()).toList() ?? [];

final responsablesList = (data['responsables'] is Iterable)
    ? List<String>.from(data['responsables'])
    : (data['responsables'] as String?)?.split(RegExp(r'[,\n]')).map((e) => e.trim()).toList() ?? [];

    final resumenProblema = data['resultadoIA']?['resumenProblema'] ?? 'No disponible';
    final resumenSolucion = data['resultadoIA']?['resumenSolucion'] ?? 'No disponible';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleIdeaPagHistorico(
          nombreProyecto: titulo,
          resumenProblema: resumenProblema,
          causas: causasList,
          resumenSolucion: resumenSolucion,
          responsables: responsablesList,
        ),
      ),
    );
  },
  child: Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        )
      ],
      border: Border.all(color: const Color(0xFFB7894A), width: 1.5),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFF6A4D1A),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: (estado == 'analizada' || estado == 'validada')
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CrearProyectoDesdeIdeaPage(
                        ideaId: doc.id,
                        resumenProblema: data['resultadoIA']?['resumenProblema'] ?? '',
                        resumenSolucion: data['resultadoIA']?['resumenSolucion'] ?? '',
                        comentarioFinal: data['resultadoIA']?['evaluacion'] ?? 'Sin comentario',
                        tituloz: titulo,
                      ),
                    ),
                  );
                }
              : null,
          icon: const Icon(Icons.rocket_launch, color: Colors.black),
          label: const Text("Crear Proyecto", style: TextStyle(color: Colors.black)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFCD78A),
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.black38,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    ),
  ),
);

                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

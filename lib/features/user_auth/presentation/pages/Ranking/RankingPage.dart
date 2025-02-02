import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Ranking Global'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('performance.global_score', descending: true) // ✅ Ordenado por global_score
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados.', style: TextStyle(color: Colors.white)));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final name = user['username'] ?? 'Usuario Anónimo';
              final score = user['performance']?['global_score'] ?? 0;
              final email = user['email'] ?? 'Sin email';

              return ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                  backgroundColor: Colors.amber,
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                subtitle: Text('Puntuación: $score\nEmail: $email',
                    style: const TextStyle(color: Colors.white70)),
                tileColor: index % 2 == 0 ? Colors.grey.shade800 : Colors.grey.shade900,
              );
            },
          );
        },
      ),
      backgroundColor: Colors.black,
    );
  }
}

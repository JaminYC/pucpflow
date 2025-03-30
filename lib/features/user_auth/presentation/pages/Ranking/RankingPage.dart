import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _videoController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset("assets/videoranking.mp4")
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🏆 Ranking Global',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 🎥 Fondo de video
          Positioned.fill(
            child: _videoController.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : Container(color: Colors.black),
          ),

          // 🧱 Capa semitransparente encima del video
          Container(color: Colors.black.withOpacity(0.1)),

          // 📊 Lista del ranking
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('puntosTotales', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay usuarios registrados.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final users = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 32),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data() as Map<String, dynamic>;
                  final name = user['full_name'] ?? user['username'] ?? user['email'] ?? 'Usuario Anónimo';
                  final score = user['puntosTotales'] ?? 0;
                  final email = user['email'] ?? '---';

                  // 🥇 Iconos especiales para los 3 primeros
                  Widget? leadingIcon;
                  if (index == 0) {
                    leadingIcon = const Icon(Icons.emoji_events, color: Colors.amber, size: 30);
                  } else if (index == 1) {
                    leadingIcon = const Icon(Icons.emoji_events, color: Colors.grey, size: 28);
                  } else if (index == 2) {
                    leadingIcon = const Icon(Icons.emoji_events, color: Colors.brown, size: 28);
                  } else {
                    leadingIcon = CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.black)),
                    );
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.black.withOpacity(0.1),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: index == 0
                            ? Colors.amber
                            : index == 1
                                ? Colors.grey
                                : index == 2
                                    ? Colors.brown
                                    : Colors.white12,
                        width: 1.2,
                      ),
                    ),
                    child: ListTile(
                      leading: leadingIcon,
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      subtitle: Text(
                        score == 0
                            ? "Aún sin puntaje\n$email"
                            : "Puntuación: $score\n$email",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

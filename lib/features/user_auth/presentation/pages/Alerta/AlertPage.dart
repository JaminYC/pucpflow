import 'package:flutter/material.dart';

class AlertPage extends StatelessWidget {
  const AlertPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📰 Noticias y Oportunidades',style: TextStyle(
            color: Colors.white,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 4,
                offset: Offset(1, 1),
                color: Colors.black,
              ),
            ],
          ),),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "✨ Últimas novedades",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 🧱 Tarjeta de noticia destacada
            _buildNewsCard(
              context,
              icon: Icons.emoji_events,
              color: Colors.amber,
              title: "Concurso de Innovación 2025",
              description: "Participa con tu equipo en el nuevo reto PUCP. Inscripciones abiertas hasta el 30 de abril.",
              linkText: "Inscribirse",
              linkAction: () {
                // Puedes agregar un Navigator o URL launcher aquí
              },
            ),

            const SizedBox(height: 12),
            _buildNewsCard(
              context,
              icon: Icons.public,
              color: Colors.blue,
              title: "Convocatoria NASA Space Apps",
              description: "Hackathon global para resolver desafíos espaciales. ¡Forma tu equipo y postula ya!",
              linkText: "Ver convocatoria",
              linkAction: () {},
            ),

            const SizedBox(height: 12),
            _buildNewsCard(
              context,
              icon: Icons.lightbulb_outline,
              color: Colors.greenAccent,
              title: "¿Tienes una idea?",
              description: "Súbela al muro de oportunidades. Deja que otros colaboren contigo.",
              linkText: "Publicar idea",
              linkAction: () {},
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),

            const Text(
              "📌 Muro de oportunidades compartidas",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _buildUserPost(
              user: "Jamin Yauri",
              message: "Estoy buscando 2 personas interesadas en participar en un hackathon de IA. Es este fin de semana. ¿Quién se apunta?",
            ),
            const SizedBox(height: 8),
            _buildUserPost(
              user: "María Flores",
              message: "Conseguí un fondo para proyectos educativos, ¿alguien con ideas para colaborar?",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String description,
      required String linkText,
      required VoidCallback linkAction}) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(description,
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: linkAction,
                    child: Text(
                      linkText,
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          decoration: TextDecoration.underline),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUserPost({required String user, required String message}) {
    return Card(
      color: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(color: Colors.white70))
          ],
        ),
      ),
    );
  }
}
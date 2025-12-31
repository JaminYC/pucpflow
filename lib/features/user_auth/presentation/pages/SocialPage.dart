import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/ProponerIdeaPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Innova/VerIdeasPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/proyectos/ProyectosPage.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Impacto Social y Proyectos',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          _buildGradientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildActionGrid(isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0E152E),
                Color(0xFF18254A),
                Color(0xFF0E152E),
              ],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -40,
          child: _blurCircle(160, Colors.blueAccent.withOpacity(0.18)),
        ),
        Positioned(
          bottom: -60,
          left: -30,
          child: _blurCircle(140, Colors.pinkAccent.withOpacity(0.16)),
        ),
      ],
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text("Lobby de proyectos", style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          const SizedBox(height: 10),
          const Text(
            "Explora, crea y comparte ideas",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "Accesos rápidos para colaborar con proyectos e ideas en la comunidad.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _headerChip(Icons.flash_on, "Explora proyectos activos"),
              _headerChip(Icons.lightbulb, "Propuestas e ideas"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionGrid(bool isMobile) {
    final actions = [
      _ActionCardData(
        title: "Explorar Proyectos",
        description: "Descubre iniciativas activas y súmate como colaborador.",
        icon: Icons.folder_open,
        color: Colors.cyanAccent,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProyectosPage())),
      ),
      _ActionCardData(
        title: "Proponer Idea",
        description: "Lanza tu idea y consigue equipo para ejecutarla.",
        icon: Icons.lightbulb,
        color: Colors.pinkAccent,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProponerIdeaPage())),
      ),
      _ActionCardData(
        title: "Ver Ideas",
        description: "Explora ideas publicadas y súmate a su desarrollo.",
        icon: Icons.people,
        color: Colors.greenAccent,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerIdeasPage())),
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 2,
        childAspectRatio: isMobile ? 3.0 : 3.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _ActionCard(data: action);
      },
    );
  }
}

class _ActionCardData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ActionCard extends StatelessWidget {
  final _ActionCardData data;

  const _ActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.06),
              Colors.white.withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: data.color.withOpacity(0.2),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: data.color.withOpacity(0.18),
              child: Icon(data.icon, color: data.color, size: 14),
            ),
            const SizedBox(height: 8),
            Text(
              data.title,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              data.description,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const Spacer(),
            Row(
              children: [
                Text("Abrir", style: TextStyle(color: data.color, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward, color: data.color, size: 18),
              ],
            )
          ],
        ),
      ),
    );
  }
}

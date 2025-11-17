import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// AppBar personalizado que muestra el branding de Vastoria
/// Indica que la app actual (ej. Flow) es parte del ecosistema Vastoria
class VastoriaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String appName; // Nombre de la app actual (ej. "Flow", "Cafillari", "Vitakua")
  final String? subtitle; // Subtítulo opcional
  final List<Widget>? actions; // Acciones personalizadas
  final bool showEcosystemMenu; // Mostrar menú de apps del ecosistema

  const VastoriaAppBar({
    Key? key,
    required this.appName,
    this.subtitle,
    this.actions,
    this.showEcosystemMenu = true,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo Vastoria (pequeño)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logovastoria.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.apps,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nombre de la app actual
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'VASTORIA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '•',
                    style: TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    appName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: Colors.white38,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (showEcosystemMenu) _buildEcosystemMenu(context),
        if (actions != null) ...actions!,
      ],
    );
  }

  Widget _buildEcosystemMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.apps, color: Colors.white),
      tooltip: 'Apps del Ecosistema Vastoria',
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 50),
      itemBuilder: (context) => [
        const PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ECOSISTEMA VASTORIA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white60,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Divider(color: Colors.white24, thickness: 0.5),
            ],
          ),
        ),
        _buildAppMenuItem(
          'Flow',
          'Gestión de Proyectos con IA',
          Icons.account_tree,
          'https://flow.teamvastoria.com',
        ),
        _buildAppMenuItem(
          'Cafillari',
          'IoT para Cafetales',
          Icons.coffee,
          'https://cafillari.teamvastoria.com',
        ),
        _buildAppMenuItem(
          'Vitakua',
          'Gestión Inteligente de Agua',
          Icons.water_drop,
          'https://vitakua.teamvastoria.com',
        ),
        _buildAppMenuItem(
          'Innova',
          'Innovación Empresarial',
          Icons.lightbulb,
          'https://innova.teamvastoria.com',
        ),
        const PopupMenuDivider(),
        _buildAppMenuItem(
          'Ver todas las apps',
          'teamvastoria.com',
          Icons.launch,
          'https://teamvastoria.com',
          isExternal: true,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildAppMenuItem(
    String title,
    String subtitle,
    IconData icon,
    String url, {
    bool isExternal = false,
  }) {
    return PopupMenuItem<String>(
      value: url,
      onTap: () => _launchUrl(url),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white70, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          if (isExternal)
            const Icon(Icons.open_in_new, color: Colors.white38, size: 14),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error al abrir URL: $e');
    }
  }
}

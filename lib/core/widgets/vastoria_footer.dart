import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Footer reutilizable que muestra el branding de Vastoria
/// Se puede usar en cualquier pantalla de la app
class VastoriaFooter extends StatelessWidget {
  final Color? backgroundColor;
  final Color? textColor;

  const VastoriaFooter({
    super.key,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Parte del ecosistema ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor?.withValues(alpha: 0.7) ?? const Color(0xFFF7F7F7),
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: () => _launchUrl('https://teamvastoria.com'),
                child: Text(
                  "VASTORIA",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor ?? const Color(0xFFF7F7F7),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "© 2025 Vastoria. Todos los derechos reservados.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor?.withValues(alpha: 0.6) ?? const Color(0xFFAAAAAA),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error al abrir URL: $e');
    }
  }
}

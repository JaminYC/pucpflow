import 'package:flutter/material.dart';
import 'package:pucpflow/demo/gamification_test_page.dart';

/// 🚀 Widget de Acceso Rápido a Gamification Test
///
/// Agrega este widget en cualquier página para acceder fácilmente
/// a la prueba de gamification.riv
///
/// USO RÁPIDO EN CUALQUIER PÁGINA:
///
/// ```dart
/// // Opción 1: Como botón flotante en Scaffold
/// floatingActionButton: GamificationQuickAccessButton(),
///
/// // Opción 2: En AppBar actions
/// appBar: AppBar(
///   actions: [GamificationQuickAccessButton()],
/// ),
///
/// // Opción 3: Como botón en el body
/// GamificationQuickAccessButton(),
/// ```
class GamificationQuickAccessButton extends StatelessWidget {
  final bool isFloatingActionButton;
  final String? tooltip;

  const GamificationQuickAccessButton({
    super.key,
    this.isFloatingActionButton = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (isFloatingActionButton) {
      return FloatingActionButton.extended(
        onPressed: () => _navigateToTest(context),
        icon: const Icon(Icons.stars),
        label: const Text('Test Gamification'),
        backgroundColor: const Color(0xFFFBBF24),
        foregroundColor: Colors.white,
        tooltip: tooltip ?? 'Probar gamification.riv',
      );
    }

    return IconButton(
      icon: const Icon(Icons.stars),
      tooltip: tooltip ?? 'Probar gamification.riv',
      onPressed: () => _navigateToTest(context),
    );
  }

  void _navigateToTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GamificationTestPage(),
      ),
    );
  }
}

/// 🎮 Card de Acceso Rápido (para usar en listas)
class GamificationQuickAccessCard extends StatelessWidget {
  const GamificationQuickAccessCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GamificationTestPage(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.stars,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gamification Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Probar animación de estrellas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🎯 Banner de Acceso Rápido (pequeño)
class GamificationQuickAccessBanner extends StatelessWidget {
  const GamificationQuickAccessBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const GamificationTestPage(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.stars, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Probar Gamification',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.play_arrow, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

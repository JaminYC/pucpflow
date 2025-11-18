import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Landing page principal del ecosistema Vastoria
/// Se muestra en teamvastoria.com
/// Presenta todas las aplicaciones disponibles
class VastoriaEcosystemLanding extends StatefulWidget {
  const VastoriaEcosystemLanding({super.key});

  @override
  State<VastoriaEcosystemLanding> createState() => _VastoriaEcosystemLandingState();
}

class _VastoriaEcosystemLandingState extends State<VastoriaEcosystemLanding> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // AppBar flotante
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            pinned: true,
            backgroundColor: Colors.black.withValues(alpha: 0.9),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logovastoria.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.apps,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VASTORIA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Text(
                        'Ecosistema de Aplicaciones',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          color: Colors.white60,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Contenido principal
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Hero Section
                _buildHeroSection(),

                const SizedBox(height: 80),

                // Apps Section
                _buildAppsSection(),

                const SizedBox(height: 80),

                // Features Section
                _buildFeaturesSection(),

                const SizedBox(height: 80),

                // Footer
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          // Logo grande
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logovastoria.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.apps,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'VASTORIA',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 4.0,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          const Text(
            'Ecosistema de Soluciones Inteligentes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: Colors.white70,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          const Text(
            'Impulsando la innovación y productividad con tecnología de punta',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Text(
            'NUESTRAS APLICACIONES',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          const Text(
            'Soluciones especializadas para cada necesidad',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Grid de apps
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                      ? 2
                      : 1;

              return Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildAppCard(
                    'FLOW',
                    'Gestión de Proyectos con IA',
                    'Organiza proyectos, tareas y equipos con inteligencia artificial. Sistema de gamificación y análisis de habilidades.',
                    Icons.account_tree,
                    'https://flow.teamvastoria.com',
                    const Color(0xFF133E87),
                    available: true,
                  ),
                  _buildAppCard(
                    'CAFILLARI',
                    'IoT para Cafetales',
                    'Monitoreo inteligente de plantaciones de café. Trazabilidad, alertas y control remoto.',
                    Icons.coffee,
                    'https://cafillari.teamvastoria.com',
                    const Color(0xFF4A5D23),
                    available: false,
                  ),
                  _buildAppCard(
                    'VITAKUA',
                    'Gestión Inteligente de Agua',
                    'Control de consumo y distribución de agua. Panel comunitario y métricas en tiempo real.',
                    Icons.water_drop,
                    'https://vitakua.teamvastoria.com',
                    const Color(0xFF1A3D7C),
                    available: false,
                  ),
                  _buildAppCard(
                    'INNOVA',
                    'Innovación Empresarial',
                    'Convierte ideas en proyectos ejecutables. Análisis IA, validación y generación de tareas.',
                    Icons.lightbulb,
                    'https://innova.teamvastoria.com',
                    const Color(0xFF8B4513),
                    available: false,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(
    String title,
    String subtitle,
    String description,
    IconData icon,
    String url,
    Color accentColor, {
    bool available = true,
  }) {
    return Container(
      width: 280,
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: available ? accentColor.withValues(alpha: 0.3) : Colors.white12,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: available
                ? accentColor.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: available ? () => _launchUrl(url) : null,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 20),

                // Título
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 6),

                // Subtítulo
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Descripción
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white60,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Estado / Botón
                Row(
                  children: [
                    if (available)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Acceder',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward,
                                color: accentColor,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white12,
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Próximamente',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white38,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          const Text(
            'POR QUÉ VASTORIA',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          Wrap(
            spacing: 32,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureItem(
                Icons.psychology,
                'Inteligencia Artificial',
                'Análisis avanzados con GPT-4',
              ),
              _buildFeatureItem(
                Icons.devices,
                'Multiplataforma',
                'Web, iOS y Android',
              ),
              _buildFeatureItem(
                Icons.speed,
                'Tiempo Real',
                'Sincronización instantánea',
              ),
              _buildFeatureItem(
                Icons.security,
                'Seguro',
                'Firebase + Encriptación',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white12,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white70,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      color: Colors.black,
      child: Column(
        children: [
          const Text(
            'VASTORIA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Transformando ideas en realidad',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 24),
          const Text(
            '© 2025 Vastoria. Todos los derechos reservados.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white38,
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

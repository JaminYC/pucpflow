import 'package:flutter/material.dart';
import 'crear_proyecto_contextual_page.dart';
import 'crear_proyecto_pmi_page.dart';
import 'crear_proyecto_personal_page.dart';

class ProyectoIAGatewayPage extends StatelessWidget {
  const ProyectoIAGatewayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header Hero
            SliverAppBar(
              expandedHeight: isMobile ? 200 : 280,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF0A0E27),
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Crear Proyecto con IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 22,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF8B5CF6).withOpacity(0.2),
                        const Color(0xFF3B82F6).withOpacity(0.1),
                        const Color(0xFF0A0E27),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: isMobile ? 80 : 120,
                        left: 24,
                        right: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF8B5CF6),
                                  Color(0xFF3B82F6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                  blurRadius: 24,
                                  spreadRadius: -4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Elige el tipo de proyecto que mejor se adapte a tus necesidades',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFB8BCC8),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Contenido - Opciones de proyecto
            SliverPadding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Blueprint Contextual
                  _buildProjectOptionCard(
                    context,
                    icon: Icons.track_changes_outlined,
                    title: 'Blueprint Contextual',
                    subtitle: 'Proyectos ágiles y adaptativos',
                    description:
                        'Genera un plan flexible basado en objetivos, habilidades del equipo y foco de negocio. Perfecto para proyectos ágiles, discovery o innovación.',
                    features: [
                      'Análisis contextual con IA',
                      'Skills técnicas y blandas',
                      'Metodologías flexibles',
                      'Workflows adaptativos',
                    ],
                    gradientColors: const [
                      Color(0xFF8B5CF6),
                      Color(0xFF3B82F6),
                    ],
                    accentColor: const Color(0xFF8B5CF6),
                    tag: 'Recomendado',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CrearProyectoContextualPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Proyecto Personal
                  _buildProjectOptionCard(
                    context,
                    icon: Icons.auto_awesome,
                    title: 'Proyecto Personal',
                    subtitle: '100% personalizable y flexible',
                    description:
                        'Crea un plan totalmente adaptado a tus necesidades únicas sin seguir frameworks rígidos. La IA diseñará fases, tareas y estrategias específicas para ti.',
                    features: [
                      'Total libertad creativa',
                      'Adaptado a tus restricciones',
                      'Fases personalizadas',
                      'Consejos y hábitos incluidos',
                    ],
                    gradientColors: const [
                      Color(0xFFEC4899),
                      Color(0xFF8B5CF6),
                    ],
                    accentColor: const Color(0xFFEC4899),
                    tag: 'Nuevo',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CrearProyectoPersonalPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Blueprint PMI
                  _buildProjectOptionCard(
                    context,
                    icon: Icons.account_tree_outlined,
                    title: 'Blueprint PMI (PMBOK)',
                    subtitle: 'Gestión formal de proyectos',
                    description:
                        'Crea automáticamente las 5 fases PMI con entregables, paquetes de trabajo y tareas jerarquizadas según el estándar PMBOK.',
                    features: [
                      '5 fases del PMBOK',
                      'Paquetes de trabajo',
                      'Entregables definidos',
                      'Estructura jerárquica',
                    ],
                    gradientColors: const [
                      Color(0xFF3B82F6),
                      Color(0xFF06B6D4),
                    ],
                    accentColor: const Color(0xFF3B82F6),
                    tag: null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CrearProyectoPMIPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required List<String> features,
    required List<Color> gradientColors,
    required Color accentColor,
    required VoidCallback onTap,
    String? tag,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF2D3347).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y gradiente
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradientColors[0].withOpacity(0.15),
                  gradientColors[1].withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (tag != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor.withOpacity(0.3),
                                    accentColor.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tag.toUpperCase(),
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFFB8BCC8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Descripción
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFB8BCC8),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),

                // Divider
                Container(
                  height: 1,
                  color: const Color(0xFF2D3347).withOpacity(0.5),
                ),
                const SizedBox(height: 20),

                // Features
                const Text(
                  'Características:',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              color: Color(0xFFB8BCC8),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // Botón
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: -4,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(14),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Configurar Proyecto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

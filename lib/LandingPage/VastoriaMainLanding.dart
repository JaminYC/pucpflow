import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Landing page principal del ecosistema Vastoria
/// Combina diseño visual con funcionalidad de SSO (Single Sign-On)
/// Un solo usuario puede acceder a todas las apps del ecosistema
class VastoriaMainLanding extends StatefulWidget {
  const VastoriaMainLanding({super.key});

  @override
  State<VastoriaMainLanding> createState() => _VastoriaMainLandingState();
}

class _VastoriaMainLandingState extends State<VastoriaMainLanding> {
  late VideoPlayerController _backgroundVideo;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _loadUserData();
  }

  void _initializeVideo() {
    _backgroundVideo = VideoPlayerController.asset("assets/background.mp4")
      ..initialize().then((_) {
        _backgroundVideo.setLooping(true);
        _backgroundVideo.setVolume(0);
        _backgroundVideo.play();
        if (mounted) setState(() {});
      });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingUser = true);

    _currentUser = _auth.currentUser;

    if (_currentUser != null) {
      try {
        final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
        if (doc.exists) {
          _userData = doc.data();
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }

    if (mounted) setState(() => _isLoadingUser = false);
  }

  @override
  void dispose() {
    _backgroundVideo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Video de fondo
          if (_backgroundVideo.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _backgroundVideo.value.size.width,
                  height: _backgroundVideo.value.size.height,
                  child: VideoPlayer(_backgroundVideo),
                ),
              ),
            ),

          // Overlay oscuro
          Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),

          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // Hero Section
                  _buildHeroSection(),

                  const SizedBox(height: 80),

                  // Apps del Ecosistema
                  _buildAppsSection(),

                  const SizedBox(height: 80),

                  // Features
                  _buildFeaturesSection(),

                  const SizedBox(height: 60),

                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black.withValues(alpha: 0.7),
      elevation: 0,
      title: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
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
          const Text(
            'VASTORIA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
      actions: [
        // Navegación
        if (MediaQuery.of(context).size.width > 800) ...[
          _buildHeaderButton('Inicio', () => _scrollToSection(0)),
          _buildHeaderButton('Ecosistema', () => _scrollToSection(1)),
          _buildHeaderButton('Aplicaciones', () => _scrollToSection(2)),
        ],

        const SizedBox(width: 16),

        // Usuario o Login
        if (_isLoadingUser)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          )
        else if (_currentUser != null)
          _buildUserMenu()
        else
          _buildAuthButtons(),

        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildHeaderButton(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildAuthButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          child: const Text(
            'Iniciar Sesión',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF133E87),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Registrarse',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMenu() {
    final userName = _userData?['full_name'] ?? _currentUser?.displayName ?? 'Usuario';
    final userEmail = _currentUser?.email ?? '';
    final userPhoto = _userData?['fotoPerfil'] ?? _currentUser?.photoURL;

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF133E87),
              backgroundImage: userPhoto != null ? NetworkImage(userPhoto) : null,
              child: userPhoto == null
                  ? Text(
                      userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            if (MediaQuery.of(context).size.width > 600)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white24),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'perfil',
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.white70, size: 18),
              SizedBox(width: 12),
              Text('Mi Perfil', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'configuracion',
          child: Row(
            children: [
              Icon(Icons.settings, color: Colors.white70, size: 18),
              SizedBox(width: 12),
              Text('Configuración', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.redAccent, size: 18),
              SizedBox(width: 12),
              Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'perfil':
            Navigator.pushNamed(context, '/home');
            break;
          case 'configuracion':
            // Ir a configuración
            break;
          case 'logout':
            await _auth.signOut();
            setState(() {
              _currentUser = null;
              _userData = null;
            });
            break;
        }
      },
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          // Logo grande
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
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
                  size: 70,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          const Text(
            'VASTORIA',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 6.0,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 20,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          const Text(
            'En el vasto mundo de talentos, solo algunos hacemos historia.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 1.0,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          const Text(
            'Ecosistema de Talento y Proyectos Colaborativos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // CTA Button
          ElevatedButton(
            onPressed: () {
              if (_currentUser != null) {
                // Ya está logueado, ir a apps
                _scrollToSection(2);
              } else {
                Navigator.pushNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF133E87),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
            ),
            child: Text(
              _currentUser != null ? 'Explorar Aplicaciones' : 'Comienza Gratis',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
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
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3.0,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          const Text(
            'Un solo inicio de sesión para acceder a todo el ecosistema',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Grid de apps
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200
                  ? 4
                  : constraints.maxWidth > 800
                      ? 3
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
                    'Organiza proyectos, tareas y equipos con inteligencia artificial. Sistema de gamificación con 24 habilidades y análisis de rendimiento.',
                    Icons.account_tree,
                    '/login',
                    const Color(0xFF133E87),
                    available: true,
                    requiresLogin: true,
                  ),
                  _buildAppCard(
                    'CAFILLARI',
                    'IoT para Cafetales',
                    'Monitoreo inteligente de plantaciones de café. Trazabilidad completa, alertas automatizadas y control remoto de dispositivos IoT.',
                    Icons.coffee,
                    '/cafillari',
                    const Color(0xFF6B4226),
                    available: true,
                    requiresLogin: false,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 48),

          // SSO Info
          if (_currentUser != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      'Estás conectado como ${_currentUser!.email}. Puedes acceder a todas las aplicaciones disponibles sin volver a iniciar sesión.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
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
    bool requiresLogin = true,
  }) {
    return Container(
      width: 300,
      height: 360,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: available ? accentColor.withValues(alpha: 0.4) : Colors.white12,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: available
                ? accentColor.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: available
              ? () {
                  if (!requiresLogin) {
                    // No requiere login, navegar directamente
                    Navigator.pushNamed(context, url);
                  } else if (_currentUser != null) {
                    // Requiere login y está logueado
                    Navigator.pushNamed(context, url);
                  } else {
                    // Requiere login pero no está logueado
                    _showLoginDialog();
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 36,
                  ),
                ),

                const SizedBox(height: 24),

                // Título
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtítulo
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Botón
                if (available)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          !requiresLogin
                              ? 'Acceder Gratis'
                              : (_currentUser != null ? 'Abrir' : 'Iniciar para acceder'),
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          !requiresLogin
                              ? Icons.arrow_forward
                              : (_currentUser != null ? Icons.launch : Icons.lock),
                          color: accentColor,
                          size: 18,
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
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
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
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
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3.0,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          Wrap(
            spacing: 40,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureItem(
                Icons.login,
                'Single Sign-On',
                'Un solo inicio de sesión para todas las apps',
              ),
              _buildFeatureItem(
                Icons.psychology,
                'Inteligencia Artificial',
                'Análisis avanzados con GPT-4',
              ),
              _buildFeatureItem(
                Icons.devices,
                'Multiplataforma',
                'Web, iOS y Android nativos',
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
              _buildFeatureItem(
                Icons.groups,
                'Colaborativo',
                'Equipos y proyectos compartidos',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return SizedBox(
      width: 220,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white24,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white70,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white60,
              height: 1.5,
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
      color: Colors.black.withValues(alpha: 0.7),
      child: Column(
        children: [
          const Text(
            'VASTORIA',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Transformando ideas en realidad',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 24),
          const Text(
            '© 2025 Vastoria. Todos los derechos reservados.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToSection(int section) {
    // Implementar scroll suave a sección
    // Por ahora solo scroll básico
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Iniciar Sesión Requerido',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Para acceder a las aplicaciones del ecosistema Vastoria, necesitas iniciar sesión con tu cuenta.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF133E87),
            ),
            child: const Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }

}

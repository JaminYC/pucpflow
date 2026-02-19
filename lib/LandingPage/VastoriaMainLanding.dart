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

class _VastoriaMainLandingState extends State<VastoriaMainLanding>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  late AnimationController _backgroundAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // Keys para navegación suave entre secciones
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _appsKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();

  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
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

      // Si el usuario está autenticado, scroll automático a la bóveda de aplicaciones
      if (mounted) {
        setState(() => _isLoadingUser = false);
        // Esperar un poco para que la UI se construya completamente
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _scrollToSection(2); // Scroll a la sección de aplicaciones
          }
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Fondo elegante blanco y negro con gradiente y patrón
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF5F5F5), // Blanco casi puro
                  const Color(0xFFE8E8E8), // Gris muy claro
                  const Color(0xFFD0D0D0), // Gris claro
                  const Color(0xFFB8B8B8), // Gris medio claro
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // Patrón de puntos elegante con animación
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: DotPatternPainter(
                    animationValue: _pulseAnimation.value,
                  ),
                );
              },
            ),
          ),

          // Overlay sutil para profundidad
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // Hero Section / Inicio
                  Container(
                    key: _heroKey,
                    child: _buildHeroSection(),
                  ),

                  const SizedBox(height: 80),

                  // Apps del Ecosistema
                  Container(
                    key: _appsKey,
                    child: _buildAppsSection(),
                  ),

                  const SizedBox(height: 80),

                  // Features / Por qué Vastoria
                  Container(
                    key: _featuresKey,
                    child: _buildFeaturesSection(),
                  ),

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
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.98),
              Colors.white.withValues(alpha: 0.90),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo con efecto elegante
          Container(
            width: MediaQuery.of(context).size.width < 600 ? 32 : 44,
            height: MediaQuery.of(context).size.width < 600 ? 32 : 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF133E87),
                  Color(0xFF0A2351),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF133E87).withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF133E87).withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.asset(
                'assets/logovastoria.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.apps,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width < 600 ? 8 : 16),
          Flexible(
            child: Text(
              'VASTORIA',
              style: TextStyle(
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w800,
                fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 20,
                letterSpacing: MediaQuery.of(context).size.width < 600 ? 1.5 : 3.0,
                shadows: const [
                  Shadow(
                    color: Color(0xFF133E87),
                    blurRadius: 15,
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // Navegación
        if (MediaQuery.of(context).size.width > 900) ...[
          _buildHeaderButton('Inicio', () => _scrollToSection(0)),
          _buildHeaderButton('Aplicaciones', () => _scrollToSection(2)),
          _buildHeaderButton('Características', () => _scrollToSection(3)),
          const SizedBox(width: 8),
        ],

        const SizedBox(width: 8),

        // Usuario o Login
        if (_isLoadingUser)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF133E87),
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
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        foregroundColor: const Color(0xFF133E87),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2A2A2A),
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildAuthButtons() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isMobile)
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/flow/login'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              foregroundColor: const Color(0xFF133E87),
            ),
            child: const Text(
              'Iniciar Sesión',
              style: TextStyle(
                color: Color(0xFF2A2A2A),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        if (!isMobile) const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF133E87),
                Color(0xFF0A2351),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF133E87).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/flow/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: isMobile ? 10 : 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isMobile ? 'Entrar' : 'Iniciar Sesión',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: isMobile ? 12 : 14,
                letterSpacing: 0.5,
              ),
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
            Navigator.pushNamed(context, '/flow/home');
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: isMobile ? 40 : 80,
          ),
          child: Column(
            children: [
              // Logo grande con efectos elegantes
              Container(
                width: isMobile ? 100 : 160,
                height: isMobile ? 100 : 160,
                decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF133E87).withValues(alpha: 0.3),
                  const Color(0xFF0A2351).withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF133E87).withValues(alpha: 0.4),
                  blurRadius: 50,
                  spreadRadius: 15,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                'assets/logovastoria.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.apps,
                  color: Colors.white,
                  size: 80,
                ),
              ),
            ),
          ),

          SizedBox(height: isMobile ? 30 : 50),

          // Título principal con gradiente oscuro
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF1A1A1A),
                Color(0xFF3A3A3A),
              ],
            ).createShader(bounds),
            child: Text(
              'VASTORIA',
              style: TextStyle(
                fontSize: isMobile ? 36 : 64,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: isMobile ? 4.0 : 8.0,
                shadows: const [
                  Shadow(
                    color: Color(0xFF133E87),
                    blurRadius: 30,
                  ),
                  Shadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: isMobile ? 16 : 24),

          // Subtítulo con estilo elegante
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
            child: Text(
              'En un vasto mundo de talento, crecer es escribir historia.',
              style: TextStyle(
                fontSize: isMobile ? 16 : 24,
                fontWeight: FontWeight.w300,
                color: Color(0xFF3A3A3A),
                letterSpacing: 1.2,
                height: 1.6,
                shadows: [
                  Shadow(
                    color: Colors.black12,
                    blurRadius: 8,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Badge con descripción
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 10 : 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF133E87).withValues(alpha: 0.08),
                  const Color(0xFF133E87).withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF133E87).withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isMobile ? 6 : 8,
                  height: isMobile ? 6 : 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Flexible(
                  child: Text(
                    'Ecosistema de Talento y Proyectos Colaborativos',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isMobile ? 30 : 50),

          // CTA Button elegante con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF133E87),
                  Color(0xFF0A2351),
                ],
              ),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF133E87).withValues(alpha: 0.5),
                  blurRadius: 25,
                  spreadRadius: 3,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (_currentUser != null) {
                  _scrollToSection(2);
                } else {
                  Navigator.pushNamed(context, '/flow/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 32 : 48,
                  vertical: isMobile ? 16 : 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _currentUser != null ? 'Explorar Aplicaciones' : 'Comienza Gratis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 15 : 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: isMobile ? 18 : 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // Título elegante con gradiente oscuro
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF1A1A1A),
                Color(0xFF4A4A4A),
              ],
            ).createShader(bounds),
            child: const Text(
              'NUESTRO ECOSISTEMA',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4.0,
                shadows: [
                  Shadow(
                    color: Color(0xFF133E87),
                    blurRadius: 25,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Subtítulo elegante
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: const Text(
              'Un solo inicio de sesión para acceder a todo el ecosistema',
              style: TextStyle(
                fontSize: 17,
                color: Color(0xFF4A4A4A),
                letterSpacing: 0.8,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 60),

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
                    '/flow',
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      'Estás conectado como ${_currentUser!.email}. Puedes acceder a todas las aplicaciones disponibles sin volver a iniciar sesión.',
                      style: const TextStyle(
                        color: Color(0xFF2A2A2A),
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 900;

    return MouseRegion(
      onEnter: (_) => setState(() {}),
      onExit: (_) => setState(() {}),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: isMobile ? MediaQuery.of(context).size.width - 48 : (isTablet ? 300 : 340),
        height: isMobile ? 360 : (isTablet ? 380 : 420),
        transform: Matrix4.identity()..translate(0.0, 0.0, 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: available ? accentColor.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
            width: 2,
          ),
          boxShadow: [
            // Sombra principal fuerte
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 15),
            ),
            // Sombra secundaria para profundidad
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
            // Sombra de color sutil
            if (available)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: -10,
                offset: const Offset(0, 20),
              ),
          ],
        ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: available
              ? () {
                  if (!requiresLogin) {
                    Navigator.pushNamed(context, url);
                  } else if (_currentUser != null) {
                    Navigator.pushNamed(context, url);
                  } else {
                    _showLoginDialog();
                  }
                }
              : null,
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono con efecto glassmorphism
                Container(
                  width: isMobile ? 60 : 80,
                  height: isMobile ? 60 : 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.25),
                        accentColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: isMobile ? 32 : 40,
                  ),
                ),

                SizedBox(height: isMobile ? 20 : 28),

                // Título con sombra
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: isMobile ? 1.5 : 2.5,
                    shadows: [
                      Shadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isMobile ? 6 : 10),

                // Subtítulo elegante
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                SizedBox(height: isMobile ? 12 : 20),

                // Descripción
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: const Color(0xFF4A4A4A),
                      height: 1.7,
                      letterSpacing: 0.3,
                    ),
                    maxLines: isMobile ? 4 : null,
                    overflow: isMobile ? TextOverflow.ellipsis : null,
                  ),
                ),

                SizedBox(height: isMobile ? 16 : 24),

                // Botón elegante con gradiente
                if (available)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.25),
                          accentColor.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 12 : 14,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              !requiresLogin
                                  ? 'Acceder Gratis'
                                  : (_currentUser != null ? 'Abrir Aplicación' : 'Iniciar Sesión'),
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w700,
                                fontSize: isMobile ? 13 : 15,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              !requiresLogin
                                  ? Icons.arrow_forward_rounded
                                  : (_currentUser != null ? Icons.launch_rounded : Icons.lock_rounded),
                              color: accentColor,
                              size: isMobile ? 16 : 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                    ),
                    child: const Text(
                      'Próximamente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white38,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
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
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF1A1A1A),
                Color(0xFF3A3A3A),
              ],
            ).createShader(bounds),
            child: const Text(
              'POR QUÉ VASTORIA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3.0,
              ),
              textAlign: TextAlign.center,
            ),
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
    return Container(
      width: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF133E87).withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF133E87).withValues(alpha: 0.12),
                  const Color(0xFF133E87).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF133E87).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF133E87),
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A4A4A),
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
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'VASTORIA',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Transformando ideas en realidad',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF4A4A4A),
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.black.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          const Text(
            '© 2025 Vastoria. Todos los derechos reservados.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6A6A6A),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToSection(int section) {
    GlobalKey? targetKey;

    switch (section) {
      case 0:
        targetKey = _heroKey; // Inicio
        break;
      case 2:
        targetKey = _appsKey; // Aplicaciones
        break;
      case 3:
        targetKey = _featuresKey; // Características
        break;
    }

    if (targetKey?.currentContext != null) {
      Scrollable.ensureVisible(
        targetKey!.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignment: 0.1, // Posición en la pantalla (0.0 = top, 1.0 = bottom)
      );
    }
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
              Navigator.pushNamed(context, '/flow/login');
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

/// CustomPainter para crear patrones geométricos modernos con animación de pulsos
class DotPatternPainter extends CustomPainter {
  final double animationValue;

  DotPatternPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Patrón de puntos base más visibles
    final dotPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    const double dotRadius = 2.0;
    const double spacing = 35.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }

    // Efecto de pulso: oscila entre 0.9 y 1.1
    final pulseScale = 0.9 + (animationValue * 0.2);

    // Opacidad que pulsa
    final pulseAlpha = 0.08 + (animationValue * 0.08);

    // Círculos decorativos grandes más visibles con pulso
    final circlePaint = Paint()
      ..color = Color(0xFF133E87).withValues(alpha: pulseAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Círculo superior derecho - múltiples anillos con pulso
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      150 * pulseScale,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      200 * pulseScale,
      circlePaint..strokeWidth = 2.0,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      250 * pulseScale,
      circlePaint..strokeWidth = 1.5,
    );

    // Círculo inferior izquierdo con pulso inverso
    final inversePulseScale = 1.1 - (animationValue * 0.2);
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.85),
      180 * inversePulseScale,
      circlePaint..strokeWidth = 3.0,
    );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.85),
      230 * inversePulseScale,
      circlePaint..strokeWidth = 2.0,
    );

    // Círculo central con pulso
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      120 * pulseScale,
      circlePaint..strokeWidth = 2.5,
    );

    // Líneas diagonales más visibles y abundantes con opacidad pulsante
    final lineAlpha = 0.05 + (animationValue * 0.06);
    final linePaint = Paint()
      ..color = Color(0xFF133E87).withValues(alpha: lineAlpha)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Red de líneas diagonales
    final path1 = Path();
    path1.moveTo(size.width * 0.2, 0);
    path1.lineTo(size.width, size.height * 0.8);
    canvas.drawPath(path1, linePaint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.2);
    path2.lineTo(size.width * 0.8, size.height);
    canvas.drawPath(path2, linePaint);

    final path3 = Path();
    path3.moveTo(size.width * 0.6, 0);
    path3.lineTo(size.width, size.height * 0.4);
    canvas.drawPath(path3, linePaint..strokeWidth = 2.0);

    final path4 = Path();
    path4.moveTo(0, size.height * 0.6);
    path4.lineTo(size.width * 0.4, size.height);
    canvas.drawPath(path4, linePaint..strokeWidth = 2.0);

    // Líneas horizontales y verticales sutiles
    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Líneas horizontales
    for (double y = 100; y < size.height; y += 200) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Líneas verticales
    for (double x = 100; x < size.width; x += 200) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Cuadrados decorativos más visibles y variados con opacidad pulsante
    final squareAlpha = 0.06 + (animationValue * 0.08);
    final squareStrokeAlpha = 0.1 + (animationValue * 0.1);

    final squarePaint = Paint()
      ..color = Color(0xFF133E87).withValues(alpha: squareAlpha)
      ..style = PaintingStyle.fill;

    final squareStrokePaint = Paint()
      ..color = Color(0xFF133E87).withValues(alpha: squareStrokeAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Cuadrados rellenos
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.2, 20, 20),
      squarePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.75, size.height * 0.6, 25, 25),
      squarePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.4, size.height * 0.1, 18, 18),
      squarePaint,
    );

    // Cuadrados con solo borde
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.3, size.height * 0.7, 30, 30),
      squareStrokePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.8, size.height * 0.3, 35, 35),
      squareStrokePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.6, size.height * 0.8, 28, 28),
      squareStrokePaint,
    );

    // Triángulos decorativos con pulso
    final triangleAlpha = 0.05 + (animationValue * 0.08);
    final trianglePaint = Paint()
      ..color = Color(0xFF133E87).withValues(alpha: triangleAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final triangle1 = Path();
    triangle1.moveTo(size.width * 0.9, size.height * 0.5);
    triangle1.lineTo(size.width * 0.95, size.height * 0.6);
    triangle1.lineTo(size.width * 0.85, size.height * 0.6);
    triangle1.close();
    canvas.drawPath(triangle1, trianglePaint);

    final triangle2 = Path();
    triangle2.moveTo(size.width * 0.05, size.height * 0.4);
    triangle2.lineTo(size.width * 0.1, size.height * 0.5);
    triangle2.lineTo(size.width * 0.0, size.height * 0.5);
    triangle2.close();
    canvas.drawPath(triangle2, trianglePaint);
  }

  @override
  bool shouldRepaint(covariant DotPatternPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

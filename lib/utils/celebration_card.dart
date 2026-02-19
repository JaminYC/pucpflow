import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── Mensajes profundos e individuales por índice del día ────────────────────
// Se selecciona uno basado en el día del mes del cumpleaños → variedad real
const _mensajesCEO = [
  'Hoy el universo te recuerda que tu presencia en este equipo no es casualidad. Gracias por existir.',
  'Cada año que pasa te hace más tú. Y ese tú es exactamente lo que Vastoria necesita.',
  'No celebramos solo tu nacimiento — celebramos todo lo que has construido desde entonces.',
  'Hay personas que iluminan los espacios donde entran. Tú eres una de ellas.',
  'Tu camino hasta aquí ha sido único. Lo que viene será incluso más grande.',
  'El mayor regalo que puedes dar al mundo es seguir siendo auténtico. Hoy lo celebramos.',
  'Vastoria existe porque personas como tú creen que el trabajo puede ser algo más que trabajo.',
  'Hoy no es solo tu cumpleaños — es el aniversario de que el mundo se volvió mejor.',
  'Lo que más admiro de ti es que apareces, incluso cuando es difícil. Eso es raro y valioso.',
  'Que este año te traiga exactamente lo que mereces: mucho, porque das mucho.',
  'El equipo no sería el mismo sin ti. Eso no es un cliché — es la verdad.',
  'Crecer no siempre es fácil. Pero tú lo haces con una gracia que inspira a los demás.',
];

// ─── Partícula de confeti ────────────────────────────────────────────────────
class _ConfettiParticle {
  final double x;
  final double speed;
  final double size;
  final Color color;
  final bool isCircle;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.x,
    required this.speed,
    required this.size,
    required this.color,
    required this.isCircle,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.progress, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color.withValues(alpha: 0.75);
      final yFrac = (progress * p.speed) % 1.0;
      final x = p.x * size.width;
      final y = yFrac * (size.height + p.size) - p.size;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotationSpeed * math.pi * 2);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ─── Widget de contenido ─────────────────────────────────────────────────────
class _CelebrationContent extends StatefulWidget {
  final String userName;
  final String mensaje;

  const _CelebrationContent({required this.userName, required this.mensaje});

  @override
  State<_CelebrationContent> createState() => _CelebrationContentState();
}

class _CelebrationContentState extends State<_CelebrationContent>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final List<_ConfettiParticle> _particles;

  static const _colors = [
    Color(0xFFFFD700),
    Color(0xFFFF6B9D),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF97316),
  ];

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);
    _particles = List.generate(22, (i) => _ConfettiParticle(
      x: rng.nextDouble(),
      speed: 0.35 + rng.nextDouble() * 0.7,
      size: 4 + rng.nextDouble() * 7,
      color: _colors[rng.nextInt(_colors.length)],
      isCircle: rng.nextBool(),
      rotationSpeed: (rng.nextDouble() - 0.5) * 5,
    ));

    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = math.min(screenWidth * 0.88, 360.0);

    return Center(
      child: SizedBox(
        width: cardWidth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Card principal ───────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF120B2E), Color(0xFF0A1628), Color(0xFF0D1F37)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Confeti animado
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _confettiCtrl,
                        builder: (_, __) => CustomPaint(
                          painter: _ConfettiPainter(_confettiCtrl.value, _particles),
                        ),
                      ),
                    ),

                    // Contenido
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badge VASTORIA pequeño
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'VASTORIA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Avatar con borde dorado pulsante
                          AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, child) => Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFF97316)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700)
                                        .withValues(alpha: 0.25 + _pulseAnim.value * 0.35),
                                    blurRadius: 16 + _pulseAnim.value * 12,
                                    spreadRadius: _pulseAnim.value * 3,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(3),
                              child: child,
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF120B2E),
                              ),
                              child: const Center(
                                child: Text('\ud83c\udf82', style: TextStyle(fontSize: 30, decoration: TextDecoration.none)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Nombre
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              decoration: TextDecoration.none,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '\u00a1Feliz Cumplea\u00f1os!',
                            style: TextStyle(
                              color: const Color(0xFFFF6B9D).withValues(alpha: 0.9),
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Te desea todo el equipo Vastoria',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.none,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Mensaje único del CEO
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Comillas decorativas
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    '\u201c',
                                    style: TextStyle(
                                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                                      fontSize: 40,
                                      fontFamily: 'Georgia',
                                      height: 0.8,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                                Text(
                                  widget.mensaje,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    height: 1.65,
                                    letterSpacing: 0.1,
                                    decoration: TextDecoration.none,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),

                                // Firma equipo
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'V',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Con carino, el equipo Vastoria',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 11,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Botón CTA
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: double.infinity,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                                ),
                                borderRadius: BorderRadius.circular(13),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Un gran d\u00eda me espera \u2728',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.none,
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
              ),
            ),

            // Botón X
            Positioned(
              top: -8,
              right: -8,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F3A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Icon(Icons.close, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── API pública ─────────────────────────────────────────────────────────────
class CelebrationCard {
  /// Selecciona un mensaje profundo basado en el día del mes (variedad real entre usuarios)
  static String _seleccionarMensaje(String userName) {
    final seed = userName.codeUnits.fold(0, (a, b) => a + b);
    return _mensajesCEO[seed % _mensajesCEO.length];
  }

  static void show(BuildContext context, {required String userName}) {
    final mensaje = _seleccionarMensaje(userName);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withValues(alpha: 0.84),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic));

        return FadeTransition(
          opacity: anim1,
          child: SlideTransition(
            position: slide,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: _CelebrationContent(userName: userName, mensaje: mensaje),
              ),
            ),
          ),
        );
      },
    );
  }
}

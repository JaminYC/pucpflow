import 'package:flutter/material.dart';
import 'package:pucpflow/widgets/rive_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🎨 Ejemplos Prácticos de Integración de Rive
///
/// Esta página muestra cómo usar las animaciones Rive en casos reales.
/// Puedes acceder desde HomePage con un botón "Ver Ejemplos Rive".
class RiveIntegrationExamples extends StatefulWidget {
  const RiveIntegrationExamples({super.key});

  @override
  State<RiveIntegrationExamples> createState() =>
      _RiveIntegrationExamplesState();
}

class _RiveIntegrationExamplesState extends State<RiveIntegrationExamples> {
  bool _isLoading = false;
  bool _isFavorite = false;
  int _successCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('🎨 Ejemplos de Rive'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoading
          ? RiveFullscreenLoading(
              message: 'Cargando datos...',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Sección 1: Loading States
                  _buildSection(
                    '1. Loading States',
                    'Indicadores de carga con animaciones',
                    [
                      _buildExampleCard(
                        'Fullscreen Loading',
                        'Loading que cubre toda la pantalla',
                        Icons.hourglass_empty,
                        const Color(0xFF6366F1),
                        () => _demoFullscreenLoading(),
                      ),
                      _buildExampleCard(
                        'Inline Loading',
                        'Loading pequeño para usar inline',
                        Icons.refresh,
                        const Color(0xFF8B5CF6),
                        () => _demoInlineLoading(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sección 2: Feedback Dialogs
                  _buildSection(
                    '2. Feedback Dialogs',
                    'Mensajes de éxito, error y celebración',
                    [
                      _buildExampleCard(
                        'Success Dialog',
                        'Mensaje de operación exitosa',
                        Icons.check_circle,
                        const Color(0xFF10B981),
                        () => _demoSuccessDialog(),
                      ),
                      _buildExampleCard(
                        'Error Dialog',
                        'Mensaje de error',
                        Icons.error,
                        const Color(0xFFEF4444),
                        () => _demoErrorDialog(),
                      ),
                      _buildExampleCard(
                        'Confetti Celebration',
                        '¡Celebración con confetti!',
                        Icons.celebration,
                        const Color(0xFFFBBF24),
                        () => _demoConfetti(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sección 3: Interactive Buttons
                  _buildSection(
                    '3. Botones Interactivos',
                    'Botones con animaciones al presionar',
                    [
                      _buildLikeButtonExample(),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sección 4: Async Operations
                  _buildSection(
                    '4. Operaciones Asíncronas',
                    'Operaciones con loading y feedback automático',
                    [
                      _buildExampleCard(
                        'Simular Guardado',
                        'Loading → Success automático',
                        Icons.save,
                        const Color(0xFF2D9BF0),
                        () => _demoAsyncSuccess(),
                      ),
                      _buildExampleCard(
                        'Simular Error',
                        'Loading → Error automático',
                        Icons.warning,
                        const Color(0xFFF97316),
                        () => _demoAsyncError(),
                      ),
                      _buildExampleCard(
                        'Simular Firebase',
                        'Operación Firebase real (sin guardar)',
                        Icons.cloud,
                        const Color(0xFF8B5CF6),
                        () => _demoFirebaseOperation(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Contador de éxitos
                  _buildSuccessCounter(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.animation,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ejemplos Prácticos de Rive',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Toca cualquier ejemplo para verlo en acción',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String description, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildExampleCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeButtonExample() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.favorite,
              color: Color(0xFFEF4444),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Like Button Animado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isFavorite ? '¡Te gusta!' : 'Toca el corazón',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          RiveLikeButton(
            isLiked: _isFavorite,
            onTap: () {
              setState(() => _isFavorite = !_isFavorite);
              if (_isFavorite) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Agregado a favoritos!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            size: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCounter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ejemplos Ejecutados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_successCount',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEMOS
  // ============================================================

  void _demoFullscreenLoading() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    _incrementSuccess();
  }

  void _demoInlineLoading() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ejemplo de Loading Inline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const RiveInlineLoading(size: 60),
              const SizedBox(height: 16),
              const Text('Este es un loading pequeño para usar inline'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _incrementSuccess();
                },
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _demoSuccessDialog() async {
    await RiveSuccessDialog.show(
      context,
      title: '¡Éxito!',
      message: 'Este es un mensaje de éxito con animación Rive',
    );
    _incrementSuccess();
  }

  Future<void> _demoErrorDialog() async {
    await RiveErrorDialog.show(
      context,
      title: 'Error',
      message: 'Este es un mensaje de error con animación Rive',
    );
    _incrementSuccess();
  }

  Future<void> _demoConfetti() async {
    await RiveConfettiDialog.show(
      context,
      message: '¡Felicitaciones! 🎉',
    );
    _incrementSuccess();
  }

  Future<void> _demoAsyncSuccess() async {
    await RiveAsyncOperation.execute(
      context: context,
      loadingMessage: 'Guardando datos...',
      successMessage: '¡Datos guardados exitosamente!',
      operation: () async {
        // Simular operación
        await Future.delayed(const Duration(seconds: 2));
      },
    );
    _incrementSuccess();
  }

  Future<void> _demoAsyncError() async {
    await RiveAsyncOperation.execute(
      context: context,
      loadingMessage: 'Intentando conectar...',
      errorMessage: 'No se pudo conectar al servidor',
      operation: () async {
        await Future.delayed(const Duration(seconds: 1));
        throw Exception('Error simulado');
      },
    );
    _incrementSuccess();
  }

  Future<void> _demoFirebaseOperation() async {
    await RiveAsyncOperation.execute(
      context: context,
      loadingMessage: 'Consultando Firebase...',
      successMessage: 'Conexión exitosa con Firebase',
      errorMessage: 'Error al conectar con Firebase',
      operation: () async {
        // Esta es una operación real que solo consulta pero no guarda nada
        final snapshot = await FirebaseFirestore.instance
            .collection('proyectos')
            .limit(1)
            .get();

        return snapshot.docs.length;
      },
    );
    _incrementSuccess();
  }

  void _incrementSuccess() {
    setState(() => _successCount++);
  }
}

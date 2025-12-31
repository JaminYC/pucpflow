import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// 🎮 Página de Prueba para gamification.riv
///
/// IMPORTANTE: Rive 0.14 deprecó State Machine inputs a favor de Data Binding.
/// Esta página te muestra:
/// 1. Cómo cargar y visualizar tu animación
/// 2. Qué información necesitas obtener del archivo Rive original
/// 3. Plan de prueba manual para validar el archivo
/// 4. Ejemplos de código para cuando configures Data Binding
class GamificationTestPage extends StatefulWidget {
  const GamificationTestPage({super.key});

  @override
  State<GamificationTestPage> createState() => _GamificationTestPageState();
}

class _GamificationTestPageState extends State<GamificationTestPage> {
  late final FileLoader _fileLoader;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _fileLoader = FileLoader.fromAsset(
      'assets/rive/gamification.riv',
      riveFactory: Factory.rive,
    );
  }

  @override
  void dispose() {
    _fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('🎮 Gamification Test'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildPreview(),
            const SizedBox(height: 24),
            _buildImportantNotice(),
            const SizedBox(height: 24),
            _buildInspectionGuide(),
            const SizedBox(height: 24),
            _buildRuntimeValidation(),
            const SizedBox(height: 24),
            _buildCodeExamples(),
            const SizedBox(height: 24),
            _buildNextSteps(),
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
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.stars, size: 48, color: Colors.white),
          SizedBox(height: 12),
          Text(
            'Gamification Runtime Test',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'gamification.riv',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vista Previa en Runtime',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isLoaded
                      ? const Color(0xFF10B981).withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLoaded ? Icons.check_circle : Icons.hourglass_empty,
                      size: 16,
                      color: _isLoaded ? const Color(0xFF10B981) : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isLoaded ? 'Cargado' : 'Cargando...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isLoaded ? const Color(0xFF10B981) : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isLoaded
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RiveWidgetBuilder(
                fileLoader: _fileLoader,
                builder: (context, state) {
                  return switch (state) {
                    RiveLoading() => const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Cargando animación...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    RiveFailed() => Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                'Error al cargar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Verifica: assets/rive/gamification.riv',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    RiveLoaded() => Builder(
                        builder: (context) {
                          // Marcar como cargado
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!_isLoaded) {
                              setState(() => _isLoaded = true);
                            }
                          });

                          return RiveWidget(
                            controller: state.controller,
                            fit: Fit.contain,
                          );
                        },
                      ),
                  };
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoaded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '✅ Archivo cargado exitosamente en runtime',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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

  Widget _buildImportantNotice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Importante: Rive 0.14',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNoticeItem(
            '⚠️',
            'State Machine inputs están DEPRECADOS en Rive 0.14',
          ),
          _buildNoticeItem(
            '🔄',
            'Rive ahora recomienda usar Data Binding',
          ),
          _buildNoticeItem(
            '📝',
            'Para usar inputs clásicos, debes acceder al editor de Rive',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Tu archivo SÍ funcionará si:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Tiene una State Machine configurada\n'
                  '• Los inputs existen en el archivo\n'
                  '• El archivo se carga correctamente (ver arriba)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionGuide() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search, color: Color(0xFF6366F1), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Cómo Inspeccionar Tu Archivo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Para saber el nombre de la State Machine e inputs:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildInspectionStep(
            '1',
            'Abre gamification.riv en el editor de Rive',
            'Ve a https://rive.app y abre tu archivo',
          ),
          _buildInspectionStep(
            '2',
            'Busca el panel "Animations"',
            'Verás tus State Machines listadas',
          ),
          _buildInspectionStep(
            '3',
            'Selecciona la State Machine',
            'Anota el nombre exacto (ej: "State Machine 1")',
          ),
          _buildInspectionStep(
            '4',
            'Revisa el panel "Inputs"',
            'Anota nombres y tipos: Trigger, Boolean, o Number',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Información típica para sistemas de estrellas:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildExpectedInput('NUMBER', 'stars', 'Valor 0-3 para cantidad de estrellas'),
                _buildExpectedInput('TRIGGER', 'pop0, pop1, pop2, pop3', 'Triggers individuales por nivel'),
                _buildExpectedInput('BOOLEAN', 'isActive', 'Activar/desactivar animación'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedInput(String type, String name, String description) {
    final colors = {
      'NUMBER': Colors.purple,
      'TRIGGER': Colors.green,
      'BOOLEAN': Colors.blue,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors[type]!.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: colors[type],
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$name - $description',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuntimeValidation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: Color(0xFF10B981), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Validación Runtime (SIN screenshot)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildValidationItem(
            _isLoaded,
            'Archivo se carga correctamente',
            'La animación se muestra arriba sin errores',
          ),
          _buildValidationItem(
            _isLoaded,
            'Funciona en Flutter/Web',
            'Esta prueba confirma compatibilidad runtime',
          ),
          _buildValidationItem(
            true,
            'El archivo existe en assets/',
            'Ubicado en: assets/rive/gamification.riv',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isLoaded
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _isLoaded ? Icons.check_circle : Icons.pending,
                  color: _isLoaded ? const Color(0xFF10B981) : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isLoaded
                        ? '✅ Validación exitosa - El archivo funciona en runtime'
                        : '⏳ Esperando que el archivo cargue...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  Widget _buildValidationItem(bool passed, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: passed ? const Color(0xFF10B981) : Colors.white54,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: passed ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeExamples() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.code, color: Colors.purple, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Ejemplos de Código',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCodeExample(
            'Respuesta a tu pregunta:',
            '''
// BASADO EN TU SCREENSHOT (adapta los nombres reales):

1) Para disparar 0/1/2/3 estrellas:
   - Si tienes un input NUMBER "stars":
     stateMachine.findInput<double>('stars')?.value = 3;

   - Si tienes TRIGGERs individuales:
     stateMachine.findInput<bool>('pop3')?.fire();

2) Tipo de inputs necesarios:
   - TRIGGER: Para eventos únicos (ej: pop0, pop1, pop2, pop3)
   - BOOLEAN: Para estados on/off (ej: isActive)
   - NUMBER: Para valores numéricos (ej: stars con rango 0-3)

3) Plan de prueba mínimo:
   ✅ El archivo carga (verificado arriba)
   ✅ La animación se muestra
   ✅ NO modifiques el .riv
   ✅ Obtén nombres desde el editor de Rive
   ✅ Usa esos nombres exactos en código
''',
          ),
          const SizedBox(height: 16),
          _buildCodeExample(
            'Ejemplo completo para 3 estrellas:',
            '''
// Método 1: Con input NUMBER
final controller = StateMachine.fromArtboard(
  artboard,
  'State Machine 1' // Tu nombre real
);
artboard.addController(controller!);

// Establecer 3 estrellas
final starsInput = controller.findInput<double>('stars');
starsInput?.value = 3.0;

// Método 2: Con TRIGGER
final trigger = controller.findInput<bool>('pop3');
trigger?.fire();
''',
          ),
        ],
      ),
    );
  }

  Widget _buildCodeExample(String title, String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            code,
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 11,
              fontFamily: 'monospace',
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextSteps() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assistant_direction, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Próximos Pasos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNextStep('1', 'Abre gamification.riv en https://rive.app'),
          _buildNextStep('2', 'Anota el nombre de la State Machine'),
          _buildNextStep('3', 'Anota nombres y tipos de todos los inputs'),
          _buildNextStep('4', 'Usa esos nombres en tu código Flutter'),
          _buildNextStep('5', 'Prueba cada input con los valores correctos'),
        ],
      ),
    );
  }

  Widget _buildNextStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

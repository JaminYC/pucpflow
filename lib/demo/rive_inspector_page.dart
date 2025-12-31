import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// 🔍 Inspector de Archivos Rive
///
/// Esta página te permite inspeccionar y probar archivos .riv con State Machines
/// sin necesidad de modificar el archivo original.
///
/// Para tu archivo gamification.riv:
/// - Muestra el nombre de la State Machine
/// - Lista todos los inputs disponibles (triggers, booleans, numbers)
/// - Permite probar cada input en tiempo real
/// - Valida que funcione en Flutter/Web
class RiveInspectorPage extends StatefulWidget {
  final String assetPath;
  final String title;

  const RiveInspectorPage({
    super.key,
    required this.assetPath,
    this.title = 'Rive Inspector',
  });

  @override
  State<RiveInspectorPage> createState() => _RiveInspectorPageState();
}

class _RiveInspectorPageState extends State<RiveInspectorPage> {
  late final FileLoader _fileLoader;

  // Información del archivo
  RiveFile? _riveFile;
  Artboard? _artboard;
  StateMachineController? _controller;

  // Inputs detectados
  List<SMIInput> _allInputs = [];
  List<SMITrigger> _triggers = [];
  List<SMIBool> _booleans = [];
  List<SMINumber> _numbers = [];

  // Estado
  bool _isLoaded = false;
  String? _errorMessage;
  Map<String, dynamic> _inputValues = {};

  @override
  void initState() {
    super.initState();
    _fileLoader = FileLoader.fromAsset(
      widget.assetPath,
      riveFactory: Factory.rive,
    );
    _loadAndInspect();
  }

  Future<void> _loadAndInspect() async {
    try {
      await _fileLoader.load();

      if (_fileLoader.file != null) {
        _riveFile = _fileLoader.file;
        _artboard = _riveFile!.mainArtboard.instance();

        // Buscar State Machines
        if (_artboard != null) {
          // Intentar obtener la primera State Machine
          final stateMachines = _artboard!.animations
              .whereType<StateMachineAnimation>()
              .toList();

          if (stateMachines.isNotEmpty) {
            // Usar la primera State Machine encontrada
            final stateMachineName = stateMachines.first.name;
            _controller = StateMachineController.fromArtboard(
              _artboard!,
              stateMachineName,
            );

            if (_controller != null) {
              _artboard!.addController(_controller!);

              // Obtener todos los inputs
              _allInputs = _controller!.inputs.toList();

              // Clasificar inputs por tipo
              for (var input in _allInputs) {
                if (input is SMITrigger) {
                  _triggers.add(input);
                } else if (input is SMIBool) {
                  _booleans.add(input);
                  _inputValues[input.name] = input.value;
                } else if (input is SMINumber) {
                  _numbers.add(input);
                  _inputValues[input.name] = input.value;
                }
              }
            }
          }
        }

        setState(() => _isLoaded = true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: !_isLoaded
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _errorMessage != null
              ? _buildError()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildPreview(),
                      const SizedBox(height: 24),
                      _buildStateMachineInfo(),
                      const SizedBox(height: 24),
                      _buildInputsSection(),
                      const SizedBox(height: 24),
                      _buildTestGuide(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar archivo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Error desconocido',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
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
          const Icon(Icons.analytics, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'Rive Inspector',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.assetPath.split('/').last,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
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
          const Text(
            'Vista Previa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _artboard != null
                ? Rive(artboard: _artboard!)
                : const Center(
                    child: Icon(Icons.error, color: Colors.red),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateMachineInfo() {
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
          Row(
            children: [
              Icon(Icons.settings, color: Colors.blue.shade300),
              const SizedBox(width: 12),
              const Text(
                'State Machine Info',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Nombre', _controller?.stateMachineName ?? 'No detectada'),
          _buildInfoRow('Total Inputs', '${_allInputs.length}'),
          _buildInfoRow('Triggers', '${_triggers.length}'),
          _buildInfoRow('Booleans', '${_booleans.length}'),
          _buildInfoRow('Numbers', '${_numbers.length}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label + ':',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputsSection() {
    if (_allInputs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange),
        ),
        child: const Column(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 32),
            SizedBox(height: 12),
            Text(
              'No se detectaron inputs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Verifica que tu archivo .riv tenga una State Machine con inputs',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Inputs Detectados',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Triggers
        if (_triggers.isNotEmpty) ...[
          _buildInputTypeSection('Triggers', _triggers.length, Colors.green),
          ..._triggers.map((trigger) => _buildTriggerControl(trigger)),
          const SizedBox(height: 16),
        ],

        // Booleans
        if (_booleans.isNotEmpty) ...[
          _buildInputTypeSection('Booleans', _booleans.length, Colors.blue),
          ..._booleans.map((bool) => _buildBooleanControl(bool)),
          const SizedBox(height: 16),
        ],

        // Numbers
        if (_numbers.isNotEmpty) ...[
          _buildInputTypeSection('Numbers', _numbers.length, Colors.purple),
          ..._numbers.map((number) => _buildNumberControl(number)),
        ],
      ],
    );
  }

  Widget _buildInputTypeSection(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.input, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerControl(SMITrigger trigger) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trigger.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tipo: Trigger (disparo único)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              trigger.fire();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Trigger "${trigger.name}" disparado'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('FIRE'),
          ),
        ],
      ),
    );
  }

  Widget _buildBooleanControl(SMIBool boolInput) {
    final currentValue = _inputValues[boolInput.name] ?? boolInput.value;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boolInput.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tipo: Boolean (true/false) - Valor: $currentValue',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: currentValue,
            onChanged: (value) {
              setState(() {
                _inputValues[boolInput.name] = value;
                boolInput.value = value;
              });
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberControl(SMINumber numberInput) {
    final currentValue = _inputValues[numberInput.name] ?? numberInput.value;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            numberInput.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tipo: Number - Valor actual: ${currentValue.toStringAsFixed(1)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: currentValue,
                  min: 0,
                  max: 5, // Asumiendo rango 0-5 para estrellas
                  divisions: 50,
                  activeColor: Colors.purple,
                  onChanged: (value) {
                    setState(() {
                      _inputValues[numberInput.name] = value;
                      numberInput.value = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentValue.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Botones rápidos para valores específicos
          Wrap(
            spacing: 8,
            children: [0, 1, 2, 3, 4, 5].map((value) {
              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    _inputValues[numberInput.name] = value.toDouble();
                    numberInput.value = value.toDouble();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentValue == value.toDouble()
                      ? Colors.purple
                      : Colors.purple.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: Text('$value'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestGuide() {
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
              const Icon(Icons.checklist, color: Color(0xFF10B981), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Plan de Prueba',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTestStep(
            '1',
            'Verifica que la animación se muestra correctamente',
            _artboard != null,
          ),
          _buildTestStep(
            '2',
            'Prueba cada Trigger haciendo clic en "FIRE"',
            _triggers.isNotEmpty,
          ),
          _buildTestStep(
            '3',
            'Alterna cada Boolean con el switch',
            _booleans.isNotEmpty,
          ),
          _buildTestStep(
            '4',
            'Ajusta cada Number con el slider o botones',
            _numbers.isNotEmpty,
          ),
          _buildTestStep(
            '5',
            'Observa cambios en la vista previa',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildTestStep(String number, String text, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isAvailable
                  ? const Color(0xFF10B981)
                  : Colors.grey.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isAvailable ? Colors.white : Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
          Icon(
            isAvailable ? Icons.check_circle : Icons.info_outline,
            color: isAvailable ? const Color(0xFF10B981) : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// 🎮 Widget de Prueba Rápida para Gamification
///
/// Específicamente para probar el archivo gamification.riv
class GamificationQuickTest extends StatelessWidget {
  const GamificationQuickTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Gamification Quick Test'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RiveInspectorPage(
                  assetPath: 'assets/rive/gamification.riv',
                  title: 'Gamification Inspector',
                ),
              ),
            );
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Inspeccionar gamification.riv'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ),
    );
  }
}

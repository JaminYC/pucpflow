import 'package:flutter/material.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/fix_duplicate_areas.dart';

/// Página temporal para ejecutar la migración de áreas duplicadas
///
/// USO:
/// 1. Navega a esta página desde cualquier parte de la app
/// 2. Presiona el botón "Ejecutar Migración"
/// 3. Espera a que termine
/// 4. Verás el resultado en pantalla
class RunMigrationPage extends StatefulWidget {
  const RunMigrationPage({super.key});

  @override
  State<RunMigrationPage> createState() => _RunMigrationPageState();
}

class _RunMigrationPageState extends State<RunMigrationPage> {
  bool _running = false;
  Map<String, dynamic>? _result;

  Future<void> _executeMigration() async {
    setState(() {
      _running = true;
      _result = null;
    });

    try {
      final fixer = FixDuplicateAreas();
      final result = await fixer.fixAllUserProjects();

      setState(() {
        _result = result;
        _running = false;
      });
    } catch (e) {
      setState(() {
        _result = {
          'error': true,
          'message': e.toString(),
        };
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('🔧 Migración de Áreas', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey.shade900,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.build_circle,
                  color: Colors.blue,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Corrección de Áreas Duplicadas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esta migración corregirá las áreas duplicadas en todos tus proyectos.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                if (_running)
                  Column(
                    children: [
                      const CircularProgressIndicator(color: Colors.blue),
                      const SizedBox(height: 16),
                      const Text(
                        'Ejecutando migración...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  )
                else if (_result == null)
                  ElevatedButton.icon(
                    onPressed: _executeMigration,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Ejecutar Migración'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  _buildResult(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    if (_result == null) return const SizedBox.shrink();

    final hasError = _result!['error'] == true || _result!.containsKey('error');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: hasError
            ? Colors.red.shade900.withValues(alpha: 0.3)
            : Colors.green.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? Colors.red : Colors.green,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasError ? Icons.error : Icons.check_circle,
            color: hasError ? Colors.red : Colors.green,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            hasError ? '❌ Error en la Migración' : '✅ Migración Completada',
            style: TextStyle(
              color: hasError ? Colors.red.shade200 : Colors.green.shade200,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (hasError)
            Text(
              _result!['message']?.toString() ?? 'Error desconocido',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            )
          else
            Column(
              children: [
                _buildStat('Proyectos Corregidos', _result!['proyectosCorregidos']?.toString() ?? '0'),
                const SizedBox(height: 8),
                _buildStat('Tareas Actualizadas', _result!['tareasCorregidas']?.toString() ?? '0'),
                if (_result!['proyectosConErrores'] != null && (_result!['proyectosConErrores'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      '⚠️ ${(_result!['proyectosConErrores'] as List).length} proyectos con errores',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _result = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
            ),
            child: const Text('Ejecutar Nuevamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

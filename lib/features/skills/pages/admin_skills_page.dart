import 'package:flutter/material.dart';
import '../init_skills_db.dart';

/// Página de administrador para inicializar la base de datos de skills
/// SOLO EJECUTAR UNA VEZ al configurar el sistema por primera vez
class AdminSkillsPage extends StatefulWidget {
  const AdminSkillsPage({super.key});

  @override
  State<AdminSkillsPage> createState() => _AdminSkillsPageState();
}

class _AdminSkillsPageState extends State<AdminSkillsPage> {
  bool _isInitializing = false;
  String _message = '';
  bool _initialized = false;

  Future<void> _initializeDatabase() async {
    setState(() {
      _isInitializing = true;
      _message = 'Inicializando base de datos...';
    });

    try {
      await InitSkillsDB().initializeSkills();

      setState(() {
        _isInitializing = false;
        _initialized = true;
        _message = '✅ Base de datos inicializada exitosamente!\n\n'
            'Se han agregado 100+ skills a Firestore.\n'
            'Ahora puedes cerrar esta página y probar cargando un CV.';
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _message = '❌ Error al inicializar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Admin - Inicializar Skills DB',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.shade400.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _initialized ? Icons.check_circle : Icons.storage,
                    size: 80,
                    color: _initialized ? Colors.green.shade400 : Colors.blue.shade400,
                  ),
                ),
                const SizedBox(height: 32),

                // Título
                Text(
                  _initialized
                      ? 'Inicialización Completa'
                      : 'Inicializar Base de Datos de Skills',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Descripción
                if (!_initialized && _message.isEmpty)
                  Text(
                    'Este proceso poblará Firestore con 100+ habilidades profesionales '
                    'organizadas por sectores (Programación, Frontend, Backend, Mobile, etc.).\n\n'
                    '⚠️ SOLO ejecutar UNA VEZ al configurar el sistema.',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),

                // Mensaje de estado
                if (_message.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _initialized
                          ? Colors.green.shade900.withValues(alpha: 0.3)
                          : _message.contains('Error')
                              ? Colors.red.shade900.withValues(alpha: 0.3)
                              : Colors.blue.shade900.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _initialized
                            ? Colors.green.shade400.withValues(alpha: 0.5)
                            : _message.contains('Error')
                                ? Colors.red.shade400.withValues(alpha: 0.5)
                                : Colors.blue.shade400.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _message,
                      style: TextStyle(
                        color: _initialized
                            ? Colors.green.shade200
                            : _message.contains('Error')
                                ? Colors.red.shade200
                                : Colors.blue.shade200,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Botón
                if (!_initialized)
                  ElevatedButton.icon(
                    onPressed: _isInitializing ? null : _initializeDatabase,
                    icon: _isInitializing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.play_arrow, size: 28),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      child: Text(
                        _isInitializing
                            ? 'Inicializando...'
                            : 'Inicializar Base de Datos',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.grey.shade700,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      child: Text(
                        'Cerrar',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
}

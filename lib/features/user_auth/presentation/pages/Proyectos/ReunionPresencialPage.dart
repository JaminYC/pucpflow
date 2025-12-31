import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ResumenYGeneracionTareasPage.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_model.dart';
import 'package:pucpflow/services/wake_word_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ReunionPresencialPage extends StatefulWidget {
  final Proyecto proyecto;
  const ReunionPresencialPage({super.key, required this.proyecto});

  @override
  State<ReunionPresencialPage> createState() => _ReunionPresencialPageState();
}

class _ReunionPresencialPageState extends State<ReunionPresencialPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final WakeWordService _wakeWordService = WakeWordService();

  bool _isListening = false;
  bool _speechDisponible = false;
  bool _sistemaActivo = false; // Iniciar en OFF - el usuario debe presionar "Empezar Reunión"
  String _transcripcionParcial = "";
  List<String> _fragmentos = [];
  Timer? _timer;
  Timer? _restartTimer;
  Timer? _watchdogTimer;
  int _seconds = 0;
  DateTime _lastResultAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _reunionIniciada = false; // Controlar si la reunión ya empezó
  bool _wakeWordEstabaActivo = false; // Para restaurar el estado al salir

  static const Duration _listenFor = Duration(minutes: 10);
  static const Duration _pauseFor = Duration(seconds: 8);
  @override
  void initState() {
    super.initState();
    _detenerWakeWordTemporalmente(); // CRÍTICO: Detener wake word para evitar conflictos
    _cargarTranscripcionGuardada(); // Cargar transcripción previa si existe
    _inicializarSpeech();
  }

  /// Detiene temporalmente el wake word service mientras se usa la transcripción
  Future<void> _detenerWakeWordTemporalmente() async {
    try {
      debugPrint('⏸️ DETENIENDO WAKE WORD COMPLETAMENTE...');

      // Siempre intentar detener, sin importar el estado
      await _wakeWordService.stopDetection();
      await _wakeWordService.stopBackgroundService();

      // Esperar a que se libere completamente
      await Future.delayed(const Duration(milliseconds: 2000));

      _wakeWordEstabaActivo = _wakeWordService.isBackgroundEnabled;
      debugPrint('✅ Wake Word detenido - Esperando liberación del micrófono...');
    } catch (e) {
      debugPrint('⚠️ Error al detener wake word: $e');
    }
  }

  /// Restaura el wake word service al salir de la página
  Future<void> _restaurarWakeWord() async {
    try {
      if (_wakeWordEstabaActivo) {
        debugPrint('▶️ Restaurando Wake Word...');
        await _wakeWordService.startBackgroundService();
      }
    } catch (e) {
      debugPrint('⚠️ Error al restaurar wake word: $e');
    }
  }

  /// Cargar transcripción guardada previamente
  Future<void> _cargarTranscripcionGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'reunion_${widget.proyecto.id}';
    final transcripcionGuardada = prefs.getString(key);

    if (transcripcionGuardada != null && transcripcionGuardada.isNotEmpty) {
      setState(() {
        _fragmentos = transcripcionGuardada.split('|||FRAGMENTO|||');
        _seconds = prefs.getInt('${key}_seconds') ?? 0;
      });

      // Preguntar al usuario si quiere continuar la reunión anterior
      if (mounted) {
        _mostrarDialogoContinuarReunion();
      }
    }
  }

  /// Mostrar diálogo para continuar reunión previa
  void _mostrarDialogoContinuarReunion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Reunión Anterior Encontrada'),
        content: Text(
          'Se encontró una transcripción previa de ${_fragmentos.length} fragmentos.\n\n¿Deseas continuar con esa reunión o empezar una nueva?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _fragmentos.clear();
                _seconds = 0;
              });
              _borrarTranscripcionGuardada();
              Navigator.pop(context);
            },
            child: const Text('Nueva Reunión'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Los datos ya están cargados
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  /// Guardar transcripción automáticamente
  Future<void> _guardarTranscripcionAutomaticamente() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'reunion_${widget.proyecto.id}';
    final transcripcionCompleta = _fragmentos.join('|||FRAGMENTO|||');

    await prefs.setString(key, transcripcionCompleta);
    await prefs.setInt('${key}_seconds', _seconds);
    debugPrint('💾 Transcripción guardada automáticamente');
  }

  /// Borrar transcripción guardada
  Future<void> _borrarTranscripcionGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'reunion_${widget.proyecto.id}';
    await prefs.remove(key);
    await prefs.remove('${key}_seconds');
  }

  Future<void> _inicializarSpeech() async {
    try {
      debugPrint('🎤 Inicializando speech EXCLUSIVO para ReunionPresencialPage...');

      // Ya esperamos 2 segundos en _detenerWakeWordTemporalmente,
      // solo un pequeño delay adicional
      await Future.delayed(const Duration(milliseconds: 500));

      // Forzar detención de cualquier speech activo
      try {
        await _speech.cancel(); // Cancel es más agresivo que stop
      } catch (e) {
        debugPrint('⚠️ Error al cancelar speech anterior: $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Inicializar con configuración limpia - INSTANCIA NUEVA
      final disponible = await _speech.initialize(
        onStatus: _manejarEstado,
        onError: (error) {
          debugPrint('❌ Error speech reunion: ${error.errorMsg}');
          // Solo reintentar si el sistema está activo y no es un error de wake word
          if (_sistemaActivo && mounted && !_speech.isListening && !error.errorMsg.contains('Wake')) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (_sistemaActivo && mounted) {
                debugPrint('🔄 Reintentando después de error...');
                _reiniciarEscucha();
              }
            });
          }
        },
        debugLogging: false,
        finalTimeout: const Duration(seconds: 5), // Timeout más corto para reiniciar rápido
      );

      if (mounted) {
        setState(() {
          _speechDisponible = disponible;
        });
      }

      if (_speechDisponible) {
        debugPrint('✅ Speech EXCLUSIVO inicializado correctamente para reuniones');
      } else {
        debugPrint('❌ No se pudo inicializar speech');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No se pudo activar el micrófono. Verifica los permisos."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Excepción al inicializar speech: $e');
      if (mounted) {
        setState(() {
          _speechDisponible = false;
        });
      }
    }
  }



  void _manejarEstado(String status) {
    debugPrint('[REUNION] status: $status');
    debugPrint('[REUNION] activo=$_sistemaActivo listening=$_isListening mounted=$mounted speechListening=${_speech.isListening}');

    if (status == "done" || status == "notListening") {
      debugPrint('[REUNION] mic stopped - status: $status');

      if (mounted) {
        setState(() => _isListening = false);
      }

      _guardarParcial();

      if (_sistemaActivo && mounted) {
        debugPrint('[REUNION] system active - scheduling restart');
        _scheduleRestart();
      } else {
        debugPrint('[REUNION] system inactive - no restart');
      }
    } else if (status == "listening") {
      debugPrint('[REUNION] listening active');
      _restartTimer?.cancel();
      if (mounted) {
        setState(() => _isListening = true);
      }
    } else {
      debugPrint('[REUNION] unknown status: $status');
    }
  }

  void _scheduleRestart({Duration delay = const Duration(milliseconds: 350)}) {
    _restartTimer?.cancel();
    if (!_sistemaActivo || !_speechDisponible) {
      return;
    }

    _restartTimer = Timer(delay, () {
      if (!mounted || !_sistemaActivo) {
        return;
      }

      Future<void>(() async {
        try {
          await _speech.cancel();
        } catch (e) {
          debugPrint('[REUNION] cancel error before restart: $e');
        }

        if (!mounted || !_sistemaActivo) {
          return;
        }

        await Future.delayed(const Duration(milliseconds: 200));

        if (!_speech.isListening) {
          _iniciarEscucha();
        }
      });
    });
  }

  void _reiniciarEscucha() {
    if (!_sistemaActivo) {
      debugPrint('[REUNION] no restart - system inactive');
      return;
    }

    _scheduleRestart(delay: const Duration(milliseconds: 200));
  }

  void _iniciarEscucha() async {
    if (!_sistemaActivo || !mounted || !_speechDisponible) {
      debugPrint('⚠️ [REUNION] No se puede iniciar escucha: activo=$_sistemaActivo, mounted=$mounted, disponible=$_speechDisponible');
      return;
    }

    // Si ya está escuchando, no iniciar de nuevo
    if (_speech.isListening) {
      debugPrint('⚠️ [REUNION] Speech ya está escuchando, no reiniciar');
      return;
    }

    try {
      debugPrint('🎙️ [REUNION] ===== INICIANDO ESCUCHA =====');

      // CLAVE: No usar await aquí para que no bloquee
      _lastResultAt = DateTime.now();
      _speech.listen(
        localeId: 'es_PE',
        listenFor: _listenFor,
        pauseFor: _pauseFor,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
          autoPunctuation: true,
          onDevice: false, // Usar reconocimiento en la nube para mejor precisión
        ),
        onResult: (result) {
          _lastResultAt = DateTime.now();
          if (mounted) {
            setState(() {
              _transcripcionParcial = result.recognizedWords;
              if (result.finalResult) {
                _guardarParcial();
              }
            });
          }
        },
      ).then((started) {
        debugPrint('🎙️ [REUNION] .then() callback - started: $started, mounted: $mounted');
        if ((started == true || _speech.isListening) && mounted) {
          // Timer ya se inició en _toggleSistema, solo actualizar estado
          setState(() => _isListening = true);
          debugPrint('✅ [REUNION] Micrófono ACTIVO - escuchando continuamente');
        } else {
          debugPrint('❌ [REUNION] No se pudo iniciar el micrófono - started: $started');
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      }).catchError((error) {
        debugPrint('❌ [REUNION] Error en .then(): $error');
        if (mounted) {
          setState(() => _isListening = false);
        }
      });
    } catch (e) {
      debugPrint('❌ Error al iniciar escucha: $e');
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  void _guardarParcial() {
    if (_transcripcionParcial.trim().isNotEmpty) {
      _fragmentos.add(_transcripcionParcial.trim());
      _transcripcionParcial = "";
      // Guardar automáticamente cada vez que se agrega un fragmento
      _guardarTranscripcionAutomaticamente();
    }
  }

  void _toggleSistema() async {
    if (_sistemaActivo) {
      // Apagar sistema (OFF) - PAUSAR
      debugPrint('⏸️ PAUSANDO sistema - Deteniendo micrófono y timer');
      setState(() {
        _sistemaActivo = false;
        _isListening = false;
      });
      _restartTimer?.cancel();
      _watchdogTimer?.cancel();
      await _speech.cancel();
      _detenerTimer();
      _guardarParcial();
      _guardarTranscripcionAutomaticamente();
    } else {
      // Encender sistema (ON) - EMPEZAR/REANUDAR
      debugPrint('▶️ ACTIVANDO sistema - Iniciando micrófono y timer');
      setState(() {
        _sistemaActivo = true;
        _reunionIniciada = true;
      });

      // CRÍTICO: Iniciar el timer AQUÍ, una sola vez cuando se activa el sistema
      _iniciarTimer();
      _iniciarWatchdog();

      // Luego iniciar la escucha
      _iniciarEscucha();
    }
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  void _detenerTimer() {
    _timer?.cancel();
  }

  void _iniciarWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_sistemaActivo || !_speechDisponible) {
        return;
      }
      final lastResultAge = DateTime.now().difference(_lastResultAt);
      if (_speech.isListening && lastResultAge <= const Duration(seconds: 12)) {
        return;
      }
      if (_restartTimer?.isActive ?? false) {
        return;
      }
      debugPrint('[REUNION] watchdog - restarting listen');
      _scheduleRestart();
    });
  }

  void _finalizarReunion() async {
    // Apagar el sistema antes de finalizar
    if (_sistemaActivo) {
      setState(() {
        _sistemaActivo = false;
        _isListening = false;
      });
      _restartTimer?.cancel();
      _watchdogTimer?.cancel();
      await _speech.cancel();
      _detenerTimer();
      _guardarParcial();
    }

    final textoCompleto = [..._fragmentos, _transcripcionParcial].join(". ");

    if (!mounted) return;

    if (textoCompleto.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay contenido para procesar.")),
      );
      return;
    }

    // Borrar la transcripción guardada ya que se va a procesar
    await _borrarTranscripcionGuardada();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResumenYGeneracionTareasPage(
          texto: textoCompleto,
          proyecto: widget.proyecto,
        ),
      ),
    );
  }

  String _formatoTiempo(int segundos) {
    final minutos = (segundos ~/ 60).toString().padLeft(2, '0');
    final seg = (segundos % 60).toString().padLeft(2, '0');
    return "$minutos:$seg";
  }

  @override
  void dispose() {
    debugPrint('🗑️ Disposing ReunionPresencialPage');
    _detenerTimer();
    _restartTimer?.cancel();
    _watchdogTimer?.cancel();
    _sistemaActivo = false;

    // Detener speech completamente
    if (_speech.isListening) {
      _speech.cancel();
    }

    // Guardar automáticamente al salir
    if (_fragmentos.isNotEmpty || _transcripcionParcial.isNotEmpty) {
      _guardarParcial();
      _guardarTranscripcionAutomaticamente();
    }

    // CRÍTICO: Restaurar wake word al salir
    _restaurarWakeWord();

    super.dispose();
    debugPrint('✅ ReunionPresencialPage disposed');
  }

  /// Manejar el botón de retroceso para evitar pérdida de datos
  Future<bool> _onWillPop() async {
    // Si hay datos sin procesar, preguntar antes de salir
    if (_fragmentos.isNotEmpty || _transcripcionParcial.isNotEmpty) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Datos sin Procesar'),
          content: const Text(
            'Tienes transcripción guardada que no ha sido procesada.\n\n'
            '¿Qué deseas hacer?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                await _guardarTranscripcionAutomaticamente();
                if (mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Guardar y Salir'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _borrarTranscripcionGuardada();
                if (mounted) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Descartar y Salir'),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final textoFinal = [..._fragmentos, _transcripcionParcial].join(".\n\n");

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF050915),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Reunión Presencial", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0E152E), Color(0xFF111C3D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -30,
            child: _blurCircle(180, Colors.cyanAccent.withValues(alpha: 0.12)),
          ),
          Positioned(
            bottom: -80,
            left: -20,
            child: _blurCircle(200, Colors.pinkAccent.withValues(alpha: 0.12)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _statusChip(
                        _sistemaActivo
                          ? "🔴 Grabando"
                          : (_reunionIniciada ? "⏸️ Pausada" : "⚫ Reunión Inactiva"),
                        _sistemaActivo
                          ? Colors.redAccent
                          : (_reunionIniciada ? Colors.orangeAccent : Colors.grey)
                      ),
                      const SizedBox(width: 8),
                      _statusChip("Proyecto: ${widget.proyecto.nombre}", Colors.cyanAccent),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              _formatoTiempo(_seconds),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5), // Fondo más oscuro para mejor contraste
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24, width: 1.5),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              textoFinal.isEmpty ? "Aquí verás la transcripción en vivo..." : textoFinal,
                              style: const TextStyle(
                                color: Colors.white, // Blanco brillante
                                fontSize: 16, // Un poco más grande
                                height: 1.6,
                                fontWeight: FontWeight.w500, // Peso medio para mejor legibilidad
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildControls(),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildControls() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _pillButton(
          icon: _sistemaActivo ? Icons.pause : Icons.play_arrow,
          label: _sistemaActivo
            ? "Pausar Reunión"
            : (_reunionIniciada ? "Reanudar" : "Empezar Reunión"),
          color: _sistemaActivo ? Colors.orangeAccent : Colors.greenAccent,
          onTap: _speechDisponible ? _toggleSistema : null,
        ),
        _pillButton(
          icon: Icons.copy,
          label: "Copiar",
          color: Colors.blueAccent,
          onTap: () {
            final textoFinal = [..._fragmentos, _transcripcionParcial].join(".\n\n");
            Clipboard.setData(ClipboardData(text: textoFinal));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Copiado al portapapeles")),
            );
          },
        ),
        _pillButton(
          icon: Icons.paste,
          label: "Pegar texto",
          color: Colors.purpleAccent,
          onTap: _dialogoPegarTexto,
        ),
        _pillButton(
          icon: Icons.check_circle,
          label: "Finalizar",
          color: Colors.tealAccent,
          onTap: _finalizarReunion,
        ),
      ],
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6), // Fondo más oscuro para mejor contraste
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2), // Borde más grueso
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white, // Texto blanco para mejor legibilidad
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _pillButton({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.16),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Future<void> _dialogoPegarTexto() async {
    String textoPegado = "";

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Pegar Transcripción Manual"),
          content: TextField(
            maxLines: 10,
            onChanged: (value) => textoPegado = value,
            decoration: const InputDecoration(
              hintText: "Pega aquí el texto completo de la reunión...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                if (textoPegado.trim().length > 20) {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResumenYGeneracionTareasPage(
                        texto: textoPegado.trim(),
                        proyecto: widget.proyecto,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("El texto es demasiado corto para procesar.")),
                  );
                }
              },
              child: const Text("Procesar"),
            ),
          ],
        );
      },
    );
  }
}

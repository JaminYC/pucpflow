import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pucpflow/providers/pomodoro_provider.dart';

/// Overlay flotante del Pomodoro que se muestra en todas las pantallas
///
/// Se puede arrastrar, minimizar/expandir y controlar el timer desde cualquier pantalla
class PomodoroFloatingOverlay extends StatefulWidget {
  const PomodoroFloatingOverlay({Key? key}) : super(key: key);

  @override
  State<PomodoroFloatingOverlay> createState() => _PomodoroFloatingOverlayState();
}

class _PomodoroFloatingOverlayState extends State<PomodoroFloatingOverlay> {
  Offset _position = const Offset(20, 100); // Posición inicial
  bool _isExpanded = false; // Estado expandido/minimizado
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroProvider>(
      builder: (context, pomodoro, child) {
        return Stack(
          children: [
            Positioned(
              left: _position.dx,
              top: _position.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _isDragging = true;
                    _position = Offset(
                      (_position.dx + details.delta.dx).clamp(0, MediaQuery.of(context).size.width - 80),
                      (_position.dy + details.delta.dy).clamp(0, MediaQuery.of(context).size.height - 80),
                    );
                  });
                },
                onPanEnd: (_) {
                  setState(() => _isDragging = false);
                },
                onTap: () {
                  setState(() => _isExpanded = !_isExpanded);
                },
                child: Material(
                  elevation: _isDragging ? 12 : 6,
                  borderRadius: BorderRadius.circular(_isExpanded ? 16 : 40),
                  color: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: _isExpanded ? 280 : 80,
                    height: _isExpanded ? 320 : 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: pomodoro.isWorkInterval
                            ? [Colors.red.shade400, Colors.red.shade700]
                            : [Colors.green.shade400, Colors.green.shade700],
                      ),
                      borderRadius: BorderRadius.circular(_isExpanded ? 16 : 40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isExpanded ? _buildExpandedView(pomodoro) : _buildMinimizedView(pomodoro),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMinimizedView(PomodoroProvider pomodoro) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Indicador circular de progreso
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pomodoro.progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Text(
                  '${pomodoro.remainingSeconds ~/ 60}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Icono de estado
          Icon(
            pomodoro.isRunning ? Icons.play_arrow : Icons.pause,
            color: Colors.white,
            size: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView(PomodoroProvider pomodoro) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Header con indicador de modo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pomodoro.isWorkInterval ? '🎯 TRABAJO' : '☕ DESCANSO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () {
                  setState(() => _isExpanded = false);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Timer circular grande
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pomodoro.progress,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pomodoro.formattedTime,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pomodoro.isWorkInterval ? 'Enfócate' : 'Relájate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tarea actual
          Text(
            pomodoro.currentTask,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 12),

          // Controles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón reset
              _buildControlButton(
                icon: Icons.refresh,
                onPressed: pomodoro.resetTimer,
                tooltip: 'Reiniciar',
              ),

              const SizedBox(width: 12),

              // Botón play/pause principal
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    pomodoro.isRunning ? Icons.pause : Icons.play_arrow,
                    color: pomodoro.isWorkInterval ? Colors.red : Colors.green,
                    size: 28,
                  ),
                  onPressed: pomodoro.isRunning ? pomodoro.pauseTimer : pomodoro.startTimer,
                  tooltip: pomodoro.isRunning ? 'Pausar' : 'Iniciar',
                ),
              ),

              const SizedBox(width: 12),

              // Botón skip
              _buildControlButton(
                icon: Icons.skip_next,
                onPressed: pomodoro.skipInterval,
                tooltip: 'Saltar',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Contador de pomodoros completados
          Text(
            '🍅 ${pomodoro.completedPomodoros} completados',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

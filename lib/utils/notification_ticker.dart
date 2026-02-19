import 'dart:async';
import 'package:flutter/material.dart';

// ─── Modelo de mensaje del ticker ───────────────────────────────────────────
class TickerMessage {
  final String texto;
  final String tipo; // 'ceo' | 'fact' | 'birthday' | 'alert'
  const TickerMessage(this.texto, this.tipo);
}

// ─── Widget principal ────────────────────────────────────────────────────────
class NotificationTicker extends StatefulWidget {
  final List<TickerMessage>? messages;

  const NotificationTicker({super.key, this.messages});

  // Mensajes por defecto — comentados temporalmente, solo se usan cumpleaños
  static const List<TickerMessage> defaultMessages = [
    // TickerMessage(
    //   '🎯 Mensaje del CEO: Sigamos construyendo el futuro juntos, equipo Vastoria.',
    //   'ceo',
    // ),
    // TickerMessage(
    //   '💡 ¿Sabías que? El 73% de los equipos más productivos usan herramientas de gestión diaria.',
    //   'fact',
    // ),
    // TickerMessage(
    //   '🚀 Vastoria Flow v2.0 está llegando — nuevas funciones de IA en camino.',
    //   'ceo',
    // ),
    // TickerMessage(
    //   '📊 Tip: Completa tu briefing diario para maximizar tu productividad.',
    //   'fact',
    // ),
    // TickerMessage(
    //   '✨ Vastoria: Construyendo el ecosistema de soluciones más completo del Perú.',
    //   'ceo',
    // ),
    // TickerMessage(
    //   '🌐 Nuestra misión: Democratizar el acceso a herramientas de gestión de clase mundial.',
    //   'fact',
    // ),
    // TickerMessage(
    //   '🏆 CEO: Cada tarea completada nos acerca un paso más a nuestros sueños colectivos.',
    //   'ceo',
    // ),
  ];

  @override
  State<NotificationTicker> createState() => _NotificationTickerState();
}

class _NotificationTickerState extends State<NotificationTicker> {
  late final ScrollController _scrollController;
  Timer? _timer;
  bool _scrolling = false;

  List<TickerMessage> get _messages =>
      widget.messages ?? NotificationTicker.defaultMessages;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Esperar que el layout esté listo antes de iniciar el scroll
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    if (_scrolling) return;
    _scrolling = true;
    _timer = Timer.periodic(const Duration(milliseconds: 28), (_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      if (current >= max) {
        // Reinicia sin animación para efecto loop suave
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(current + 1.0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Color _colorForTipo(String tipo) {
    switch (tipo) {
      case 'ceo':
        return const Color(0xFFFFD700);
      case 'birthday':
        return const Color(0xFFFF6B9D);
      case 'alert':
        return const Color(0xFFF97316);
      case 'fact':
      default:
        return const Color(0xFF06B6D4);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sin repetición — cada mensaje aparece una sola vez
    final items = <Widget>[];
    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];

      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            msg.texto,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );

      // Separador entre mensajes
      if (i < _messages.length - 1) {
        items.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '·',
              style: TextStyle(
                color: Colors.black26,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        );
      }
    }

    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Badge "VASTORIA" fijo a la izquierda
          Container(
            width: 78,
            height: 36,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: const Center(
              child: Text(
                'VASTORIA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),

          // Separador vertical
          Container(
            width: 1,
            height: 36,
            color: const Color(0xFFE5E7EB),
          ),

          // Ticker scrollable
          Expanded(
            child: ClipRect(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 16),
                      ...items,
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

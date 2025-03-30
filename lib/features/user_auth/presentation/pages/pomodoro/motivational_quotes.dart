import 'dart:async';
import 'package:flutter/material.dart';

class MotivationalQuoteWidget extends StatefulWidget {
  const MotivationalQuoteWidget({super.key});

  @override
  State<MotivationalQuoteWidget> createState() => _MotivationalQuoteWidgetState();
}

class _MotivationalQuoteWidgetState extends State<MotivationalQuoteWidget> {
  final List<String> _quotes = [
    "✨ Cada día es una nueva oportunidad.",
    "🚀 Hazlo con pasión o no lo hagas.",
    "🌱 El progreso vale más que la perfección.",
    "🔥 Cree en ti, incluso cuando otros no lo hagan.",
    "🎯 Enfócate. Respira. Avanza.",
    "🧠 Hoy es un gran día para aprender algo nuevo.",
    "💪 La disciplina supera a la motivación.",
  ];

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startRotation();
  }

  void _startRotation() {
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _quotes.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Center(
        child: Text(
          _quotes[_currentIndex],
          style: const TextStyle(
            fontSize: 18,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

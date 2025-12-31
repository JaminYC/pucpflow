import 'dart:async';
import 'package:flutter/foundation.dart';

/// Servicio para detección de wake word
class WakeWordService {
  static final WakeWordService _instance = WakeWordService._internal();
  factory WakeWordService() => _instance;
  WakeWordService._internal();

  final StreamController<void> _wakeWordController = StreamController<void>.broadcast();
  Stream<void> get wakeWordStream => _wakeWordController.stream;

  bool _isListening = false;
  bool get isListening => _isListening;

  bool _isBackgroundEnabled = false;
  bool get isBackgroundEnabled => _isBackgroundEnabled;

  Future<void> initialize() async {
    debugPrint('✅ WakeWordService inicializado');
  }

  Future<void> startListening() async {
    _isListening = true;
    debugPrint('🎤 Wake word listening started');
  }

  Future<void> stopListening() async {
    _isListening = false;
    debugPrint('🔇 Wake word listening stopped');
  }

  Future<void> startBackgroundService() async {
    _isBackgroundEnabled = true;
    debugPrint('🔄 Wake word background service started');
  }

  Future<void> stopBackgroundService() async {
    _isBackgroundEnabled = false;
    debugPrint('⏹️ Wake word background service stopped');
  }

  Future<void> stopDetection() async {
    await stopListening();
  }

  void setProcessing(bool isProcessing) {
    debugPrint('🔄 Processing: $isProcessing');
  }

  void setADANSpeaking(bool isSpeaking) {
    debugPrint('🗣️ ADAN Speaking: $isSpeaking');
  }

  void dispose() {
    _wakeWordController.close();
  }
}

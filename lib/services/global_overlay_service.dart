import 'dart:async';
import 'package:flutter/material.dart';

/// Servicio Singleton para gestionar overlays globales (Pomodoro, ADAN, etc.)
class GlobalOverlayService {
  static final GlobalOverlayService _instance = GlobalOverlayService._internal();
  factory GlobalOverlayService() => _instance;
  GlobalOverlayService._internal();

  // Pomodoro state
  bool _pomodoroIsRunning = false;
  int _pomodoroRemainingSeconds = 1500;
  bool _pomodoroIsWorkInterval = true;

  bool get pomodoroIsRunning => _pomodoroIsRunning;
  int get pomodoroRemainingSeconds => _pomodoroRemainingSeconds;
  bool get pomodoroIsWorkInterval => _pomodoroIsWorkInterval;

  // Basic methods
  void updatePomodoroState({
    required bool isRunning,
    required int remainingSeconds,
    required bool isWorkInterval,
  }) {
    _pomodoroIsRunning = isRunning;
    _pomodoroRemainingSeconds = remainingSeconds;
    _pomodoroIsWorkInterval = isWorkInterval;
  }
}

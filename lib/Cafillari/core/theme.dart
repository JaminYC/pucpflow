import 'package:flutter/material.dart';

/// Tema profesional para Cafillari - Sistema CPS de Secado de Café
class CafillariTheme {
  // Colores principales
  static const Color primaryBrown = Color(0xFF5D4037);
  static const Color darkBrown = Color(0xFF3E2723);
  static const Color lightBrown = Color(0xFF8D6E63);
  static const Color coffeeGold = Color(0xFFFFB300);
  static const Color coffeeOrange = Color(0xFFFF8F00);

  // Colores de fondo
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color backgroundCard = Color(0xFF16213E);
  static const Color backgroundLight = Color(0xFF0F3460);

  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Colores de sensores
  static const Color temperature = Color(0xFFE53935);
  static const Color humidity = Color(0xFF1E88E5);
  static const Color airflow = Color(0xFF43A047);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBrown, darkBrown],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [backgroundCard, backgroundLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient temperatureGradient = LinearGradient(
    colors: [Color(0xFFFF5722), Color(0xFFE91E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient humidityGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppColors {
  static const Color background = Color(0xFF1A1A2E);
  static const Color primary = Color(0xFF5D4037);
  static const Color secondary = Color(0xFFFFB300);
  static const Color accent = Color(0xFF00BCD4);
  static const Color surface = Color(0xFF16213E);
  static const Color cardBg = Color(0xFF0F3460);
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.2,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: Colors.white70,
    letterSpacing: 0.5,
  );

  static const TextStyle cardTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
    color: Colors.white,
  );

  static const TextStyle sensorValue = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle sensorLabel = TextStyle(
    fontSize: 12,
    color: Colors.white60,
    letterSpacing: 0.5,
  );

  static const TextStyle kpiValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}

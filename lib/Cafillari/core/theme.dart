import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFFAF9F6); // Fondo crema
  static const Color primary = Color(0xFF6B4226); // Marrón café
  static const Color secondary = Color(0xFFFDB813); // Dorado amanecer
  static const Color accent = Color(0xFF1976D2); // Azul tecnología
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: Colors.black54,
  );

  static const TextStyle cardTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );
}

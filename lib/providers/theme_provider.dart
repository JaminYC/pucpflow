import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // FLOW Color Palette - Dark Mode
  static const Color darkBackground = Color(0xFF0A0E27);
  static const Color darkCard = Color(0xFF1A1F3A);
  static const Color darkBorder = Color(0xFF2D3347);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB8BCC8);

  // FLOW Color Palette - Light Mode
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Accent Colors (same for both themes)
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF97316);

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
    notifyListeners();
  }

  // Dynamic color getters
  Color get backgroundColor => _isDarkMode ? darkBackground : lightBackground;
  Color get cardColor => _isDarkMode ? darkCard : lightCard;
  Color get borderColor => _isDarkMode ? darkBorder : lightBorder;
  Color get textPrimaryColor => _isDarkMode ? darkTextPrimary : lightTextPrimary;
  Color get textSecondaryColor => _isDarkMode ? darkTextSecondary : lightTextSecondary;

  // Gradient getters
  LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accentPurple, accentBlue],
      );

  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentPurple.withOpacity(0.2),
          accentBlue.withOpacity(0.1),
          backgroundColor,
        ],
      );

  // Box shadow getter
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.1),
          blurRadius: 24,
          spreadRadius: -8,
          offset: const Offset(0, 8),
        ),
      ];
}

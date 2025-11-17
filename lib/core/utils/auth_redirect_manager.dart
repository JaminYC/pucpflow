import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Gestor de redirección de autenticación
/// Maneja el flujo de login y redirección a la app correcta
class AuthRedirectManager {
  static const String _lastAppKey = 'last_accessed_app';
  static const String _redirectUrlKey = 'redirect_after_login';

  /// Guarda la app a la que el usuario quería acceder antes de hacer login
  static Future<void> saveIntendedApp(String appName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAppKey, appName);
  }

  /// Obtiene la última app a la que el usuario quería acceder
  static Future<String?> getIntendedApp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastAppKey);
  }

  /// Limpia la app guardada
  static Future<void> clearIntendedApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastAppKey);
  }

  /// Guarda la URL completa de redirección
  static Future<void> saveRedirectUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_redirectUrlKey, url);
  }

  /// Obtiene la URL de redirección
  static Future<String?> getRedirectUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_redirectUrlKey);
  }

  /// Limpia la URL de redirección
  static Future<void> clearRedirectUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_redirectUrlKey);
  }

  /// Determina a dónde redirigir después del login
  static Future<String> getPostLoginDestination() async {
    // 1. Verificar si hay una app específica guardada
    final intendedApp = await getIntendedApp();
    if (intendedApp != null) {
      await clearIntendedApp();
      return _getAppRoute(intendedApp);
    }

    // 2. Verificar si hay URL de redirección
    final redirectUrl = await getRedirectUrl();
    if (redirectUrl != null) {
      await clearRedirectUrl();
      return redirectUrl;
    }

    // 3. Por defecto, ir a la última app usada o Flow
    final prefs = await SharedPreferences.getInstance();
    final lastApp = prefs.getString('user_last_used_app') ?? 'flow';
    return _getAppRoute(lastApp);
  }

  /// Guarda la última app usada por el usuario
  static Future<void> saveLastUsedApp(String appName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_last_used_app', appName);
  }

  /// Obtiene la ruta interna de una app
  static String _getAppRoute(String appName) {
    switch (appName.toLowerCase()) {
      case 'flow':
        return '/home';
      case 'innova':
        return '/innova';
      case 'cafillari':
        return '/cafillari';
      case 'vitakua':
        return '/vitakua';
      default:
        return '/home';
    }
  }

  /// Detecta la app actual desde el subdominio (solo web)
  static String? getCurrentAppFromUrl() {
    if (!kIsWeb) return null;

    final host = Uri.base.host.toLowerCase();

    if (host.contains('flow.')) return 'flow';
    if (host.contains('innova.')) return 'innova';
    if (host.contains('cafillari.')) return 'cafillari';
    if (host.contains('vitakua.')) return 'vitakua';

    return null;
  }

  /// Verifica si el usuario está autenticado
  static bool isAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  /// Obtiene el usuario actual
  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  /// Cierra sesión en todo el ecosistema
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await clearIntendedApp();
    await clearRedirectUrl();
  }
}

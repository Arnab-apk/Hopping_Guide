import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing dynamic app theme switching (Dark Mode <-> Light Mode)
/// with persistent storage in SharedPreferences.
class ThemeService extends ChangeNotifier {
  ThemeService({ThemeMode initialMode = ThemeMode.dark}) : _themeMode = initialMode;

  static const String _prefKey = 'app_theme_mode';
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static Future<ThemeService> create() async {
    final service = ThemeService();
    await service.init();
    return service;
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedMode == 'system') {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final nextMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String value = 'dark';
      if (mode == ThemeMode.light) {
        value = 'light';
      } else if (mode == ThemeMode.system) {
        value = 'system';
      }
      await prefs.setString(_prefKey, value);
    } catch (_) {}
  }
}

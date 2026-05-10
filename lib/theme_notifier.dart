import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark, amoled }

class ThemeNotifier extends ChangeNotifier {
  static const String _themePreferenceKey = 'themeMode';

  AppThemeMode _currentTheme;

  AppThemeMode get currentTheme => _currentTheme;
  ThemeMode get themeMode {
    switch (_currentTheme) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
      case AppThemeMode.amoled:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  ThemeNotifier({required AppThemeMode initialTheme})
    : _currentTheme = initialTheme;

  Future<void> setTheme(AppThemeMode? value) async {
    final themeToSet = value ?? AppThemeMode.system;
    if (_currentTheme == themeToSet) return;

    _currentTheme = themeToSet;
    notifyListeners();
    await _saveTheme();
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, _currentTheme.name);
    } catch (e) {
      print("Failed to save theme: $e");
    }
  }

  static Future<AppThemeMode> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themePreferenceKey);
      return AppThemeMode.values.firstWhere(
        (e) => e.name == themeName,
        orElse: () => AppThemeMode.system,
      );
    } catch (e) {
      print("Failed to load theme: $e");
      return AppThemeMode.system;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKeyStorage = 'app_theme_mode';
  static const _secureStorage = FlutterSecureStorage();
  
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final savedTheme = await _secureStorage.read(key: _themeKeyStorage);
      _isDarkMode = savedTheme == 'dark';
      notifyListeners();
    } catch (e) {
      print('[ThemeProvider] Erreur chargement thème: $e');
      _isDarkMode = false;
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _secureStorage.write(
      key: _themeKeyStorage,
      value: _isDarkMode ? 'dark' : 'light',
    );
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _secureStorage.write(
        key: _themeKeyStorage,
        value: _isDarkMode ? 'dark' : 'light',
      );
      notifyListeners();
    }
  }
}

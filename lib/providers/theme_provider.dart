// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const THEME_STATUS = "THEME_STATUS";
  bool _darkTheme = false;

  bool get isDarkTheme => _darkTheme;

  ThemeProvider() {
    _loadTheme();
  }

  // Метод за смяна на темата
  Future<void> setDarkTheme(bool value) async {
    _darkTheme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(THEME_STATUS, value);
    // Уведомява всички "слушатели", че има промяна
    notifyListeners();
  }

  // Метод за зареждане на запазената тема при стартиране
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _darkTheme = prefs.getBool(THEME_STATUS) ?? false;
    notifyListeners();
  }
}
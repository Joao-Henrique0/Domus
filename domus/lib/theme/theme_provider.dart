import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:domus/theme/theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = lightMode;

  ThemeData get themeData => _themeData;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme') ?? 'lightMode';
    _themeData = themeName == 'darkMode' ? darkMode : lightMode;
    notifyListeners();
  }

  void setTheme(ThemeData themeData) async {
    _themeData = themeData;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('theme', themeData == darkMode ? 'darkMode' : 'lightMode');
  }

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    final newTheme = _themeData == lightMode ? darkMode : lightMode;
    setTheme(newTheme);
  }
}

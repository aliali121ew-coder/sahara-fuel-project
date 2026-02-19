import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDark = !_isDark;
    // Keep legacy AppColors in sync during migration
    AppColors.isDark = _isDark;
    notifyListeners();
  }

  void setDark(bool value) {
    _isDark = value;
    AppColors.isDark = value;
    notifyListeners();
  }
}

import 'package:flutter/cupertino.dart';
import 'package:riverpod/riverpod.dart';

enum AppThemeMode { light, dark, system }

// NotifierProvider voor thema beheer (Riverpod 3.x compatible)
final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    return AppThemeMode.system;
  }

  void setTheme(AppThemeMode mode) {
    state = mode;
  }
}

class AppColors {
  // Light Theme Colors
  static const lightScaffoldBackground = Color(0xFFF8FAF8);
  static const lightCardBackground = Color(0xFFFFFFFF);
  static const lightPrimary = Color(0xFF0F8A22);
  static const lightText = Color(0xFF1B3D1B);
  static const lightBorder = Color(0xFFDDE5DD);

  // Dark Theme Colors
  static const darkScaffoldBackground = Color(0xFF121212);
  static const darkCardBackground = Color(0xFF1E1E1E);
  static const darkPrimary = Color(0xFF4CAF50);
  static const darkText = Color(0xFFE0E0E0);
  static const darkBorder = Color(0xFF333333);
}

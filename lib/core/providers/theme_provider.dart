import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppThemeSettings {
  final ThemeMode themeMode;
  final Color primaryColor;

  AppThemeSettings({required this.themeMode, required this.primaryColor});

  AppThemeSettings copyWith({ThemeMode? themeMode, Color? primaryColor}) {
    return AppThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeSettings>((
  ref,
) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeSettings> {
  ThemeNotifier()
    : super(
        AppThemeSettings(
          themeMode: ThemeMode.system,
          primaryColor: const Color(0xFF137FEC),
        ),
      );

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void toggleTheme(bool isDark) {
    state = state.copyWith(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    );
  }

  void setPrimaryColor(Color color) {
    state = state.copyWith(primaryColor: color);
  }
}

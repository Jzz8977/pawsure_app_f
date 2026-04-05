import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';

enum AppThemeMode { light, dark, system }

class ThemeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    Future.microtask(_loadFromStorage);
    return AppThemeMode.system;
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(StorageKeys.themeMode);
    if (saved != null) {
      state = AppThemeMode.values.byName(saved);
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.themeMode, mode.name);
  }

  ThemeMode get flutterThemeMode => switch (state) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };
}

final themeNotifierProvider =
    NotifierProvider<ThemeNotifier, AppThemeMode>(ThemeNotifier.new);

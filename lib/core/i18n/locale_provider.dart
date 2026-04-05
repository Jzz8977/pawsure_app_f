import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    Future.microtask(_loadFromStorage);
    return const Locale('zh');
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(StorageKeys.locale);
    if (code != null) state = Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.locale, locale.languageCode);
  }

  static const List<Locale> supportedLocales = [
    Locale('zh'),
    Locale('en'),
  ];
}

final localeNotifierProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

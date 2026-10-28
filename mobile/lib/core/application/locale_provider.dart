import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localePrefsKey = 'app_locale';

final localeProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController();
});

class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(_deviceLocale()) {
    _loadLocale();
  }

  static Locale _deviceLocale() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (code == 'pt') return const Locale('pt');
    return const Locale('en');
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localePrefsKey);
    if (code == null || code.isEmpty) return;
    final parts = code.split('_');
    state = parts.length >= 2 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
  }

  Future<void> changeLocale(Locale newLocale) async {
    state = newLocale;
    final prefs = await SharedPreferences.getInstance();
    final code = newLocale.countryCode != null
        ? '${newLocale.languageCode}_${newLocale.countryCode}'
        : newLocale.languageCode;
    await prefs.setString(_localePrefsKey, code);
  }
}

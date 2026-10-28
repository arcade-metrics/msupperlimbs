import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chave usada no SharedPreferences
const _localePrefsKey = 'app_locale';

/// Provider para acessar e alterar o idioma
final localeProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController();
});

class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(const Locale('en')) {
    _loadLocale();
  }

  /// Carrega o idioma salvo no SharedPreferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localePrefsKey);
    if (code != null && code.isNotEmpty) {
      final parts = code.split('_');
      if (parts.length == 2) {
        state = Locale(parts[0], parts[1]);
      } else {
        state = Locale(parts[0]);
      }
    } else {
      // Default to English if no locale is saved
      state = const Locale('en');
    }
  }

  /// Altera o idioma e salva no SharedPreferences
  Future<void> changeLocale(Locale newLocale) async {
    state = newLocale;
    final prefs = await SharedPreferences.getInstance();
    final code = newLocale.countryCode != null
        ? '${newLocale.languageCode}_${newLocale.countryCode}'
        : newLocale.languageCode;
    await prefs.setString(_localePrefsKey, code);
  }

  /// Restaura para seguir o idioma do sistema
  Future<void> resetToSystemLocale() async {
    await changeLocale(const Locale('en'));
  }
}

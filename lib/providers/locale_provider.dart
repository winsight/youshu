import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/l10n/app_locale.dart';

class LocaleNotifier extends StateNotifier<AppLanguage> {
  LocaleNotifier() : super(AppLanguage.system) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_language');
    if (saved != null && mounted) {
      final lang = AppLanguage.values.firstWhere(
        (l) => l.name == saved,
        orElse: () => AppLanguage.system,
      );
      state = lang;
    }
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang.name);
  }

  Locale? get resolvedLocale {
    if (state == AppLanguage.system) return null;
    return state.locale;
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  return LocaleNotifier();
});

final resolvedLocaleProvider = Provider<Locale?>((ref) {
  final lang = ref.watch(localeProvider);
  return lang.locale;
});

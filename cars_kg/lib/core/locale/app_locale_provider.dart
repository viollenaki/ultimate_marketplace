import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_localizations.dart';

const _localePrefsKey = 'app_locale_code';

final appLocaleProvider =
    AsyncNotifierProvider<AppLocaleNotifier, Locale>(AppLocaleNotifier.new);

class AppLocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localePrefsKey);
    if (code == 'ru') {
      return const Locale('ru');
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    )) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefsKey, locale.languageCode);
    state = AsyncValue.data(locale);
  }
}

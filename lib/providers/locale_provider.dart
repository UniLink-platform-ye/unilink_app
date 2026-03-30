// lib/providers/locale_provider.dart
// إدارة لغة التطبيق (العربية / الإنجليزية) مع SharedPreferences

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'unilink_locale';

  Locale _locale = const Locale('ar'); // افتراضي: العربية
  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code  = prefs.getString(_key) ?? 'ar';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    notifyListeners();
  }

  Future<void> toggle() async {
    await setLocale(isArabic ? const Locale('en') : const Locale('ar'));
  }
}

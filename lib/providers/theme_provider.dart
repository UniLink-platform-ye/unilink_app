// lib/providers/theme_provider.dart
// ThemeProvider الديناميكي:
// • يجلب branding مرة واحدة عند بدء التطبيق ويحتفظ به في الذاكرة طول الجلسة.
// • يدعم Dark/Light toggle مستقل عن الـ branding.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/branding_model.dart';
import '../services/branding_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'unilink_theme_mode';

  // ── وضع الثيم (فاتح / داكن) ──────────────────────────────
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  // ── بيانات الهوية (تُحمَّل مرة واحدة وتبقى طول الجلسة) ─
  BrandingModel _branding = BrandingModel.defaults;
  BrandingModel get branding => _branding;

  // ─────────────────────────────────────────────────────────
  /// التحميل الأولي — يُستدعى مرة واحدة في main()
  /// يجلب: وضع الثيم من SharedPreferences + branding (cache أو network).
  // ─────────────────────────────────────────────────────────
  Future<void> load() async {
    // 1) وضع الثيم
    final prefs = await SharedPreferences.getInstance();
    _themeMode  = _parseMode(prefs.getString(_themeKey)) ?? ThemeMode.light;

    // 2) Branding (يُستخدم in-memory إن وُجد، ثم disk، ثم network)
    _branding = await BrandingService.fetchBranding();

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  /// تحديث إجباري للـ branding من الشبكة (يُستخدم بشكل صريح فقط،
  /// مثلاً: زر "تحديث" في صفحة الإعدادات).
  // ─────────────────────────────────────────────────────────
  Future<void> refreshBranding() async {
    BrandingService.resetSessionCache();
    _branding = await BrandingService.fetchBranding(forceRefresh: true);
    notifyListeners();
  }

  // ── التحكم في وضع الثيم ──────────────────────────────────
  ThemeMode? _parseMode(String? raw) {
    if (raw == 'dark')  return ThemeMode.dark;
    if (raw == 'light') return ThemeMode.light;
    return null;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> toggle() => setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);

  // ── بناء ThemeData ديناميكي ──────────────────────────────
  ThemeData buildTheme(Brightness brightness) {
    final b      = _branding;
    final isDark = brightness == Brightness.dark;
    final primary   = b.primaryColor;
    final onPrimary = b.buttonTextColor;

    final colorScheme = ColorScheme.fromSeed(
      seedColor:  primary,
      brightness: brightness,
    ).copyWith(
      primary:    primary,
      onPrimary:  onPrimary,
      secondary:  b.secondaryColor,
      tertiary:   b.accentColor,
      surface:    isDark ? const Color(0xFF1E293B) : b.backgroundColor,
      onSurface:  isDark ? const Color(0xFFE2E8F0) : b.textColor,
    );

    return ThemeData(
      useMaterial3:            true,
      colorScheme:             colorScheme,
      fontFamily:              b.fontFamily,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : b.backgroundColor,

      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation:       0,
        centerTitle:     true,
        titleTextStyle: TextStyle(
          fontFamily: b.fontFamily,
          fontWeight: FontWeight.w700,
          fontSize:   18,
          color:      onPrimary,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: b.buttonPrimaryColor,
          foregroundColor: b.buttonTextColor,
          shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: TextStyle(
            fontFamily: b.fontFamily, fontWeight: FontWeight.w700, fontSize: 15,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: isDark ? const Color(0xFF1E293B) : b.inputBgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: b.inputBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: b.inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      cardTheme: CardTheme(
        elevation: 0,
        color:     isDark ? const Color(0xFF1E293B) : b.cardBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : b.inputBorderColor,
          ),
        ),
      ),
    );
  }
}

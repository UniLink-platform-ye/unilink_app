// lib/services/branding_service.dart
// يجلب Branding API مرة واحدة فقط لكل جلسة — يُخزّن في ذاكرة + SharedPreferences

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/branding_model.dart';

class BrandingService {
  static const String _cacheKey = 'unilink_branding_cache';

  // ── In-memory singleton (حياته طوال الجلسة) ───────────────
  static BrandingModel? _sessionCache;

  /// هل تم جلب الـ branding لهذه الجلسة؟
  static bool get isLoaded => _sessionCache != null;

  /// الـ branding الحالي في الذاكرة (قد يكون null قبل أول fetch)
  static BrandingModel? get current => _sessionCache;

  // ─────────────────────────────────────────────────────────────
  /// جلب إعدادات الهوية — أولوية الأداء:
  ///   1) in-memory singleton   → فوري (نفس الجلسة)
  ///   2) SharedPreferences cache → من القرص (أسرع من الشبكة)
  ///   3) HTTP API              → شبكة (عند أول تشغيل أو انتهاء الـ cache)
  ///   4) BrandingModel.defaults → fallback كامل
  // ─────────────────────────────────────────────────────────────
  static Future<BrandingModel> fetchBranding({bool forceRefresh = false}) async {
    // 1) الذاكرة (طول الجلسة)
    if (!forceRefresh && _sessionCache != null) {
      if (kDebugMode) debugPrint('[Branding] ✔ from in-memory session cache');
      return _sessionCache!;
    }

    // 2) القرص (SharedPreferences)
    if (!forceRefresh) {
      final cached = await _loadFromDisk();
      if (cached != null) {
        _sessionCache = cached;
        if (kDebugMode) debugPrint('[Branding] ✔ from disk cache');
        return _sessionCache!;
      }
    }

    // 3) الشبكة
    final fromNetwork = await _fetchFromNetwork();
    if (fromNetwork != null) {
      _sessionCache = fromNetwork;
      await _saveToDisk(fromNetwork);
      if (kDebugMode) debugPrint('[Branding] ✔ fetched from network');
      return _sessionCache!;
    }

    // 4) Fallback
    if (kDebugMode) debugPrint('[Branding] ⚠ using defaults (network + cache failed)');
    _sessionCache ??= BrandingModel.defaults;
    return _sessionCache!;
  }

  // ── private: قراءة من القرص ──────────────────────────────────
  static Future<BrandingModel?> _loadFromDisk() async {
    try {
      final prefs  = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        return BrandingModel.fromJson(map);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Branding] disk cache error: $e');
    }
    return null;
  }

  // ── private: حفظ في القرص ────────────────────────────────────
  static Future<void> _saveToDisk(BrandingModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(model.toJson()));
    } catch (e) {
      if (kDebugMode) debugPrint('[Branding] disk save error: $e');
    }
  }

  // ── private: جلب من الشبكة ───────────────────────────────────
  static Future<BrandingModel?> _fetchFromNetwork() async {
    try {
      final uri = Uri.parse(ApiConfig.branding);
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          return BrandingModel.fromJson(body['data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Branding] network error: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  /// مسح الـ cache (القرص فقط — الذاكرة تُمسح تلقائياً عند إغلاق التطبيق)
  /// يُستخدم عند تسجيل الخروج أو التحديث الإجباري من الإعدادات.
  // ─────────────────────────────────────────────────────────────
  static Future<void> clearDiskCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }

  /// إعادة تعيين الـ session cache (يُستخدم مع forceRefresh)
  static void resetSessionCache() {
    _sessionCache = null;
  }
}

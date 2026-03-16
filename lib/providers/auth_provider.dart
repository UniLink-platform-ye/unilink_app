import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../config/api_config.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _pendingToken; // مؤقت بين login وverifyOtp

  Map<String, dynamic>? get user      => _user;
  bool                  get isLoading => _isLoading;
  bool                  get isLoggedIn => _user != null;

  // ── تحميل الجلسة عند بدء التطبيق ──────────────────────
  Future<void> loadSession() async {
    final savedUser = await ApiService.getUser();
    final token     = await ApiService.getToken();
    if (savedUser != null && token != null) {
      _user = savedUser;
      notifyListeners();
    }
  }

  // ── المرحلة 1: email + password → OTP ─────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true; notifyListeners();
    try {
      final res = await ApiService.post(ApiConfig.login, {
        'email': email.trim(),
        'password': password,
      });
      if (res['success'] == true) {
        _pendingToken = res['data']?['pending_token'];
      }
      return res;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  /// إعادة إرسال OTP: إما بالـ pending_token (من شاشة OTP) أو email+password (لحساب غير مفعّل)
  Future<Map<String, dynamic>> resendOtp({String? email, String? password}) async {
    _isLoading = true; notifyListeners();
    try {
      final body = <String, dynamic>{};
      if (_pendingToken != null && _pendingToken!.isNotEmpty) {
        body['pending_token'] = _pendingToken;
      } else if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
        body['email'] = email.trim();
        body['password'] = password;
      } else {
        _isLoading = false; notifyListeners();
        return {'success': false, 'error': 'انتهت الجلسة. أعد تسجيل الدخول واختر إعادة إرسال رمز التفعيل.'};
      }
      final res = await ApiService.post(ApiConfig.resendOtp, body);
      if (res['success'] == true && res['data'] != null) {
        _pendingToken = res['data']?['pending_token'];
      }
      return res;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  // ── المرحلة 2: OTP → JWT ───────────────────────────────
  Future<Map<String, dynamic>> verifyOtp(String otp) async {
    if (_pendingToken == null) {
      return {'success': false, 'error': 'انتهت جلسة الدخول، أعد المحاولة'};
    }
    _isLoading = true; notifyListeners();
    try {
      final res = await ApiService.post(ApiConfig.verifyOtp, {
        'pending_token': _pendingToken,
        'otp': otp.trim(),
      });
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        // ✅ نحفظ التوكن والمستخدم أولاً
        await ApiService.saveToken(data['token'] as String);
        await ApiService.saveUser(data['user'] as Map<String, dynamic>);
        _user         = data['user'] as Map<String, dynamic>;
        _pendingToken = null;
        // ✅ نُبلّغ الـ UI الآن (بعد حفظ التوكن) ليُبنى HomeScreen بتوكن جاهز
        _isLoading = false; notifyListeners();
        // ✅ نسجّل FCM بعد الانتقال لتجنب تأخير الـ UI
        FcmService.registerToken();
      }
      return res;
    } finally {
      if (_isLoading) { _isLoading = false; notifyListeners(); }
    }
  }

  // ── التسجيل ────────────────────────────────────────────
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    _isLoading = true; notifyListeners();
    try {
      final res = await ApiService.post(ApiConfig.register, data);
      if (res['success'] == true) {
        _pendingToken = res['data']?['pending_token'];
      }
      return res;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  // ── تسجيل الخروج ───────────────────────────────────────
  Future<void> logout() async {
    await FcmService.unregisterToken();
    FcmService.resetState();
    await ApiService.clearAll();
    _user = null;
    _pendingToken = null;
    notifyListeners();
  }
}

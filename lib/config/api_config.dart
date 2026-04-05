import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// api_config.dart - central API endpoint configuration.
class ApiConfig {
  static const String _defaultApiPath = '/Trusted-Social-Network-Platform/api/v1';
  static const String _devServerDefault =
      String.fromEnvironment('DEV_SERVER', defaultValue: '10.0.2.2');
  static const String _releaseBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const bool _allowDebugHttp =
      bool.fromEnvironment('ALLOW_DEBUG_HTTP', defaultValue: true);

  static String _baseUrl = '';

  static String get baseUrl => _baseUrl;
  static String get serverIp => _baseUrl;
  static bool get isConfigured => _baseUrl.isNotEmpty;
  static bool get isSecureTransport =>
      _baseUrl.toLowerCase().startsWith('https://');

  static Future<void> loadHost() async {
    final prefs = await SharedPreferences.getInstance();

    if (kReleaseMode) {
      _baseUrl = _normalizeBaseUrl(_releaseBaseUrl, allowHttp: false);
      return;
    }

    final saved = prefs.getString('api_base_url');
    _baseUrl = _normalizeBaseUrl(
      saved?.trim().isNotEmpty == true ? saved! : _devServerDefault,
      allowHttp: _allowDebugHttp,
    );
  }

  static Future<void> setHost(String value) async {
    final normalized = previewBaseUrl(value);
    if (normalized.isEmpty) {
      throw ArgumentError('Invalid API server value.');
    }
    if (kReleaseMode && !normalized.startsWith('https://')) {
      throw ArgumentError('HTTPS is required in release builds.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', normalized);
    _baseUrl = normalized;
  }

  static String previewBaseUrl(String value) {
    return _normalizeBaseUrl(value, allowHttp: !kReleaseMode && _allowDebugHttp);
  }

  static String _normalizeBaseUrl(String rawValue, {required bool allowHttp}) {
    var value = rawValue.trim();
    if (value.isEmpty) {
      return '';
    }

    if (!value.contains('://')) {
      value = '${allowHttp ? 'http' : 'https'}://$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) {
      return '';
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && !(allowHttp && scheme == 'http')) {
      return '';
    }

    final normalizedPath = _normalizeApiPath(uri.path);
    final normalized = uri.replace(
      path: normalizedPath,
      query: null,
      fragment: null,
    );

    final output = normalized.toString();
    return output.endsWith('/') ? output.substring(0, output.length - 1) : output;
  }

  static String _normalizeApiPath(String rawPath) {
    var path = rawPath.trim();
    if (path.isEmpty || path == '/') {
      return _defaultApiPath;
    }

    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    if (path.endsWith('/api/v1')) {
      return path;
    }

    if (path.contains('/api/v1')) {
      final idx = path.indexOf('/api/v1');
      return path.substring(0, idx + '/api/v1'.length);
    }

    if (path.endsWith('/Trusted-Social-Network-Platform')) {
      return '$path/api/v1';
    }

    return '$path/api/v1';
  }

  static String get login => '$_baseUrl/auth/login.php';
  static String get verifyOtp => '$_baseUrl/auth/verify_otp.php';
  static String get resendOtp => '$_baseUrl/auth/resend_otp.php';
  static String get register => '$_baseUrl/auth/register.php';

  static String get feed => '$_baseUrl/feed.php';
  static String get posts => '$_baseUrl/posts.php';
  static String get groups => '$_baseUrl/groups.php';
  static String get messages => '$_baseUrl/messages.php';
  static String get users => '$_baseUrl/users.php';
  static String get notifications => '$_baseUrl/notifications.php';
  static String get fcmToken => '$_baseUrl/fcm_token.php';
  static String get profile => '$_baseUrl/profile.php';
  static String get files => '$_baseUrl/files.php';
  static String get calendar => '$_baseUrl/calendar.php';
  static String get reports => '$_baseUrl/reports.php';
  static String get support => '$_baseUrl/support.php';
  static String get search => '$_baseUrl/search.php';
  static String get groupsManage => '$_baseUrl/groups_manage.php';
}

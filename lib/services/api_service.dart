import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'unilink_jwt';
  static const String _userKey = 'unilink_user';
  static const bool _enableApiLog =
      bool.fromEnvironment('ENABLE_API_LOGS', defaultValue: false);

  static void _log(String tag, Object message, [Object? extra]) {
    if (!kDebugMode || !_enableApiLog) {
      return;
    }

    final time = DateTime.now().toIso8601String().substring(11, 23);
    debugPrint('[$time] [API::$tag] $message');
    if (extra != null) {
      debugPrint('[$time] [API::$tag] -> ${_sanitizeForLog(extra)}');
    }
  }

  static Object? _sanitizeForLog(Object? value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(
            key,
            _isSensitiveKey(key.toString()) ? '[redacted]' : _sanitizeForLog(val),
          ));
    }

    if (value is List) {
      return value.map(_sanitizeForLog).toList(growable: false);
    }

    if (value is String) {
      final lower = value.toLowerCase();
      if (lower.contains('bearer ') || lower.contains('token') || value.length > 160) {
        return '[redacted]';
      }
      return value;
    }

    return value;
  }

  static bool _isSensitiveKey(String key) {
    final lower = key.toLowerCase();
    return lower.contains('password') ||
        lower.contains('token') ||
        lower.contains('secret') ||
        lower.contains('authorization') ||
        lower.contains('otp');
  }

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static Future<void> saveUser(Map<String, dynamic> user) =>
      _storage.write(key: _userKey, value: jsonEncode(user));

  static Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) {
      return null;
    }

    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _parse(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return {
        'success': false,
        'error': 'Invalid server response (${response.statusCode})',
      };
    }
  }

  static Map<String, dynamic> _parseRawBytes(List<int> bytes, int statusCode) {
    try {
      return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      return {
        'success': false,
        'error': 'Invalid server response ($statusCode)',
      };
    }
  }

  static Future<Map<String, dynamic>> _finalizeResponse(
    int statusCode,
    Map<String, dynamic> payload,
  ) async {
    if (statusCode == 401) {
      await clearAll();
      payload['auth_expired'] = true;
    }

    return payload;
  }

  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: params);
    final stopwatch = Stopwatch()..start();
    _log('GET', uri.toString(), params);

    try {
      final response = await http.get(uri, headers: await _headers());
      stopwatch.stop();
      _log('GET', '${response.statusCode} ${uri.path} (${stopwatch.elapsedMilliseconds}ms)');
      return _finalizeResponse(response.statusCode, _parse(response));
    } catch (e, st) {
      stopwatch.stop();
      _log('GET', 'ERROR', {'error': e.toString(), 'stack': st.toString()});
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final stopwatch = Stopwatch()..start();
    _log('POST', url, body);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      stopwatch.stop();
      _log('POST', '${response.statusCode} $url (${stopwatch.elapsedMilliseconds}ms)');
      return _finalizeResponse(response.statusCode, _parse(response));
    } catch (e, st) {
      stopwatch.stop();
      _log('POST', 'ERROR', {'error': e.toString(), 'stack': st.toString()});
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> postMultipart(
    String url, {
    required File file,
    String fieldName = 'file',
    Map<String, String>? fields,
  }) async {
    final token = await getToken();
    final uri = Uri.parse(url);
    final stopwatch = Stopwatch()..start();
    _log('MP_POST', uri.toString(), fields);

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (fields != null) {
        request.fields.addAll(fields);
      }
      request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

      final response = await request.send();
      final bytes = await response.stream.toBytes();
      stopwatch.stop();
      _log('MP_POST', '${response.statusCode} $url (${stopwatch.elapsedMilliseconds}ms)');

      final parsed = _parseRawBytes(bytes, response.statusCode);
      return _finalizeResponse(response.statusCode, parsed);
    } catch (e, st) {
      stopwatch.stop();
      _log('MP_POST', 'ERROR', {'error': e.toString(), 'stack': st.toString()});
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final stopwatch = Stopwatch()..start();
    _log('DELETE', url, body);

    try {
      final request = http.Request('DELETE', Uri.parse(url));
      request.headers.addAll(await _headers());
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final response = await request.send();
      final raw = await response.stream.bytesToString();
      stopwatch.stop();
      _log('DELETE', '${response.statusCode} $url (${stopwatch.elapsedMilliseconds}ms)');

      Map<String, dynamic> parsed;
      try {
        parsed = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        parsed = {'success': false, 'error': 'Invalid response'};
      }

      return _finalizeResponse(response.statusCode, parsed);
    } catch (e, st) {
      stopwatch.stop();
      _log('DELETE', 'ERROR', {'error': e.toString(), 'stack': st.toString()});
      rethrow;
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'unilink_jwt';
  static const String _userKey  = 'unilink_user';

  /// تفعيل تتبع الـ API على الكونسول (يعمل تلقائياً في وضع Debug فقط)
  static const bool _enableApiLog = true;

  static void _log(String tag, Object message, [Object? extra]) {
    if (kDebugMode && _enableApiLog) {
      final time = DateTime.now().toIso8601String().substring(11, 23);
      print('[$time] [API::$tag] $message');
      if (extra != null) print('[$time] [API::$tag] ↳ $extra');
    }
  }

  // ─── Token Management ─────────────────────────────────────
  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static Future<void> saveUser(Map<String, dynamic> user) =>
      _storage.write(key: _userKey, value: jsonEncode(user));

  static Future<Map<String, dynamic>?> getUser() async {
    final s = await _storage.read(key: _userKey);
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  static Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  // ─── HTTP Helpers ──────────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _parse(http.Response res) {
    try {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      _log('PARSE', 'Invalid JSON response (${res.statusCode})', res.body.length > 300 ? '${res.body.substring(0, 300)}...' : res.body);
      return {'success': false, 'error': 'Invalid server response (${res.statusCode})'};
    }
  }

  static Map<String, dynamic> _parseRawBytes(List<int> bytes, int statusCode) {
    try {
      return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (e) {
      _log('PARSE', 'Invalid JSON response ($statusCode)', bytes.length > 300 ? '${utf8.decode(bytes.take(300).toList())}...' : utf8.decode(bytes));
      return {'success': false, 'error': 'Invalid server response ($statusCode)'};
    }
  }

  // ─── GET ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: params);
    _log('GET', uri.toString(), params?.isNotEmpty == true ? params : null);
    final stopwatch = Stopwatch()..start();
    try {
      final res = await http.get(uri, headers: await _headers());
      stopwatch.stop();
      _log('GET', '${res.statusCode} ${uri.path} (${stopwatch.elapsedMilliseconds}ms)');
      if (res.statusCode >= 400) _log('GET', 'BODY', res.body.length > 500 ? '${res.body.substring(0, 500)}...' : res.body);
      final out = _parse(res);
      if (out.containsKey('error') || (out['success'] == false)) _log('GET', 'RESPONSE', out);
      return out;
    } catch (e, st) {
      stopwatch.stop();
      _log('GET', 'ERROR', e);
      _log('GET', 'STACK', st.toString().split('\n').take(5).join('\n'));
      rethrow;
    }
  }

  // ─── MULTIPART (File Upload) ───────────────────────────────
  static Future<Map<String, dynamic>> postMultipart(
    String url, {
    required File file,
    String fieldName = 'file',
    Map<String, String>? fields,
  }) async {
    final token = await getToken();
    final uri = Uri.parse(url);
    _log('MP_POST', uri.toString(), fields);
    final stopwatch = Stopwatch()..start();

    try {
      final req = http.MultipartRequest('POST', uri);
      req.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (fields != null) req.fields.addAll(fields);
      req.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

      final res = await req.send();
      final bytes = await res.stream.toBytes();
      stopwatch.stop();
      _log('MP_POST', '${res.statusCode} $url (${stopwatch.elapsedMilliseconds}ms)');
      if (res.statusCode >= 400) {
        final raw = utf8.decode(bytes);
        _log('MP_POST', 'BODY', raw.length > 500 ? '${raw.substring(0, 500)}...' : raw);
      }
      final out = _parseRawBytes(bytes, res.statusCode);
      if (out.containsKey('error') || (out['success'] == false)) _log('MP_POST', 'RESPONSE', out);
      return out;
    } catch (e, st) {
      stopwatch.stop();
      _log('MP_POST', 'ERROR', e);
      _log('MP_POST', 'STACK', st.toString().split('\n').take(5).join('\n'));
      rethrow;
    }
  }

  // ─── POST ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    _log('POST', url, body);
    final stopwatch = Stopwatch()..start();
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      stopwatch.stop();
      _log('POST', '${res.statusCode} $url (${stopwatch.elapsedMilliseconds}ms)');
      if (res.statusCode >= 400) _log('POST', 'BODY', res.body.length > 500 ? '${res.body.substring(0, 500)}...' : res.body);
      final out = _parse(res);
      if (out.containsKey('error') || (out['success'] == false)) _log('POST', 'RESPONSE', out);
      return out;
    } catch (e, st) {
      stopwatch.stop();
      _log('POST', 'ERROR', e);
      _log('POST', 'STACK', st.toString().split('\n').take(5).join('\n'));
      rethrow;
    }
  }

  // ─── PUT ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body,
  ) async {
    _log('PUT', url, body);
    final stopwatch = Stopwatch()..start();
    try {
      final res = await http.put(
        Uri.parse(url),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      stopwatch.stop();
      _log('PUT', '${res.statusCode} $url (${stopwatch.elapsedMilliseconds}ms)');
      if (res.statusCode >= 400) _log('PUT', 'BODY', res.body.length > 500 ? '${res.body.substring(0, 500)}...' : res.body);
      final out = _parse(res);
      if (out.containsKey('error') || (out['success'] == false)) _log('PUT', 'RESPONSE', out);
      return out;
    } catch (e, st) {
      stopwatch.stop();
      _log('PUT', 'ERROR', e);
      _log('PUT', 'STACK', st.toString().split('\n').take(5).join('\n'));
      rethrow;
    }
  }

  // ─── DELETE ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    _log('DELETE', url, body);
    final stopwatch = Stopwatch()..start();
    try {
      final req = http.Request('DELETE', Uri.parse(url));
      req.headers.addAll(await _headers());
      if (body != null) req.body = jsonEncode(body);
      final res = await req.send();
      final raw = await res.stream.bytesToString();
      stopwatch.stop();
      _log('DELETE', '${res.statusCode} $url (${stopwatch.elapsedMilliseconds}ms)');
      if (res.statusCode >= 400) _log('DELETE', 'BODY', raw.length > 500 ? '${raw.substring(0, 500)}...' : raw);
      try {
        final out = jsonDecode(raw) as Map<String, dynamic>;
        if (out.containsKey('error') || (out['success'] == false)) _log('DELETE', 'RESPONSE', out);
        return out;
      } catch (_) {
        return {'success': false, 'error': 'Invalid response'};
      }
    } catch (e, st) {
      stopwatch.stop();
      _log('DELETE', 'ERROR', e);
      _log('DELETE', 'STACK', st.toString().split('\n').take(5).join('\n'));
      rethrow;
    }
  }
}

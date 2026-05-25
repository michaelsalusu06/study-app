import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../constants/app_config.dart';
import '../services/auth_state.dart';

/// Centralized HTTP wrapper used by all services.
///
/// Security features:
///   - Auto-injects `Authorization` header when [requiresAuth] is true.
///   - Rate-limits each path to one call per 300 ms (DDoS/spam guard).
///   - Retries on network failure with exponential back-off.
///   - Sanitizes request body strings (trims whitespace, strips null bytes).
///   - Translates exceptions into user-facing error strings.
///   - Adds `X-Request-ID` (UUID v4) for server-side traceability.
///   - Warns when running on plain HTTP outside a loopback address.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // ── Rate-limiting ──────────────────────────────────────────────────────────

  final Map<String, DateTime> _lastCallTime = {};
  static const Duration _minInterval = Duration(milliseconds: 300);

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
    bool requiresAuth = false,
  }) async {
    _checkTls();
    _rateLimit(path);
    final uri = Uri.parse('${AppConfig.apiUrl}$path').replace(
      queryParameters: (queryParams?.isNotEmpty == true) ? queryParams : null,
    );
    return _withRetry(
      () => http
          .get(uri, headers: _headers(requiresAuth: requiresAuth))
          .timeout(AppConfig.requestTimeout),
    );
  }

  Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    _checkTls();
    _rateLimit(path);
    final uri = Uri.parse('${AppConfig.apiUrl}$path');
    return _withRetry(
      () => http
          .post(
            uri,
            headers: _headers(requiresAuth: requiresAuth),
            body: jsonEncode(_sanitize(body)),
          )
          .timeout(AppConfig.requestTimeout),
    );
  }

  Future<http.Response> patch(
    String path,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    _checkTls();
    _rateLimit(path);
    final uri = Uri.parse('${AppConfig.apiUrl}$path');
    return _withRetry(
      () => http
          .patch(
            uri,
            headers: _headers(requiresAuth: requiresAuth),
            body: jsonEncode(_sanitize(body)),
          )
          .timeout(AppConfig.requestTimeout),
    );
  }

  /// Translates a caught exception into a user-friendly message.
  String friendlyError(Object e) {
    if (e is SocketException) return 'No internet connection. Please check your network.';
    if (e is TimeoutException) return 'Request timed out. Please try again.';
    return 'Something went wrong. Please try again.';
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Map<String, String> _headers({required bool requiresAuth}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Request-ID': _uuid(),
    };
    if (requiresAuth && AuthState.instance.isLoggedIn) {
      headers['Authorization'] = 'Bearer ${AuthState.instance.accessToken}';
    }
    return headers;
  }

  void _rateLimit(String path) {
    final last = _lastCallTime[path];
    if (last != null && DateTime.now().difference(last) < _minInterval) {
      throw StateError(
        'Rate limit: "$path" called too fast. Wait ${_minInterval.inMilliseconds}ms.',
      );
    }
    _lastCallTime[path] = DateTime.now();
  }

  Future<http.Response> _withRetry(Future<http.Response> Function() call) async {
    int attempt = 0;
    while (true) {
      try {
        return await call();
      } on SocketException {
        if (attempt >= AppConfig.maxRetryAttempts) rethrow;
        await Future.delayed(AppConfig.retryDelay * pow(2, attempt).toInt());
        attempt++;
      } on TimeoutException {
        if (attempt >= AppConfig.maxRetryAttempts) rethrow;
        await Future.delayed(AppConfig.retryDelay * pow(2, attempt).toInt());
        attempt++;
      }
    }
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> body) {
    return body.map((key, value) {
      if (value is String) {
        return MapEntry(key, value.trim().replaceAll('\x00', ''));
      }
      return MapEntry(key, value);
    });
  }

  void _checkTls() {
    if (!AppConfig.useTls) return;
    final url = AppConfig.apiUrl;
    if (url.startsWith('http://') &&
        !url.contains('localhost') &&
        !url.contains('127.0.0.1') &&
        !url.contains('10.0.2.2')) {
      // ignore: avoid_print
      print('[ApiClient] WARNING: Plain HTTP on non-loopback address. '
          'Set AppConfig.apiUrl to an https:// URL for production.');
    }
  }

  String _uuid() {
    final rng = Random.secure();
    final b = List<int>.generate(16, (_) => rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String h(int v) => v.toRadixString(16).padLeft(2, '0');
    return '${h(b[0])}${h(b[1])}${h(b[2])}${h(b[3])}'
        '-${h(b[4])}${h(b[5])}'
        '-${h(b[6])}${h(b[7])}'
        '-${h(b[8])}${h(b[9])}'
        '-${h(b[10])}${h(b[11])}${h(b[12])}${h(b[13])}${h(b[14])}${h(b[15])}';
  }
}

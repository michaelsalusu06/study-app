import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_config.dart';
import 'auth_state.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      await _applyMockState(email: email, role: 'STUDENT');
      return AuthResult.success(role: 'STUDENT');
    }

    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(AppConfig.requestTimeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        await AuthState.instance.setFromResponse(data);
        return AuthResult.success(role: AuthState.instance.role ?? 'STUDENT');
      }

      return AuthResult.error(
        _extractMessage(data, response.statusCode),
      );
    } on Exception catch (e) {
      return AuthResult.error(_friendlyError(e));
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<AuthResult> register({
    required String email,
    required String password,
    String role = 'STUDENT',
  }) async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      await _applyMockState(email: email, role: role);
      return AuthResult.success(role: role);
    }

    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiUrl}/auth/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password, 'role': role}),
          )
          .timeout(AppConfig.requestTimeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        await AuthState.instance.setFromResponse(data);
        return AuthResult.success(role: AuthState.instance.role ?? 'STUDENT');
      }

      return AuthResult.error(_extractMessage(data, response.statusCode));
    } on Exception catch (e) {
      return AuthResult.error(_friendlyError(e));
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  void logout() => AuthState.instance.clear();

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _applyMockState({required String email, required String role}) async {
    await AuthState.instance.setFromResponse({
      'access_token': 'mock-token',
      'user': {
        'id': 'mock-user-1',
        'email': email,
        'role': role,
        'full_name': 'Muh Daffa Dwi S.',
      },
    });
  }

  String _extractMessage(Map<String, dynamic> data, int statusCode) {
    final raw = data['message'];
    if (raw is List) return raw.first.toString();
    return raw?.toString() ?? 'Request failed ($statusCode)';
  }

  String _friendlyError(Exception e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('TimeoutException')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Something went wrong. Please try again.';
  }
}

// ── Result type ────────────────────────────────────────────────────────────────

class AuthResult {
  final bool success;
  final String? role;
  final String? errorMessage;

  const AuthResult._({
    required this.success,
    this.role,
    this.errorMessage,
  });

  factory AuthResult.success({required String role}) =>
      AuthResult._(success: true, role: role);

  factory AuthResult.error(String message) =>
      AuthResult._(success: false, errorMessage: message);

  String get dashboardRoute =>
      (role?.toUpperCase() == 'TUTOR') ? '/teacher-dashboard' : '/student-dashboard';
}

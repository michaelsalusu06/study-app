import 'dart:convert';

import '../constants/app_config.dart';
import '../network/api_client.dart';
import 'auth_state.dart';
import 'student_profile_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (!email.contains('@') || !email.contains('.')) {
      return AuthResult.error('Please enter a valid email address.');
    }

    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      await _applyMockState(email: email, role: 'STUDENT');
      return AuthResult.success(role: 'STUDENT');
    }

    try {
      final response = await ApiClient.instance.post(
        '/auth/login',
        {'email': email, 'password': password},
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        await AuthState.instance.setFromResponse(data);
        // Fetch full profile to populate full_name (login response omits it).
        await StudentProfileService.instance.getMyProfile();
        return AuthResult.success(role: AuthState.instance.role ?? 'STUDENT');
      }

      return AuthResult.error(_extractMessage(data, response.statusCode));
    } on StateError catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error(ApiClient.instance.friendlyError(e));
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<AuthResult> register({
    required String email,
    required String password,
    String role = 'STUDENT',
  }) async {
    if (!email.contains('@') || !email.contains('.')) {
      return AuthResult.error('Please enter a valid email address.');
    }

    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      await _applyMockState(email: email, role: role);
      return AuthResult.success(role: role);
    }

    try {
      final response = await ApiClient.instance.post(
        '/auth/signup',
        {'email': email, 'password': password, 'role': role},
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        await AuthState.instance.setFromResponse(data);
        return AuthResult.success(role: AuthState.instance.role ?? 'STUDENT');
      }

      return AuthResult.error(_extractMessage(data, response.statusCode));
    } on StateError catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error(ApiClient.instance.friendlyError(e));
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

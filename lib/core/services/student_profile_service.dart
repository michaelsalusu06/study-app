import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';
import 'auth_state.dart';

// ─────────────────────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────────────────────

class GetMyProfileResult {
  final bool success;
  final Map<String, dynamic>? profile;
  final String? errorMessage;

  const GetMyProfileResult._({
    required this.success,
    this.profile,
    this.errorMessage,
  });

  factory GetMyProfileResult.success(Map<String, dynamic> profile) =>
      GetMyProfileResult._(success: true, profile: profile);

  factory GetMyProfileResult.error(String message) =>
      GetMyProfileResult._(success: false, errorMessage: message);
}

// ─────────────────────────────────────────────────────────────
// StudentProfileService — singleton
// ─────────────────────────────────────────────────────────────

/// Fetches and manages the logged-in student's own profile data.
///
/// Usage:
///   final result = await StudentProfileService.instance.getMyProfile();
///   if (result.success) {
///     final name = result.profile!['full_name'];
///   }
class StudentProfileService {
  StudentProfileService._();
  static final instance = StudentProfileService._();

  // ── Get own profile ─────────────────────────────────────────
  /// GET /user/profile/me  🔒 JWT required
  ///
  /// Returns the authenticated user's full profile.
  ///
  /// Response shape:
  ///   {
  ///     "id": "uuid",
  ///     "email": "john@example.com",
  ///     "full_name": "John Doe",
  ///     "username": "john_doe",
  ///     "bio": "...",
  ///     "avatar_url": "https://...",
  ///     "role": "STUDENT",
  ///     "subjects": [],
  ///     "overall_rating": null,
  ///     "student_rating": null,
  ///     "rating_count": 0,
  ///   }
  Future<GetMyProfileResult> getMyProfile() async {
    if (!AuthState.instance.isLoggedIn) {
      return GetMyProfileResult.error('You must be logged in.');
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/user/profile/me'),
        headers: AuthState.instance.authHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return GetMyProfileResult.success(data as Map<String, dynamic>);
      }

      if (response.statusCode == 401) {
        return GetMyProfileResult.error('Session expired. Please log in again.');
      }

      if (response.statusCode == 404) {
        return GetMyProfileResult.error('Profile not found.');
      }

      final message = data['message'] ?? data['error'] ?? 'Failed to load profile.';
      return GetMyProfileResult.error(message.toString());
    } catch (e) {
      return GetMyProfileResult.error('Network error: $e');
    }
  }
}
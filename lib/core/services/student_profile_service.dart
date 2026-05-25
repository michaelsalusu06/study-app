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
        Uri.parse('${AppConfig.apiUrl}/auth/me'),
        headers: AuthState.instance.authHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final profileData = data as Map<String, dynamic>;
        
        // --- Deep Scan for Coin Balance ---
        // 1. Check top level
        // 2. Check inside 'user' object if it exists
        final nestedUser = profileData['user'] as Map<String, dynamic>?;
        
        final dynamic balance = profileData['coins_balance'] 
                             ?? profileData['coin_balance']
                             ?? nestedUser?['coins_balance']
                             ?? nestedUser?['coin_balance']
                             ?? profileData['balance'];
        
        if (balance != null) {
          AuthState.instance.coinsBalance = (balance as num).toInt();
        }
        return GetMyProfileResult.success(profileData);
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

//* continue this code later
// Future<GetCoins> getCoin() async {
//   try {
//     final response = await http.get(Uri.parse('${AppConfig.apiUrl}/coins/balance'));
//   } catch (e) {
//     return e      
//   }
// }

  // ── Get notifications ───────────────────────────────────────
  Future<NotificationListResult> getNotifications({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/notifications?page=$page'),
        headers: AuthState.instance.authHeaders,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final list = (data['data'] as List).cast<Map<String, dynamic>>();
        return NotificationListResult.success(list);
      }
      return NotificationListResult.error(data['message']?.toString() ?? 'Error');
    } catch (e) {
      return NotificationListResult.error('Network error: $e');
    }
  }

  Future<bool> markSeen(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConfig.apiUrl}/notifications/$id/seen'),
        headers: AuthState.instance.authHeaders,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllSeen() async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConfig.apiUrl}/notifications/seen-all'),
        headers: AuthState.instance.authHeaders,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<int> getUnseenCount() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/notifications/unseen-count'),
        headers: AuthState.instance.authHeaders,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['unseen_count'] ?? 0;
      }
    } catch (_) {}
    return 0;
  }
}

class NotificationListResult {
  final bool success;
  final List<Map<String, dynamic>>? notifications;
  final String? errorMessage;
  NotificationListResult._({required this.success, this.notifications, this.errorMessage});
  factory NotificationListResult.success(List<Map<String, dynamic>> list) =>
      NotificationListResult._(success: true, notifications: list);
  factory NotificationListResult.error(String msg) =>
      NotificationListResult._(success: false, errorMessage: msg);
}
import 'dart:convert';

import '../network/api_client.dart';
import 'auth_state.dart';

// ─── Result types ─────────────────────────────────────────────────────────────

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

// ─── StudentProfileService — singleton ───────────────────────────────────────

/// Fetches and manages the logged-in user's own profile data.
class StudentProfileService {
  StudentProfileService._();
  static final instance = StudentProfileService._();

  // ── GET /auth/me ───────────────────────────────────────────────────────────

  /// GET /auth/me  🔒 JWT required
  ///
  /// Note: the server does NOT return coins_balance here.
  /// Call CoinService.getCoinBalance() separately to refresh balance.
  Future<GetMyProfileResult> getMyProfile() async {
    if (!AuthState.instance.isLoggedIn) {
      return GetMyProfileResult.error('You must be logged in.');
    }

    try {
      final response = await ApiClient.instance.get('/auth/me', requiresAuth: true);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final profile = data as Map<String, dynamic>;

        // Sync name/avatar into AuthState from the profile response.
        final fullName = profile['full_name']?.toString();
        if (fullName != null && fullName.isNotEmpty) {
          AuthState.instance.fullName = fullName;
        }
        final avatar = profile['avatar_url']?.toString();
        if (avatar != null) AuthState.instance.avatarUrl = avatar;

        return GetMyProfileResult.success(profile);
      }

      if (response.statusCode == 401) {
        return GetMyProfileResult.error('Session expired. Please log in again.');
      }

      if (response.statusCode == 404) {
        return GetMyProfileResult.error('Profile not found.');
      }

      final message = data['message'] ?? data['error'] ?? 'Failed to load profile.';
      return GetMyProfileResult.error(message.toString());
    } on StateError catch (e) {
      return GetMyProfileResult.error(e.message);
    } catch (e) {
      return GetMyProfileResult.error(ApiClient.instance.friendlyError(e));
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<NotificationListResult> getNotifications({int page = 1}) async {
    try {
      final response = await ApiClient.instance.get(
        '/notifications',
        queryParams: {'page': page.toString()},
        requiresAuth: true,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final list = (data['data'] as List).cast<Map<String, dynamic>>();
        return NotificationListResult.success(list);
      }
      return NotificationListResult.error(
          data['message']?.toString() ?? 'Error (${response.statusCode})');
    } on StateError catch (e) {
      return NotificationListResult.error(e.message);
    } catch (e) {
      return NotificationListResult.error(ApiClient.instance.friendlyError(e));
    }
  }

  Future<bool> markSeen(String id) async {
    try {
      final response = await ApiClient.instance.patch(
        '/notifications/$id/seen',
        {},
        requiresAuth: true,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllSeen() async {
    try {
      final response = await ApiClient.instance.patch(
        '/notifications/seen-all',
        {},
        requiresAuth: true,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<int> getUnseenCount() async {
    try {
      final response = await ApiClient.instance.get(
        '/notifications/unseen-count',
        requiresAuth: true,
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

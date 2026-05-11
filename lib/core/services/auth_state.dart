import 'package:shared_preferences/shared_preferences.dart';

/// In-memory singleton that holds authenticated user state.
/// Automatically persists to/from SharedPreferences so state survives restarts.
class AuthState {
  AuthState._();
  static final AuthState instance = AuthState._();

  String? accessToken;
  String? userId;
  String? email;
  String? role;
  String? fullName;
  String? avatarUrl;

  static const _kToken = 'auth_access_token';
  static const _kUserId = 'auth_user_id';
  static const _kEmail = 'auth_email';
  static const _kRole = 'auth_role';
  static const _kFullName = 'auth_full_name';
  static const _kAvatarUrl = 'auth_avatar_url';

  // ---------------------------------------------------------------------------
  // Hydrate from a server response
  // ---------------------------------------------------------------------------

  /// Call after a successful login/register response.
  Future<void> setFromResponse(Map<String, dynamic> data) async {
    accessToken = data['access_token']?.toString();

    final user = data['user'] as Map<String, dynamic>? ?? {};
    userId = user['id']?.toString();
    email = user['email']?.toString();
    role = user['role']?.toString();
    fullName = user['full_name']?.toString()
        ?? user['fullName']?.toString()
        ?? user['name']?.toString();
    avatarUrl = user['avatar_url']?.toString();

    await _persist();
  }

  // ---------------------------------------------------------------------------
  // Restore from disk (call on app start)
  // ---------------------------------------------------------------------------

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(_kToken);
    userId = prefs.getString(_kUserId);
    email = prefs.getString(_kEmail);
    role = prefs.getString(_kRole);
    fullName = prefs.getString(_kFullName);
    avatarUrl = prefs.getString(_kAvatarUrl);
  }

  // ---------------------------------------------------------------------------
  // Clear on logout
  // ---------------------------------------------------------------------------

  void clear() {
    accessToken = null;
    userId = null;
    email = null;
    role = null;
    fullName = null;
    avatarUrl = null;
    _clearPrefs();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool get isLoggedIn => accessToken != null;

  /// Ready-to-use headers for every authenticated HTTP request.
  Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

  /// Display name — falls back gracefully so the UI never shows "null".
  String get displayName => fullName ?? email?.split('@').first ?? 'Student';

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null) await prefs.setString(_kToken, accessToken!);
    if (userId != null) await prefs.setString(_kUserId, userId!);
    if (email != null) await prefs.setString(_kEmail, email!);
    if (role != null) await prefs.setString(_kRole, role!);
    if (fullName != null) await prefs.setString(_kFullName, fullName!);
    if (avatarUrl != null) await prefs.setString(_kAvatarUrl, avatarUrl!);
  }

  void _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kEmail);
    await prefs.remove(_kRole);
    await prefs.remove(_kFullName);
    await prefs.remove(_kAvatarUrl);
  }
}

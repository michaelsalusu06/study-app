import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory singleton that holds authenticated user state.
/// Automatically persists to/from SharedPreferences so state survives restarts.
class AuthState extends ChangeNotifier {
  AuthState._();
  static final AuthState instance = AuthState._();

  String? accessToken;
  String? userId;
  String? email;
  String? role;
  
  String? _username;
  String? get username => _username;
  set username(String? val) {
    _username = val;
    _persist();
    notifyListeners();
  }

  String? _fullName;
  String? get fullName => _fullName;
  set fullName(String? val) {
    _fullName = val;
    _persist();
    notifyListeners();
  }

  int _coinsBalance = 0;
  int get coinsBalance => _coinsBalance;
  set coinsBalance(int val) {
    _coinsBalance = val;
    _persist();
    notifyListeners();
  }

  String? avatarUrl;

  static const _kToken = 'auth_access_token';
  static const _kUserId = 'auth_user_id';
  static const _kEmail = 'auth_email';
  static const _kRole = 'auth_role';
  static const _kFullName = 'auth_full_name';
  static const _kUsername = 'auth_username';
  static const _kCoinsBalance = 'auth_coins_balance';
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
    _username = user['username']?.toString();
    _fullName = user['full_name']?.toString()
        ?? user['fullName']?.toString()
        ?? user['name']?.toString();
    
    // Scan for balance in both top level and nested user
    final dynamic balance = data['coins_balance'] 
                         ?? data['coin_balance'] 
                         ?? user['coins_balance'] 
                         ?? user['coin_balance'];
    
    _coinsBalance = (balance as num?)?.toInt() ?? 0;
    
    avatarUrl = user['avatar_url']?.toString();

    await _persist();
    notifyListeners();
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
    _username = prefs.getString(_kUsername);
    _fullName = prefs.getString(_kFullName);
    _coinsBalance = prefs.getInt(_kCoinsBalance) ?? 0;
    avatarUrl = prefs.getString(_kAvatarUrl);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Clear on logout
  // ---------------------------------------------------------------------------

  void clear() {
    accessToken = null;
    userId = null;
    email = null;
    role = null;
    _username = null;
    _fullName = null;
    _coinsBalance = 0;
    avatarUrl = null;
    _clearPrefs();
    notifyListeners();
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
    if (_username != null) await prefs.setString(_kUsername, _username!);
    if (_fullName != null) await prefs.setString(_kFullName, _fullName!);
    await prefs.setInt(_kCoinsBalance, _coinsBalance);
    if (avatarUrl != null) await prefs.setString(_kAvatarUrl, avatarUrl!);
  }

  void _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kEmail);
    await prefs.remove(_kRole);
    await prefs.remove(_kUsername);
    await prefs.remove(_kFullName);
    await prefs.remove(_kCoinsBalance);
    await prefs.remove(_kAvatarUrl);
  }
}

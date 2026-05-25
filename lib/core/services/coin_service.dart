import 'dart:convert';

import '../network/api_client.dart';
import 'auth_state.dart';

// ─── Result types ─────────────────────────────────────────────────────────────

class CoinBalanceResult {
  final bool success;
  final int? balance;
  final String? errorMessage;

  const CoinBalanceResult._({
    required this.success,
    this.balance,
    this.errorMessage,
  });

  factory CoinBalanceResult.success(int balance) =>
      CoinBalanceResult._(success: true, balance: balance);

  factory CoinBalanceResult.error(String message) =>
      CoinBalanceResult._(success: false, errorMessage: message);
}

class CoinHistoryResult {
  final bool success;
  final List<Map<String, dynamic>>? history;
  final String? errorMessage;

  const CoinHistoryResult._({
    required this.success,
    this.history,
    this.errorMessage,
  });

  factory CoinHistoryResult.success(List<Map<String, dynamic>> data) =>
      CoinHistoryResult._(success: true, history: data);

  factory CoinHistoryResult.error(String message) =>
      CoinHistoryResult._(success: false, errorMessage: message);
}

// ─── CoinService ──────────────────────────────────────────────────────────────

/// Handles all coin-related API calls.
///
/// Usage:
///   final result = await CoinService.instance.getCoinBalance();
///   final history = await CoinService.instance.getCoinHistory();
class CoinService {
  CoinService._();
  static final CoinService instance = CoinService._();

  // ── GET /coins/balance ─────────────────────────────────────────────────────

  /// Fetches live coin balance and updates [AuthState.coinsBalance].
  /// Backend returns: `{ "coins_balance": number }`
  Future<CoinBalanceResult> getCoinBalance() async {
    if (!AuthState.instance.isLoggedIn) {
      return CoinBalanceResult.error('Not authenticated.');
    }

    try {
      final response = await ApiClient.instance.get(
        '/coins/balance',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = data['coins_balance'] ?? data['coin_balance'] ?? data['balance'];
        final balance = (raw as num?)?.toInt() ?? 0;
        AuthState.instance.coinsBalance = balance;
        return CoinBalanceResult.success(balance);
      }

      if (response.statusCode == 401) {
        return CoinBalanceResult.error('Session expired. Please log in again.');
      }

      return CoinBalanceResult.error('Failed to load balance (${response.statusCode})');
    } on StateError catch (e) {
      return CoinBalanceResult.error(e.message);
    } catch (e) {
      return CoinBalanceResult.error(ApiClient.instance.friendlyError(e));
    }
  }

  // ── GET /coins/history ─────────────────────────────────────────────────────

  /// Returns last 50 coin transactions.
  /// Fields per item: kind, amount, note, created_at.
  Future<CoinHistoryResult> getCoinHistory() async {
    if (!AuthState.instance.isLoggedIn) {
      return CoinHistoryResult.error('Not authenticated.');
    }

    try {
      final response = await ApiClient.instance.get(
        '/coins/history',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return CoinHistoryResult.success(list.cast<Map<String, dynamic>>());
      }

      return CoinHistoryResult.error('Failed to load history (${response.statusCode})');
    } on StateError catch (e) {
      return CoinHistoryResult.error(e.message);
    } catch (e) {
      return CoinHistoryResult.error(ApiClient.instance.friendlyError(e));
    }
  }
}

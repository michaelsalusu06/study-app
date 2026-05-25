/// Central app configuration.
///
/// Flip [useMock] to `false` and set [apiUrl] to your real server
/// before building for production.
class AppConfig {
  AppConfig._();

  // ── Environment toggle ─────────────────────────────────────────────────────

  /// When `true` every service returns fake data; no real HTTP is made.
  static bool useMock = false;

  // ── API base URL ───────────────────────────────────────────────────────────

  /// `10.0.2.2` is the Android-emulator alias for `localhost`.
  /// Replace with your real server URL for physical devices / production.
  static const String apiUrl = 'http://10.0.2.2:3000';

  // ── Network settings ───────────────────────────────────────────────────────

  static const Duration requestTimeout = Duration(seconds: 15);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  /// When true, ApiClient logs a warning if apiUrl is plain HTTP on a
  /// non-loopback address (reminder to use HTTPS in production).
  static const bool useTls = true;

  // ── Currency & coins ───────────────────────────────────────────────────────

  static const String currencySymbol = 'Rp';
  static const String currencyCode = 'IDR';
  static const String coinLabel = 'Coins';

  /// Matches backend WELCOME_COINS = 10.
  static const int welcomeBonusCoins = 10;

  // ── Subscription prices ────────────────────────────────────────────────────

  static const double premiumMonthlyPrice = 19.99;
  static const double premiumYearlyPrice = 199.99;
  static const double proMonthlyPrice = 39.99;
  static const double proYearlyPrice = 399.99;

  static const List<SubscriptionPlanConfig> subscriptionPlans = [
    SubscriptionPlanConfig(name: 'Free', monthlyPrice: 0, yearlyPrice: 0),
    SubscriptionPlanConfig(
      name: 'Premium',
      monthlyPrice: premiumMonthlyPrice,
      yearlyPrice: premiumYearlyPrice,
    ),
    SubscriptionPlanConfig(
      name: 'Pro',
      monthlyPrice: proMonthlyPrice,
      yearlyPrice: proYearlyPrice,
    ),
  ];

  // ── Validation limits ──────────────────────────────────────────────────────

  static const int maxMessageLength = 2000;
}

/// Lightweight pricing config for a subscription tier.
class SubscriptionPlanConfig {
  final String name;
  final double monthlyPrice;
  final double yearlyPrice;

  const SubscriptionPlanConfig({
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
  });
}

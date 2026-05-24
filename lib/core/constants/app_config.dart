/// Central app configuration.
///
/// Flip [useMock] to `false` and set [apiUrl] to your real server
/// before building for production.
class AppConfig {
  AppConfig._();

  // ── Environment toggle ─────────────────────────────────────────────────────

  /// When `true` every service returns fake data; no real HTTP is made.
  /// Flip to `false` when the backend is running.
  /// On Android emulator, the server at localhost is reachable via 10.0.2.2.
  /// On physical device, replace apiUrl with your machine's local IP (e.g. 192.168.x.x).
  static bool useMock = false;

  // ── API base URL ───────────────────────────────────────────────────────────

  /// Base URL for all API requests.
  ///
  /// `10.0.2.2` is the Android-emulator alias for `localhost`.
  /// Replace with your real server URL for physical devices / production.
  static const String apiUrl = 'http://10.0.2.2:3000';

  // ── Network settings ───────────────────────────────────────────────────────

  /// How long to wait for a server response before giving up.
  static const Duration requestTimeout = Duration(seconds: 15);

}

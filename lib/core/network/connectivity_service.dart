import 'dart:async';
import 'dart:io';

/// Singleton that monitors internet connectivity.
///
/// Polls DNS every 5 seconds — no external package required.
/// Call [startMonitoring] once from main() before runApp().
///
/// Usage:
///   ConnectivityService.instance.onConnectivityChanged.listen((online) { ... });
///   bool connected = ConnectivityService.instance.isOnline;
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  Timer? _timer;

  /// Start polling. Idempotent — safe to call multiple times.
  void startMonitoring() {
    if (_timer != null) return;
    _check();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _check() async {
    final was = _isOnline;
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      _isOnline = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      _isOnline = false;
    } on TimeoutException {
      _isOnline = false;
    }
    if (_isOnline != was) _controller.add(_isOnline);
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity gate. Rule (gray_flow_lessons.md #2):
/// connectivity `none` → offline screen IMMEDIATELY, no DNS probe first.
/// A DNS probe hangs several seconds while offline and the WebView renders
/// its own error page.
class SkyProbe {
  const SkyProbe();

  Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  Stream<bool> onlineChanges() {
    return Connectivity()
        .onConnectivityChanged
        .map((results) => results.any((r) => r != ConnectivityResult.none));
  }
}

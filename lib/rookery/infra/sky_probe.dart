import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity gate. Two-tier check.
///
/// 1. [hasInterface] — instant, uses `connectivity_plus`. Detects Airplane
///    mode / Wi-Fi and cellular both off. Never blocks.
/// 2. [canReachNetwork] — actual reachability of the wider Internet via
///    a raw TCP connect to a public IP. DNS caching on iOS makes
///    `InternetAddress.lookup` unreliable (a cached apple.com record can
///    resolve while the device has no route to the Internet); TCP connect
///    talks to the routing stack directly and fails within ~1 s when the
///    interface is up but there is no upstream.
///
/// Rule (gray_flow_lessons.md #2): a `none` interface → offline screen
/// IMMEDIATELY (no probe). Once the interface is up we may spend a bounded
/// time (~1.5 s) validating actual reachability, but never the full 10–15 s
/// of AppsFlyer + dispatch timeouts.
class SkyProbe {
  const SkyProbe();

  /// Public anycast addresses (Cloudflare + Google) — both routable
  /// worldwide; if neither answers on :443 the device has no Internet.
  static const List<String> _reachIps = <String>[
    '1.1.1.1',
    '8.8.8.8',
  ];
  static const int _reachPort = 443;
  static const Duration _connectTimeout = Duration(milliseconds: 1500);

  Future<bool> hasInterface() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.isEmpty) return false;
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  /// True when at least one anycast host accepts a TCP connection.
  Future<bool> canReachNetwork() async {
    if (!await hasInterface()) return false;
    for (final ip in _reachIps) {
      try {
        final socket = await Socket.connect(
          ip,
          _reachPort,
          timeout: _connectTimeout,
        );
        socket.destroy();
        return true;
      } catch (_) {
        // Try the next host.
      }
    }
    return false;
  }

  Stream<bool> onlineChanges() {
    return Connectivity()
        .onConnectivityChanged
        .map((results) => results.any((r) => r != ConnectivityResult.none));
  }
}

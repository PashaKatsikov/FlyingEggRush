import 'dart:io' show HttpClient, Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../config/rookery_config.dart';
import 'debug_flock.dart';

/// Builds a realistic Mobile Safari User-Agent from the actual device and
/// hands out an HTTP client + a WebView UA string that ALWAYS match.
///
/// GAME THEME CATEGORY: crash (no appid/appname suffix — see gray_user_agent.mdc)
///
/// Rules enforced:
/// - No `Dart`/`Flutter`/`CFNetwork`/`Darwin`/`WebView` tokens anywhere.
/// - Same UA on the HTTP client (URLSession override) and the WebView.
/// - Real device iOS release from `device_info_plus`; hard fallback used
///   only if that throws.
class TalonAgent {
  TalonAgent._();
  static final TalonAgent instance = TalonAgent._();

  String? _ua;
  http.Client? _client;

  Future<String> userAgent() async {
    if (_ua != null) return _ua!;
    _ua = await _build();
    flockLog(() => '[FEG.agent] UA=$_ua');
    return _ua!;
  }

  http.Client get client {
    return _client ??= _buildClient();
  }

  Future<String> _build() async {
    try {
      if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        final release = info.systemVersion.replaceAll('.', '_');
        // Bump minor per project (fingerprint); iOS 18.5 is our current pin.
        return 'Mozilla/5.0 (iPhone; CPU iPhone OS $release like Mac OS X) '
            'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 '
            'Mobile/15E148 Safari/604.1';
      }
    } catch (_) {
      // fall through to hardcoded fallback
    }
    return 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 '
        'Mobile/15E148 Safari/604.1';
  }

  http.Client _buildClient() {
    final ua = _ua ?? '';
    final inner = HttpClient()
      // Override URLSession's default "CFNetwork/… Darwin/…" UA.
      ..userAgent = ua
      ..connectionTimeout = RookeryConfig.configTimeout;
    return IOClient(inner);
  }

  /// Only used in tests to reset the singleton between UA-related cases.
  void resetForTests() {
    _ua = null;
    _client?.close();
    _client = null;
  }
}

/// Ignore the unused import in non-iOS analysis passes — this file only
/// executes on iOS in release, but the analyzer runs on host.
// ignore: unused_element
void _touchConfig() => RookeryConfig.appTitle;

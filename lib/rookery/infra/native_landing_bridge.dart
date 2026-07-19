import 'package:shared_preferences/shared_preferences.dart';

/// Bridges the cold-start push URL captured by SceneDelegate into Dart.
///
/// SceneDelegate writes the tapped URL to UserDefaults under
/// `"flutter.feg_launch_route"` — the `flutter.` prefix is how
/// SharedPreferences and NSUserDefaults are wired on iOS. The Dart-side key
/// omits the prefix.
///
/// The two keys MUST stay in sync between:
///   ios/Runner/SceneDelegate.swift → `tapUrlKey = "flutter.feg_launch_route"`
///   this file                      → `_key      = "feg_launch_route"`
class NativeLandingBridge {
  static const String _key = 'feg_launch_route';

  /// Reads AND clears the cold-start URL. Returns null when nothing was
  /// captured (normal launch).
  ///
  /// MUST be called first in `RoostPilot.decide` — before push bootstrap /
  /// network probe / attribution — otherwise the URL is lost to a timeout
  /// race (`.cursor/rules/cold_start_push_viewport.mdc`).
  static Future<String?> consumeTapUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    await prefs.remove(_key);
    return raw;
  }
}

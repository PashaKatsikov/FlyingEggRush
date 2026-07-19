import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';

import 'debug_flock.dart';

/// Firebase Cloud Messaging wrapper. Owns permission, token retrieval
/// (with APNs pre-registration polling), and inbound-message routing.
class ChirpHub {
  ChirpHub._();
  static final ChirpHub instance = ChirpHub._();

  final _messaging = FirebaseMessaging.instance;
  bool _permissionRunning = false;
  String? _cachedToken;

  /// Fires when a fresh push token arrives after boot (typically once the
  /// user grants notification permission).
  void Function(String token)? onTokenReady;

  /// Fires when a push is opened while the app is running/background
  /// (NOT the killed-app cold-start path — that goes through SceneDelegate).
  void Function(String url)? onPushOpenUrl;

  Future<void> bootstrap() async {
    if (!Platform.isIOS) return;

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _messaging.onTokenRefresh.listen((t) {
      _cachedToken = t;
      onTokenReady?.call(t);
      flockLog(() => '[FEG.chirp] refresh token=${_short(t)}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final url = _extractUrl(msg.data);
      if (url != null) onPushOpenUrl?.call(url);
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      final url = _extractUrl(initial.data);
      if (url != null) onPushOpenUrl?.call(url);
    }
  }

  /// Poll `getAPNSToken()` briefly, then request the FCM token.
  /// On the first boot APNs is not registered yet so `getToken()` returns
  /// null unless we wait (gray_flow_guide.md §"APNs token delay").
  Future<String?> tryReadToken({int attempts = 5}) async {
    if (!Platform.isIOS) return null;
    if (_cachedToken != null) return _cachedToken;
    for (var i = 0; i < attempts; i++) {
      final apns = await _messaging.getAPNSToken();
      if (apns != null && apns.isNotEmpty) break;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    try {
      final t = await _messaging.getToken();
      _cachedToken = t;
      return t;
    } catch (e) {
      flockLog(() => '[FEG.chirp] token err=$e');
      return null;
    }
  }

  /// Wait longer (post-consent). Called from `WingInvitation` after Accept.
  Future<String?> waitForTokenAfterConsent() async {
    return tryReadToken(attempts: 14);
  }

  /// Ask the user for notification permission. Guarded against concurrent
  /// calls (Firebase throws "permissions request already running" otherwise).
  Future<NotificationSettings?> askPermission() async {
    if (!Platform.isIOS) return null;
    if (_permissionRunning) return null;
    _permissionRunning = true;
    try {
      final result = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      flockLog(() => '[FEG.chirp] perm=${result.authorizationStatus}');
      return result;
    } finally {
      _permissionRunning = false;
    }
  }

  Future<bool> currentlyDenied() async {
    if (!Platform.isIOS) return false;
    final s = await _messaging.getNotificationSettings();
    return s.authorizationStatus == AuthorizationStatus.denied;
  }

  /// True when the OS has already granted (authorized or provisional)
  /// notification permission. Our opt-in screen must never show in this
  /// state — the system decision is already positive.
  Future<bool> currentlyAuthorized() async {
    if (!Platform.isIOS) return false;
    final s = await _messaging.getNotificationSettings();
    return s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
  }

  static String? _extractUrl(Map<String, dynamic> data) {
    for (final k in const ['url', 'link', 'target', 'deeplink', 'deep_link']) {
      final v = data[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  static String _short(String s) => s.length > 12 ? '${s.substring(0, 12)}…' : s;
}

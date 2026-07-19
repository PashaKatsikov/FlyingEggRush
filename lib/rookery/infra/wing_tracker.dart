import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:http/http.dart' as http;

import '../config/rookery_config.dart';
import 'debug_flock.dart';
import 'talon_agent.dart';

/// AppsFlyer wrapper. Owns SDK bootstrap, conversion/deeplink capture,
/// GCD fallback (organic false-positive fix — see gray_flow_lessons.md #5),
/// and the final flat payload builder.
class WingTracker {
  AppsflyerSdk? _sdk;
  Map<String, dynamic>? _conversion;
  Map<String, dynamic>? _deepLink;
  bool _sdkStarted = false;

  final _conversionReady = Completer<void>();
  final _deepLinkReady = Completer<void>();

  Future<void> warmup() async {
    final options = AppsFlyerOptions(
      afDevKey: RookeryConfig.appsFlyerDevKey,
      appId: RookeryConfig.iosStoreId,
      showDebug: false,
      timeToWaitForATTUserAuthorization: 15,
    );
    _sdk = AppsflyerSdk(options);

    _sdk!.onInstallConversionData((raw) {
      final data = _extractPayload(raw);
      _conversion = data;
      flockLog(() => '[FEG.wing] conversion=$data');
      if (!_conversionReady.isCompleted) _conversionReady.complete();
    });

    _sdk!.onDeepLinking((raw) {
      final data = _extractDeepLink(raw);
      _deepLink = data;
      flockLog(() => '[FEG.wing] deepLink=$data');
      if (!_deepLinkReady.isCompleted) _deepLinkReady.complete();
    });

    await _sdk!.initSdk(
      registerConversionDataCallback: true,
      registerOnDeepLinkingCallback: true,
      registerOnAppOpenAttributionCallback: true,
    );
    _sdk!.startSDK(
      onError: (int code, String message) {
        flockLog(() => '[FEG.wing] start error $code: $message');
        // Never hang the boot on SDK errors (lesson #5).
        if (!_conversionReady.isCompleted) _conversionReady.complete();
      },
    );
    _sdkStarted = true;
  }

  Map<String, dynamic> _extractPayload(dynamic raw) {
    if (raw is Map) {
      final payload = raw['payload'] ?? raw['data'] ?? raw;
      if (payload is Map) return Map<String, dynamic>.from(payload);
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _extractDeepLink(dynamic raw) {
    if (raw is Map) {
      final dl = raw['deepLink'];
      if (dl is Map) return Map<String, dynamic>.from(dl);
    }
    return const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> awaitConversion({Duration? timeout}) async {
    if (!_sdkStarted) return const <String, dynamic>{};
    try {
      await _conversionReady.future.timeout(
        timeout ?? RookeryConfig.conversionWait,
      );
    } on TimeoutException {
      flockLog(() => '[FEG.wing] conversion timeout');
    }
    return _conversion ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> awaitDeepLink({Duration? timeout}) async {
    if (!_sdkStarted) return const <String, dynamic>{};
    try {
      await _deepLinkReady.future.timeout(
        timeout ?? RookeryConfig.deepLinkWait,
      );
    } on TimeoutException {
      // Deep link is optional; do not surface as error.
    }
    return _deepLink ?? const <String, dynamic>{};
  }

  Future<String?> currentUid() async {
    try {
      return await _sdk?.getAppsFlyerUID();
    } catch (_) {
      return null;
    }
  }

  /// Re-fetch attribution via the GCD REST API when the SDK returned
  /// `af_status: "Organic"` on a first launch (a known SDK bug on paid
  /// installs). Uses the NUMERIC store id, not the bundle id (lesson #11).
  Future<Map<String, dynamic>> gcdReconvert({String? deviceId}) async {
    if (deviceId == null || deviceId.isEmpty) return const <String, dynamic>{};
    if (!Platform.isIOS) return const <String, dynamic>{};

    final ua = await TalonAgent.instance.userAgent();
    final uri = Uri.parse(
      '${RookeryConfig.gcdBaseUrl}/install_data/v5.0/'
      '${RookeryConfig.platformStoreId}?device_id=$deviceId',
    );
    try {
      final resp = await TalonAgent.instance.client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer ${RookeryConfig.appsFlyerDevKey}',
              'User-Agent': ua,
            },
          )
          .timeout(RookeryConfig.configTimeout);
      flockLog(() => '[FEG.wing] gcd status=${resp.statusCode}');
      if (resp.statusCode != 200) return const <String, dynamic>{};
      final decoded = jsonDecode(resp.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on TimeoutException {
      flockLog(() => '[FEG.wing] gcd timeout');
    } catch (e) {
      flockLog(() => '[FEG.wing] gcd err=$e');
    }
    return const <String, dynamic>{};
  }

  /// Build the flat config-body per the API contract. Priority (first-write-
  /// wins for AppsFlyer sources, device fields overwrite):
  /// conversion > appOpen > deepLink > device.
  Future<Map<String, dynamic>> buildPayload({
    required String locale,
    String? pushToken,
  }) async {
    final body = <String, dynamic>{};

    void mergePutIfAbsent(Map<String, dynamic>? m) {
      if (m == null || m.isEmpty) return;
      m.forEach((k, v) => body.putIfAbsent(k, () => v));
    }

    // 1. install conversion (first-write-wins => write raw)
    if (_conversion != null && _conversion!.isNotEmpty) {
      body.addAll(_conversion!);
    }
    // 2. deep-link
    mergePutIfAbsent(_deepLink);

    // 3. device-side overwrites (rule §3 in gray_flow_guide.md)
    final afId = await currentUid();
    if (afId != null && afId.isNotEmpty) body['af_id'] = afId;
    body['bundle_id'] = RookeryConfig.bundleId;
    body['os'] = 'iOS';
    body['store_id'] = RookeryConfig.platformStoreId;
    body['locale'] = locale;

    if (pushToken != null && pushToken.isNotEmpty) {
      body['push_token'] = pushToken;
      body['firebase_project_id'] = RookeryConfig.firebaseProjectNumber;
    } else {
      // NEVER send empty/null sentinels for these keys — omit entirely.
      body.remove('push_token');
      body.remove('firebase_project_id');
    }

    return body;
  }

  /// Detect the organic false-positive scenario.
  bool get sawOrganicFalsePositive {
    final status = _conversion?['af_status']?.toString();
    return status == 'Organic';
  }

  /// True after AppsFlyer returned SOMETHING (even Organic). Used to decide
  /// whether a `mode=game` commit is safe: without a completed conversion
  /// callback we do NOT know if the install is organic yet.
  bool get conversionArrived =>
      _conversion != null && _conversion!.isNotEmpty;

  /// Raw `af_status` value from the SDK, if any.
  String? get afStatus => _conversion?['af_status']?.toString();
}

// Silence the unused import warning for `http` when this file compiles for
// non-iOS platforms during analysis.
// ignore: unused_element
void _pin() => http.Client;

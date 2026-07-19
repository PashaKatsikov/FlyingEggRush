import 'plume_stash.dart';

/// Central configuration for the gray flow. Identity, timings and endpoints
/// live here; every secret is decoded lazily through `PlumeStash`.
class RookeryConfig {
  static const String appTitle = 'Flying Egg Rush';
  static const String bundleId = 'com.flyingeggrush.flyingeggrushgame';

  /// Numeric App Store id (used to build `store_id: "id..."` in the
  /// config body and the GCD lookup URL).
  static const String iosStoreId = '6790466793';
  static String get platformStoreId => 'id$iosStoreId';

  /// Storage key prefix — unique per project (FINGERPRINT).
  static const String storagePrefix = 'feg.rookery';

  // Timing knobs
  static const Duration configTimeout = Duration(seconds: 15);
  static const Duration organicRetryDelay = Duration(seconds: 6);
  static const Duration conversionWait = Duration(seconds: 15);
  static const Duration deepLinkWait = Duration(seconds: 3);
  static const Duration pushCooldown = Duration(days: 3);
  static const Duration savedUrlValidity = Duration(hours: 12);

  // Endpoints (decoded on demand)
  static String get configEndpoint => PlumeStash.configEndpoint;
  static String get appsFlyerDevKey => PlumeStash.appsFlyerDevKey;
  static String get firebaseProjectNumber => PlumeStash.firebaseProjectNumber;
  static String get gcdBaseUrl => PlumeStash.gcdBaseUrl;
  static String get privacyUrl => PlumeStash.privacyUrl;
  static String get supportUrl => PlumeStash.supportUrl;

  /// The gray flow only activates if all THREE core credentials are present.
  /// Optional fields (privacy, support, GCD host) never disable the gate —
  /// they have defaults and the gate must still work without them (see
  /// gray_flow_lessons.md item 4).
  static bool get grayCredentialsReady =>
      configEndpoint.isNotEmpty &&
      appsFlyerDevKey.isNotEmpty &&
      firebaseProjectNumber.isNotEmpty;
}

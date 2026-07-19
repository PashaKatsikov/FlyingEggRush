import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/rookery_config.dart';
import '../models/perch_mode.dart';

/// Persistent state for the gray flow. Split between:
/// - SharedPreferences: mode, cooldowns, flags (fast, unencrypted).
/// - Keychain via flutter_secure_storage: content URL + expiry (sensitive).
class PerchVault {
  static const _kMode = '${RookeryConfig.storagePrefix}.mode';
  static const _kCooldown = '${RookeryConfig.storagePrefix}.invite_cooldown';
  static const _kOsDenied = '${RookeryConfig.storagePrefix}.os_denied';
  static const _kSavedUrl = '${RookeryConfig.storagePrefix}.saved_url';
  static const _kSavedExpires = '${RookeryConfig.storagePrefix}.saved_expires';
  static const _kOneShotUrl = '${RookeryConfig.storagePrefix}.one_shot_url';

  final _secure = const FlutterSecureStorage();

  Future<PerchMode> readMode() async {
    final prefs = await SharedPreferences.getInstance();
    return PerchModeCodec.fromKey(prefs.getString(_kMode));
  }

  Future<void> writeMode(PerchMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMode, mode.storageKey);
  }

  Future<void> writeSavedUrl(String url, {int? expiresAt}) async {
    await _secure.write(key: _kSavedUrl, value: url);
    if (expiresAt != null) {
      await _secure.write(
        key: _kSavedExpires,
        value: expiresAt.toString(),
      );
    }
  }

  Future<String?> readSavedUrl() async => _secure.read(key: _kSavedUrl);

  Future<int?> readSavedExpires() async {
    final raw = await _secure.read(key: _kSavedExpires);
    return raw == null ? null : int.tryParse(raw);
  }

  Future<bool> hasValidSavedUrl() async {
    final url = await readSavedUrl();
    if (url == null || url.isEmpty) return false;
    final exp = await readSavedExpires();
    if (exp == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 < exp;
  }

  Future<void> writeOneShotUrl(String url) async {
    await _secure.write(key: _kOneShotUrl, value: url);
  }

  Future<String?> consumeOneShotUrl() async {
    final v = await _secure.read(key: _kOneShotUrl);
    if (v != null) {
      await _secure.delete(key: _kOneShotUrl);
    }
    return v;
  }

  Future<bool> needsPushPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kOsDenied) == true) return false;
    final cooldownUntil = prefs.getInt(_kCooldown) ?? 0;
    return DateTime.now().millisecondsSinceEpoch >= cooldownUntil;
  }

  Future<void> writeInviteCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now()
        .add(RookeryConfig.pushCooldown)
        .millisecondsSinceEpoch;
    await prefs.setInt(_kCooldown, until);
  }

  Future<void> markOsDenied() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOsDenied, true);
  }
}

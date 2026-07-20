import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'config/rookery_config.dart';
import 'infra/chirp_hub.dart';
import 'infra/debug_flock.dart';
import 'infra/dispatch_relay.dart';
import 'infra/native_landing_bridge.dart';
import 'infra/perch_vault.dart';
import 'infra/sky_probe.dart';
import 'infra/wing_tracker.dart';
import 'models/dispatch_reply.dart';
import 'models/perch_mode.dart';

/// A single decision emitted by `RoostPilot.decide`.
sealed class RoostDestination {
  const RoostDestination();
}

class NestGameDestination extends RoostDestination {
  const NestGameDestination();
}

class NestWebDestination extends RoostDestination {
  final String url;
  final bool coldStartPush;
  const NestWebDestination(this.url, {this.coldStartPush = false});
}

class NestOfflineDestination extends RoostDestination {
  const NestOfflineDestination();
}

class NestPushPromptDestination extends RoostDestination {
  final String url;
  const NestPushPromptDestination(this.url);
}

/// Routing pipeline. `decide` is the whole brain: cold-start push handling,
/// connectivity gate, attribution, config exchange, mode persistence.
///
/// Contract:
/// - The future is CACHED to de-dupe concurrent calls (e.g. two rebuilds
///   during boot) but CLEARED on completion so the offline-retry button
///   re-runs the whole pipeline fresh (lesson #3).
/// - `fresh` mode is only demoted to `game` on a successful config response
///   with no URL. A network failure keeps the install `fresh` so a later
///   online launch can still reach the WebView.
class RoostPilot {
  RoostPilot({
    required this.vault,
    required this.wing,
    required this.sky,
    required this.dispatch,
    required this.chirp,
  });

  final PerchVault vault;
  final WingTracker wing;
  final SkyProbe sky;
  final DispatchRelay dispatch;
  final ChirpHub chirp;

  Future<RoostDestination>? _pending;

  Future<RoostDestination> decide() {
    return _pending ??= _run().whenComplete(() => _pending = null);
  }

  Future<RoostDestination> _run() async {
    if (!RookeryConfig.grayCredentialsReady) {
      flockLog(() => '[FEG.pilot] creds not ready → game');
      return const NestGameDestination();
    }

    // 1. Cold-start push tap — MUST run first (see cold_start_push_viewport.mdc).
    final tapUrl = await NativeLandingBridge.consumeTapUrl();
    if (tapUrl != null && tapUrl.isNotEmpty) {
      flockLog(() => '[FEG.pilot] cold-start push url=$tapUrl');
      await vault.writeMode(PerchMode.web);
      // Fire-and-forget attribution + config in the background so the URL is
      // reachable even before the SDK finishes warming up.
      unawaited(_fireAndForgetBackgroundDispatch());
      return NestWebDestination(tapUrl, coldStartPush: true);
    }

    final mode = await vault.readMode();
    flockLog(() => '[FEG.pilot] mode=$mode');

    // Fast path — no network interface at all (airplane mode / Wi-Fi off).
    // Never trigger a reach probe here (gray_flow_lessons.md #2).
    final tGate = DateTime.now();
    final hasIf = await sky.hasInterface();
    flockLog(() =>
        '[FEG.pilot] hasInterface=$hasIf t=${DateTime.now().difference(tGate).inMilliseconds}ms');
    if (!hasIf) {
      return _offlineFallback(mode);
    }

    // Interface exists — validate REAL reachability with a raw TCP probe.
    // DNS on iOS caches aggressively (a stale apple.com record can resolve
    // while the device is fully offline); a TCP connect to a public anycast
    // IP is the only reliable signal.
    final tReach = DateTime.now();
    final reachable = await sky.canReachNetwork();
    flockLog(() =>
        '[FEG.pilot] canReachNetwork=$reachable t=${DateTime.now().difference(tReach).inMilliseconds}ms');
    if (!reachable) {
      return _offlineFallback(mode);
    }

    switch (mode) {
      case PerchMode.web:
        return _handleWebReturn();
      case PerchMode.game:
        return _handleGameReturn();
      case PerchMode.fresh:
        return _handleFresh();
    }
  }

  Future<RoostDestination> _offlineFallback(PerchMode mode) async {
    // fresh: user hasn't seen the WebView yet and we cannot decide organic
    // without attribution, so show NoWind and let retry re-run the pipeline.
    // web: fall back to the last-known-good URL if we have one; else NoWind.
    // game: established organic install works offline.
    if (mode == PerchMode.game) return const NestGameDestination();
    if (mode == PerchMode.web) {
      final saved = await vault.readSavedUrl();
      if (saved != null && saved.isNotEmpty) {
        return NestWebDestination(saved);
      }
    }
    return const NestOfflineDestination();
  }

  Future<RoostDestination> _handleFresh() async {
    unawaited(chirp.bootstrap());
    await wing.warmup();
    await wing.awaitConversion();
    if (wing.sawOrganicFalsePositive) {
      final uid = await wing.currentUid();
      await Future<void>.delayed(RookeryConfig.organicRetryDelay);
      final rescued = await wing.gcdReconvert(deviceId: uid);
      flockLog(() => '[FEG.pilot] GCD rescued=${rescued.isNotEmpty}');
    }
    await wing.awaitDeepLink();
    final pushToken = await chirp.tryReadToken();
    var body = await wing.buildPayload(
      locale: _locale(),
      pushToken: pushToken,
    );
    var reply = await dispatch.send(body);

    // If the first request was fired before AppsFlyer produced a conversion
    // callback (`awaitConversion` returned by timeout) the server most likely
    // answered 404 "No data" because the body carried no attribution. If the
    // conversion has since materialised, retry ONCE with the full payload.
    final bodyIsBare = !body.containsKey('af_status');
    if (!reply.hasDestination &&
        !reply.transportFailed &&
        bodyIsBare &&
        wing.conversionArrived) {
      flockLog(() => '[FEG.pilot] late conversion → dispatch retry');
      body = await wing.buildPayload(
        locale: _locale(),
        pushToken: pushToken,
      );
      reply = await dispatch.send(body);
    }
    return _commitFreshReply(reply);
  }

  Future<RoostDestination> _commitFreshReply(DispatchReply reply) async {
    // Transport failure on a fresh install → NEVER commit game and NEVER
    // downgrade to organic. Show the offline screen; retry re-runs the whole
    // pipeline (fresh + no-internet-yet install must remain fresh).
    if (reply.transportFailed) {
      flockLog(() => '[FEG.pilot] fresh dispatch transport-fail → offline');
      return const NestOfflineDestination();
    }
    if (!reply.hasDestination) {
      // Server actually answered `ok:false`. Commit `game` ONLY when we are
      // sure the install was organic:
      // 1) AppsFlyer already delivered a conversion callback, AND
      // 2) `af_status` is NOT Non-organic.
      // Otherwise keep the install `fresh` for the next launch.
      final gotConversion = wing.conversionArrived;
      final nonOrganic = wing.afStatus == 'Non-organic';
      final safeToCommitGame = gotConversion && !nonOrganic;
      if (safeToCommitGame) {
        await vault.writeMode(PerchMode.game);
      } else {
        flockLog(() =>
            '[FEG.pilot] keep fresh (conv=$gotConversion nonOrg=$nonOrganic)');
      }
      return const NestGameDestination();
    }
    await vault.writeMode(PerchMode.web);
    await vault.writeSavedUrl(reply.destination!, expiresAt: reply.expiresAt);
    return _webWithMaybePrompt(reply.destination!);
  }

  Future<RoostDestination> _handleWebReturn() async {
    unawaited(chirp.bootstrap());

    // One-shot URL (e.g. from a push received in background).
    final oneShot = await vault.consumeOneShotUrl();
    if (oneShot != null && oneShot.isNotEmpty) {
      return _webWithMaybePrompt(oneShot);
    }

    // If the saved URL is still valid we may skip the network call.
    final saved = await vault.readSavedUrl();
    final valid = await vault.hasValidSavedUrl();

    await wing.warmup();
    await wing.awaitConversion();
    await wing.awaitDeepLink();
    final pushToken = await chirp.tryReadToken();
    final body = await wing.buildPayload(
      locale: _locale(),
      pushToken: pushToken,
    );
    final reply = await dispatch.send(body);
    if (reply.hasDestination) {
      await vault.writeSavedUrl(reply.destination!, expiresAt: reply.expiresAt);
      return _webWithMaybePrompt(reply.destination!);
    }
    // Failure: keep the last-known-good URL (never fall to the game once we
    // were already gray). Only if we have nothing do we show offline.
    if (saved != null && saved.isNotEmpty) {
      return NestWebDestination(saved);
    }
    if (valid) {
      return NestWebDestination(saved ?? '');
    }
    return const NestOfflineDestination();
  }

  Future<RoostDestination> _handleGameReturn() async {
    // Established organic install: game works offline. A network probe here
    // is only useful for potentially flipping game→web later, so we don't
    // block on it — the game must show immediately (Airplane-mode users
    // should NOT wait on config.php).
    unawaited(_backgroundGameToWebRetry());
    return const NestGameDestination();
  }

  Future<void> _backgroundGameToWebRetry() async {
    try {
      unawaited(chirp.bootstrap());
      await wing.warmup();
      await wing.awaitConversion();
      await wing.awaitDeepLink();
      final pushToken = await chirp.tryReadToken();
      final body = await wing.buildPayload(
        locale: _locale(),
        pushToken: pushToken,
      );
      final reply = await dispatch.send(body);
      if (reply.hasDestination) {
        await vault.writeMode(PerchMode.web);
        await vault.writeSavedUrl(
          reply.destination!,
          expiresAt: reply.expiresAt,
        );
      }
    } catch (e) {
      flockLog(() => '[FEG.pilot] bg game→web err=$e');
    }
  }

  Future<RoostDestination> _webWithMaybePrompt(String url) async {
    final needsPrompt = await vault.needsPushPrompt();
    if (!needsPrompt) return NestWebDestination(url);
    // If the OS already has a decision (denied / authorized / provisional),
    // our opt-in screen is redundant — persist that so we never re-render it.
    // Only `notDetermined` warrants the promo.
    if (await chirp.currentlyAuthorized()) {
      await vault.markInviteAccepted();
      return NestWebDestination(url);
    }
    if (await chirp.currentlyDenied()) {
      await vault.markOsDenied();
      return NestWebDestination(url);
    }
    return NestPushPromptDestination(url);
  }

  Future<void> _fireAndForgetBackgroundDispatch() async {
    try {
      await wing.warmup();
      await wing.awaitConversion();
      await wing.awaitDeepLink();
      final pushToken = await chirp.tryReadToken();
      final body = await wing.buildPayload(
        locale: _locale(),
        pushToken: pushToken,
      );
      final reply = await dispatch.send(body);
      if (reply.hasDestination) {
        await vault.writeSavedUrl(
          reply.destination!,
          expiresAt: reply.expiresAt,
        );
      }
    } catch (e) {
      flockLog(() => '[FEG.pilot] bg dispatch err=$e');
    }
  }

  String _locale() {
    final l = PlatformDispatcher.instance.locale;
    final country = l.countryCode;
    if (country == null || country.isEmpty) return l.languageCode;
    return '${l.languageCode}_$country';
  }
}

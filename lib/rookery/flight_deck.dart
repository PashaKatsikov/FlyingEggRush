import 'package:flutter/material.dart';

import '../theme.dart';
import 'infra/chirp_hub.dart';
import 'infra/dispatch_relay.dart';
import 'infra/perch_vault.dart';
import 'infra/sky_probe.dart';
import 'infra/wing_tracker.dart';
import 'models/perch_mode.dart';
import 'pages/nest_boot.dart';
import 'pages/sky_portal.dart';
import 'roost_pilot.dart';

/// Root MaterialApp for the whole binary. Boots into `NestBoot`, which then
/// decides whether to show the game (organic) or the WebView (non-organic).
class FlightDeckApp extends StatefulWidget {
  const FlightDeckApp({super.key});

  @override
  State<FlightDeckApp> createState() => _FlightDeckAppState();
}

class _FlightDeckAppState extends State<FlightDeckApp> {
  late final PerchVault _vault;
  late final RoostPilot _pilot;
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _vault = PerchVault();
    _pilot = RoostPilot(
      vault: _vault,
      wing: WingTracker(),
      sky: const SkyProbe(),
      dispatch: const DispatchRelay(),
      chirp: ChirpHub.instance,
    );
    ChirpHub.instance.onPushOpenUrl = _handlePushOpenUrl;
  }

  Future<void> _handlePushOpenUrl(String url) async {
    // Persist for a possible restart AND route immediately if we have a
    // live navigator (app is in foreground/background, not killed).
    await _vault.writeOneShotUrl(url);
    await _vault.writeMode(PerchMode.web);
    final nav = _navKey.currentState;
    if (nav == null) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SkyPortal(url: url, vault: _vault),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'Flying Egg Rush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          brightness: Brightness.light,
        ),
        fontFamily: 'Georgia',
      ),
      home: NestBoot(pilot: _pilot, vault: _vault),
    );
  }
}

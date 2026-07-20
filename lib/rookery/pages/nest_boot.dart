import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/magazine.dart';
import '../../main.dart' show store;
import '../../screens/newsstand_screen.dart';
import '../../theme.dart';
import '../infra/chirp_hub.dart';
import '../infra/debug_flock.dart';
import '../infra/perch_vault.dart';
import '../roost_pilot.dart';
import 'no_wind_page.dart';
import 'sky_portal.dart';
import 'wing_invitation.dart';

/// The single loading + routing entrypoint.
///
/// - Runs `RoostPilot.decide` and the game's own init in parallel.
/// - Shows the same visual as the pre-existing loading screen (bg vertical/
///   horizontal + logo + bar) so no jarring switch happens between organic
///   splash and the gray decision.
/// - Kicks off ATT dialog AFTER the first frame (silent-drop rule).
class NestBoot extends StatefulWidget {
  const NestBoot({super.key, required this.pilot, required this.vault});

  final RoostPilot pilot;
  final PerchVault vault;

  @override
  State<NestBoot> createState() => _NestBootState();
}

class _NestBootState extends State<NestBoot> with TickerProviderStateMixin {
  late final AnimationController _bar;
  Timer? _dotsTimer;
  int _dots = 0;
  bool _navigated = false;
  bool _gameReady = false;
  RoostDestination? _decision;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _bar = AnimationController(
      vsync: this,
      // Two-phase fill: first phase goes 0 → 0.9 slowly over ~5s while we're
      // waiting for AppsFlyer + config, second phase (in `_finishIfReady`)
      // does 0.9 → 1.0. Bounds MUST be 0..1 — using upperBound 0.9 and then
      // animateTo(1.0) is undefined behaviour and can silently clamp.
      duration: const Duration(milliseconds: 5000),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..animateTo(0.9, duration: const Duration(milliseconds: 5000))
        .whenComplete(_finishIfReady);
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (mounted) setState(() => _dots = (_dots + 1) % 4);
    });
    _kick();
  }

  Future<void> _kick() async {
    unawaited(_askAttAfterFirstFrame());
    unawaited(_warmGameCaches());
    try {
      final decision = await widget.pilot.decide();
      _decision = decision;
    } catch (e) {
      flockLog(() => '[FEG.boot] pilot err=$e → game');
      _decision = const NestGameDestination();
    }
    // Offline path must show NoWind immediately — no reason to sit through
    // the 5s splash-bar fill when the pilot decided in <1s.
    if (_decision is NestOfflineDestination) {
      _navigateFast();
      return;
    }
    _finishIfReady();
  }

  void _navigateFast() {
    if (_navigated) return;
    if (_decision == null) return;
    _navigated = true;
    _bar.stop();
    if (!mounted) return;
    _routeToDecision(_decision!);
  }

  Future<void> _askAttAfterFirstFrame() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      await AppTrackingTransparency.requestTrackingAuthorization();
    } catch (_) {
      // Non-iOS platforms or user rejection — ignore.
    }
  }

  Future<void> _warmGameCaches() async {
    try {
      await store.load();
      if (!mounted) return;
      for (final issue in kIssues) {
        await precacheImage(AssetImage(issue.breed.asset), context);
        if (!mounted) return;
      }
      await precacheImage(const AssetImage(AppAssets.egg), context);
      if (!mounted) return;
      await precacheImage(const AssetImage(AppAssets.bgVertical), context);
      if (!mounted) return;
      await precacheImage(const AssetImage(AppAssets.bgHorizontal), context);
      if (!mounted) return;
      await precacheImage(const AssetImage(AppAssets.logo), context);
    } catch (_) {
      // Don't let asset warmup block routing.
    }
    _gameReady = true;
    _finishIfReady();
  }

  Future<void> _finishIfReady() async {
    if (_navigated) return;
    if (_decision == null) return;
    // For gray branches we don't need the game caches to be ready.
    if (_decision is NestGameDestination && !_gameReady) return;
    if (_bar.value < 0.9) return;
    _navigated = true;

    // Bar must be visibly full before the transition begins, then a short
    // deliberate pause (~0.5s) so the user perceives the "done" moment,
    // then we navigate. No launching before 100%, no long dwell after.
    await _bar.animateTo(
      1.0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _routeToDecision(_decision!);
  }

  void _routeToDecision(RoostDestination d) {
    switch (d) {
      case NestGameDestination():
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
        ]);
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, a, _) => FadeTransition(
              opacity: a,
              child: const NewsstandScreen(),
            ),
          ),
        );
      case NestWebDestination(:final url, :final coldStartPush):
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SkyPortal(
              url: url,
              vault: widget.vault,
              coldStartPush: coldStartPush,
              onNeedOffline: () => _rebootTo(
                (_) => NoWindPage(retryBuilder: (ctx) => _selfRebuild(ctx)),
              ),
            ),
          ),
        );
      case NestOfflineDestination():
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => NoWindPage(retryBuilder: _selfRebuild),
          ),
        );
      case NestPushPromptDestination(:final url):
        final vault = widget.vault;
        final selfRebuild = _selfRebuild;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (inviteCtx) => WingInvitation(
              vault: vault,
              chirp: ChirpHub.instance,
              onDone: (_) async {
                if (!inviteCtx.mounted) return;
                Navigator.of(inviteCtx).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => SkyPortal(
                      url: url,
                      vault: vault,
                      onNeedOffline: () => Navigator.of(inviteCtx)
                          .pushReplacement(MaterialPageRoute(
                        builder: (_) =>
                            NoWindPage(retryBuilder: selfRebuild),
                      )),
                    ),
                  ),
                );
              },
            ),
          ),
        );
    }
  }

  void _rebootTo(WidgetBuilder builder) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: builder));
  }

  Widget _selfRebuild(BuildContext _) {
    return NestBoot(pilot: widget.pilot, vault: widget.vault);
  }

  @override
  void dispose() {
    _dotsTimer?.cancel();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                isPortrait ? AppAssets.bgVertical : AppAssets.bgHorizontal,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x22000000), Color(0x66000000)],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isPortrait ? 32 : 80,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(),
                      Image.asset(
                        AppAssets.logo,
                        width: isPortrait
                            ? MediaQuery.of(context).size.width * 0.72
                            : MediaQuery.of(context).size.height * 0.6,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                      _BootBar(controller: _bar),
                      const SizedBox(height: 14),
                      Text(
                        'Loading${'.' * _dots}',
                        style: AppText.body(18, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BootBar extends StatelessWidget {
  const _BootBar({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Container(
        height: 22,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0x55000000),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cream, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => FractionallySizedBox(
                widthFactor: controller.value.clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.deepGold,
                        AppColors.gold,
                        Color(0xFFFFE08A),
                      ],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

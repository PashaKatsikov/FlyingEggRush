import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/magazine.dart';
import '../main.dart';
import '../theme.dart';
import 'newsstand_screen.dart';

/// Adaptive splash / loading screen.
///
/// * Works in BOTH portrait and landscape (background + logo swap to match).
/// * Shows a horizontal left-to-right progress bar that only reaches 100%
///   right before the game actually launches.
/// * Shows an animated "Loading" label with cycling dots.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _barController;
  Timer? _dotsTimer;
  int _dots = 0;
  bool _initDone = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // The loading screen is the only place we allow landscape.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Drive the bar to 90% over a comfortable minimum display time, then it
    // waits for the real work to finish before topping up to 100%.
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
      lowerBound: 0.0,
      upperBound: 0.9,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _maybeFinish();
      })
      ..forward();

    _dotsTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (mounted) setState(() => _dots = (_dots + 1) % 4);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Real initialisation work: warm the image cache + load saved progress.
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

    _initDone = true;
    _maybeFinish();
  }

  /// Only top the bar up to a full 100% once the animation reached 90% AND the
  /// real init finished — the completed fill signals the imminent launch.
  Future<void> _maybeFinish() async {
    if (_navigated) return;
    if (!_initDone || _barController.value < 0.9) return;
    _navigated = true;

    // Fill the final 10% right before launching.
    await _barController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
    await Future<void>.delayed(const Duration(milliseconds: 220));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, a, _) =>
            FadeTransition(opacity: a, child: const NewsstandScreen()),
      ),
    );
  }

  @override
  void dispose() {
    _dotsTimer?.cancel();
    _barController.dispose();
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
              // Soft scrim so the logo and bar stay readable over the art.
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
                      _LoadingBar(controller: _barController),
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

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.controller});

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
              builder: (context, _) {
                return FractionallySizedBox(
                  // Left-to-right fill.
                  widthFactor: controller.value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.deepGold, AppColors.gold, Color(0xFFFFE08A)],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

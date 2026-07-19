import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// "No signal" screen. Ships an orientation-aware background artwork with
/// a single Retry button.
///
/// IMPORTANT: `retryBuilder` receives a fresh `BuildContext` and returns the
/// widget to navigate to (typically `NestBoot()`). We do NOT capture the
/// parent context (lesson #3, symptom A) — that would crash with
/// "defunct widget context" once the parent tree is disposed.
class NoWindPage extends StatefulWidget {
  const NoWindPage({super.key, required this.retryBuilder});

  final WidgetBuilder retryBuilder;

  @override
  State<NoWindPage> createState() => _NoWindPageState();
}

class _NoWindPageState extends State<NoWindPage> {
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _onRetry() {
    if (_tapped) return;
    _tapped = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: widget.retryBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;
          final asset = isPortrait
              ? 'assets/Vertical_Nowifi_Screen.webp'
              : 'assets/Horizontal_Nowifi_Screen.webp';
          final size = MediaQuery.of(context).size;
          final btnWidth = isPortrait
              ? (size.width * 0.70).clamp(220.0, 380.0)
              : (size.width * 0.35).clamp(180.0, 320.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                asset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              SafeArea(
                minimum: EdgeInsets.only(
                  bottom: isPortrait ? 24 : 16,
                ),
                child: Align(
                  alignment: isPortrait
                      ? const Alignment(0, 0.92)
                      : const Alignment(0, 0.88),
                  child: SizedBox(
                    width: btnWidth,
                    height: 56,
                    child: _RetryButton(onPressed: _onRetry),
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

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD866), Color(0xFFE08A1E)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: const Center(
            child: Text(
              'Retry',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3A2A17),
                height: 1.0,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

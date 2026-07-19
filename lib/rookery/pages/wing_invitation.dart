import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../infra/chirp_hub.dart';
import '../infra/perch_vault.dart';

/// Push permission opt-in screen (background art + Accept + Skip).
///
/// Accept → asks the system push permission, then forwards to
/// [onDone] with the FCM/APNs token that came back (may be null).
/// Skip → sets a cooldown so we don't re-prompt for
/// `RookeryConfig.pushCooldown`, then calls [onDone] with null.
class WingInvitation extends StatefulWidget {
  const WingInvitation({
    super.key,
    required this.vault,
    required this.chirp,
    required this.onDone,
  });

  final PerchVault vault;
  final ChirpHub chirp;
  final Future<void> Function(String? freshToken) onDone;

  @override
  State<WingInvitation> createState() => _WingInvitationState();
}

class _WingInvitationState extends State<WingInvitation> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    // Record the accept decision BEFORE showing the system dialog so we
    // never re-show this screen even if the user backgrounds the app on
    // top of the OS prompt (gray_flow_guide.md §push opt-in).
    await widget.vault.markInviteAccepted();
    await widget.chirp.askPermission();
    final token = await widget.chirp.waitForTokenAfterConsent();
    if (!mounted) return;
    await widget.onDone(token);
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.vault.writeInviteCooldown();
    if (!mounted) return;
    await widget.onDone(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;
          final asset = isPortrait
              ? 'assets/Vertical_Notifications_Screen.webp'
              : 'assets/Horizontal_Notifications_Screen.webp';
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
                  child: _ButtonStack(
                    isPortrait: isPortrait,
                    onAccept: _accept,
                    onSkip: _skip,
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

class _ButtonStack extends StatelessWidget {
  const _ButtonStack({
    required this.isPortrait,
    required this.onAccept,
    required this.onSkip,
  });

  final bool isPortrait;
  final VoidCallback onAccept;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final btnWidth = isPortrait
        ? (width * 0.72).clamp(230.0, 380.0)
        : (width * 0.36).clamp(200.0, 320.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: btnWidth,
          height: 56,
          child: _GradientButton(
            label: 'Allow notifications',
            colors: const [Color(0xFFFFD866), Color(0xFFE08A1E)],
            onPressed: onAccept,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: btnWidth,
          height: 52,
          child: _GradientButton(
            label: 'Skip',
            colors: const [Color(0xFF5B7CA6), Color(0xFF2E5E86)],
            onPressed: onSkip,
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final List<Color> colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
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
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
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

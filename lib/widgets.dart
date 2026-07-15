import 'package:flutter/material.dart';

import 'theme.dart';

/// A chunky folk-art styled button used across all menus.
class FolkButton extends StatefulWidget {
  const FolkButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.cherry,
    this.icon,
    this.width,
    this.height = 62,
    this.fontSize = 22,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;
  final double? width;
  final double height;
  final double fontSize;
  final bool enabled;

  @override
  State<FolkButton> createState() => _FolkButtonState();
}

class _FolkButtonState extends State<FolkButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.enabled ? widget.color : Colors.grey.shade500;
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: widget.enabled ? () => setState(() => _down = false) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _down = false);
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(base, Colors.white, 0.22)!,
                base,
                Color.lerp(base, Colors.black, 0.22)!,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cream, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: widget.fontSize + 4),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.label,
                  style: AppText.title(widget.fontSize),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small round icon button (used for info / policy links).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = AppColors.folkBlue,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: CircleBorder(
        side: const BorderSide(color: AppColors.cream, width: 2.5),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }
}

/// A small pill that shows a value with an icon (coins, best score...).
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    this.color = AppColors.folkBlue,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.cream, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 6),
          Text(value, style: AppText.body(16, color: Colors.white)),
        ],
      ),
    );
  }
}

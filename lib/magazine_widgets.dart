import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets.dart';

/// The newspaper nameplate: "The Chicken Times", flanked by rules, with an
/// optional date/issue line. Used big on the newsstand and small on pages.
class Masthead extends StatelessWidget {
  const Masthead({
    super.key,
    this.size = 34,
    this.dateLine,
    this.color = AppColors.ink,
    this.onPaper = true,
  });

  final double size;
  final String? dateLine;
  final Color color;
  final bool onPaper;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _rule(color)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('🐔', style: TextStyle(fontSize: 16)),
            ),
            Expanded(child: _rule(color)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'The Chicken Times',
          textAlign: TextAlign.center,
          style: AppText.masthead(size, color: color, spacing: 0.5),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _rule(color)),
            if (dateLine != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  dateLine!.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: size * 0.28,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ),
            Expanded(child: _rule(color)),
          ],
        ),
      ],
    );
  }

  Widget _rule(Color c) => Container(height: 2.5, color: c);
}

/// Caps the reading width of long-form content on large screens (iPad) so
/// text lines and cards don't stretch edge-to-edge awkwardly, while staying
/// full-width on phones.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 640,
  });
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Sliver counterpart of [ResponsiveContent]: centers its sliver child inside
/// a [CustomScrollView] by adding equal side padding, instead of pinning it
/// to the leading edge like [SliverConstrainedCrossAxis] does.
class CenteredSliver extends StatelessWidget {
  const CenteredSliver({super.key, required this.sliver, this.maxWidth = 640});
  final Widget sliver;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final inset = width > maxWidth ? (width - maxWidth) / 2 : 0.0;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      sliver: sliver,
    );
  }
}

/// A reusable "magazine page" scaffold: aged-paper background, a thin printed
/// frame, a compact masthead header with a back button, section label, and the
/// page title — then your body.
class MagazinePage extends StatelessWidget {
  const MagazinePage({
    super.key,
    required this.sectionLabel,
    required this.title,
    required this.child,
    this.accent = AppColors.cherry,
    this.actions,
    this.subtitle,
  });

  final String sectionLabel;
  final String title;
  final String? subtitle;
  final Widget child;
  final Color accent;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    color: AppColors.ink,
                    size: 40,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'The Chicken Times',
                      style: AppText.masthead(16, color: AppColors.inkSoft),
                    ),
                  ),
                  ...?actions,
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(height: 2, color: AppColors.ink),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 40),
                child: ResponsiveContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionChip(label: sectionLabel, color: accent),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: AppText.masthead(30, color: AppColors.ink),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: AppText.serif(
                            15,
                            color: AppColors.inkSoft,
                            style: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionChip extends StatelessWidget {
  const SectionChip({
    super.key,
    required this.label,
    this.color = AppColors.cherry,
  });
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Long-form body copy with a decorative drop-cap on the first paragraph — the
/// classic magazine reading touch.
class DropCapText extends StatelessWidget {
  const DropCapText({
    super.key,
    required this.paragraphs,
    this.accent = AppColors.cherry,
  });
  final List<String> paragraphs;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final first = paragraphs.first;
    final cap = first.isNotEmpty ? first.characters.first : '';
    final rest = first.length > 1 ? first.substring(1) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    cap,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 58,
                      height: 0.9,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ),
              ),
              TextSpan(text: rest, style: AppText.serif(17)),
            ],
          ),
        ),
        for (final p in paragraphs.skip(1)) ...[
          const SizedBox(height: 14),
          Text(p, style: AppText.serif(17)),
        ],
      ],
    );
  }
}

/// A framed "moral of the story" call-out.
class MoralBox extends StatelessWidget {
  const MoralBox({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.deepGold, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌟', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Moral: $text',
              style: AppText.serif(15, weight: FontWeight.w700, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

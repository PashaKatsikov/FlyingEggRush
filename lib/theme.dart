import 'package:flutter/material.dart';

/// Central place for asset paths and the folk-art palette so the whole game
/// keeps one consistent look.
class AppAssets {
  static const bgVertical = 'assets/bg_vertical.jpg';
  static const bgHorizontal = 'assets/bg_horizontal.jpg';
  static const logo = 'assets/logo.webp';
  static const icon = 'assets/icon.jpg';

  static const egg = 'assets/icon.jpg'; // the golden winged egg (default hero)
  static const leghorn = 'assets/leghorn.webp';
  static const brahma = 'assets/brahma.webp';
  static const silkie = 'assets/silkie.webp';
  static const ameraucana = 'assets/ameraucana.webp';
  static const buff = 'assets/buff.webp';
}

class AppColors {
  static const sky = Color(0xFF7EC8E3);
  static const cream = Color(0xFFF7ECD2);
  static const paper = Color(0xFFF4E8CC);
  static const paperEdge = Color(0xFFE7D6AC);
  static const gold = Color(0xFFF2B233);
  static const deepGold = Color(0xFFE08A1E);
  static const cherry = Color(0xFFC33A22);
  static const folkBlue = Color(0xFF2E5E86);
  static const teal = Color(0xFF2E7D8A);
  static const ink = Color(0xFF3A2A17);
  static const inkSoft = Color(0xFF6B5540);
  static const leaf = Color(0xFF6E9E3E);
}

class AppText {
  static TextStyle title(double size, {Color color = Colors.white}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 0.5,
        height: 1.05,
        shadows: const [
          Shadow(color: Color(0xAA3A2A17), blurRadius: 6, offset: Offset(0, 3)),
        ],
      );

  static TextStyle body(double size,
          {Color color = Colors.white, FontWeight weight = FontWeight.w700}) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        shadows: const [
          Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      );

  /// Newspaper-style display used for the masthead and big headings. No shadow,
  /// tight tracking — clean editorial look on paper.
  static TextStyle masthead(double size,
          {Color color = AppColors.ink, double spacing = 1.0}) =>
      TextStyle(
        fontFamily: 'Georgia',
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: spacing,
        height: 1.0,
      );

  /// Serif body copy for reading long-form articles on paper.
  static TextStyle serif(double size,
          {Color color = AppColors.ink,
          FontWeight weight = FontWeight.w500,
          double height = 1.5,
          FontStyle style = FontStyle.normal}) =>
      TextStyle(
        fontFamily: 'Georgia',
        fontSize: size,
        fontWeight: weight,
        fontStyle: style,
        color: color,
        height: height,
      );
}

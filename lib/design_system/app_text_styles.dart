import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  /// Heading / UI typeface — confident tight grotesk (CoinFlo Hi-Fi).
  static const String uiFont = 'SchibstedGrotesk';

  // Display — large balance numbers (JetBrains Mono for finance identity)
  static const TextStyle displayXL = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle displayL = TextStyle(
    fontFamily: uiFont,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.1,
  );

  // Headings
  static const TextStyle headingL = TextStyle(
    fontFamily: uiFont,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );
  static const TextStyle headingM = TextStyle(
    fontFamily: uiFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static const TextStyle headingS = TextStyle(
    fontFamily: uiFont,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  // Body
  static const TextStyle bodyL = TextStyle(
    fontFamily: uiFont,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.41,
  );
  static const TextStyle bodyM = TextStyle(
    fontFamily: uiFont,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.47,
  );
  static const TextStyle bodyS = TextStyle(
    fontFamily: uiFont,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.38,
  );

  // Labels
  static const TextStyle labelM = TextStyle(
    fontFamily: uiFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
  static const TextStyle labelS = TextStyle(
    fontFamily: uiFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
  );

  /// Uppercase section eyebrow — `.sec` in the Hi-Fi system.
  static const TextStyle section = TextStyle(
    fontFamily: uiFont,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: Color(0xFFA0A0A0),
  );

  // Numeric — amounts, always tabular (JetBrains Mono for finance identity)
  static const TextStyle numericL = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle numericM = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 15,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display — large balance numbers (JetBrains Mono for finance identity)
  static const TextStyle displayXL = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle displayL = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Headings
  static const TextStyle headingL = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static const TextStyle headingM = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static const TextStyle headingS = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  // Body
  static const TextStyle bodyL = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.41,
  );
  static const TextStyle bodyM = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.47,
  );
  static const TextStyle bodyS = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.38,
  );

  // Labels
  static const TextStyle labelM = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
  static const TextStyle labelS = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
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

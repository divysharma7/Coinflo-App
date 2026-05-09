import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/enums.dart';

// ---------------------------------------------------------------------------
// Pulse Design Tokens v1.2
// Dark-first, OLED-friendly, Cred-inspired.
// ---------------------------------------------------------------------------

/// Colour palette.
abstract final class PaisaColors {
  // -- Backgrounds --
  static const Color scaffold = Color(0xFF000000);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceHigh = Color(0xFF1E1E1E);

  // Legacy aliases (widgets still referencing these)
  static const Color surfaceElevated = surfaceHigh;
  static const Color surfaceSecondary = surface;

  // -- Borders --
  static const Color border = Color(0xFF2A2A2A);

  // -- Text --
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9999A3);
  static const Color textTertiary = Color(0xFF606060);

  // -- Primary accents --
  static const Color yellow = Color(0xFFFFD60A);
  static const Color yellowShadow = Color(0xFFB8A000);
  static const Color gold = Color(0xFFC9A84C);
  static const Color amber = Color(0xFFF5A623);

  // -- Semantic --
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFFF5252);
  static const Color splitPending = Color(0xFFFF9800);

  // -- Legacy aliases --
  static const Color accentYellow = yellow;
  static const Color accentGold = gold;
  static const Color accentAmber = amber;
  static const Color accentBlue = Color(0xFF4DA8FF);
  static const Color accentGreen = income;
  static const Color accentRed = expense;
  static const Color accentPurple = Color(0xFF8E7AAF);
  static const Color neoPopShadow = yellowShadow;

  // -- Category accents (muted, never full saturation) --
  static const Map<TransactionCategory, Color> categoryActive = {
    TransactionCategory.rent: Color(0xFF7B8FA1),
    TransactionCategory.transport: Color(0xFF6B8F71),
    TransactionCategory.food: Color(0xFFA0785A),
    TransactionCategory.family: Color(0xFFC9A84C),
    TransactionCategory.social: Color(0xFF8E7AAF),
    TransactionCategory.other: Color(0xFF7A7A7A),
  };

  static const Color categoryMuted = Color(0xFF3A3A3A);

  static Color categoryColor(TransactionCategory cat) =>
      categoryActive[cat] ?? const Color(0xFF7A7A7A);

  // -- Semantic (legacy) --
  static const Color success = income;
  static const Color warning = amber;
  static const Color error = expense;
  static const Color info = accentBlue;
}

/// Typography styles.
abstract final class PaisaTextStyles {
  static const TextStyle heroSymbol = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,
    color: PaisaColors.textSecondary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle heroAmount = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w700,
    color: PaisaColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -2.0,
    height: 1,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: PaisaColors.textTertiary,
    letterSpacing: 1.5,
  );

  static const TextStyle merchantName = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: PaisaColors.textPrimary,
  );

  static const TextStyle pillLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle emptyState = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: PaisaColors.textSecondary,
    height: 1.6,
  );

  static const TextStyle greeting = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: PaisaColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle insightBody = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: PaisaColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle onboardingHeadline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: PaisaColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle onboardingBody = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: PaisaColors.textSecondary,
    height: 1.6,
  );
}

/// Spacing scale (8-pt grid).
abstract final class PaisaSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double cardPadding = 16;
  static const double screenH = 16;
  static const double screenTop = 24;
  static const double cardGap = 12;
}

/// Corner radii.
abstract final class PaisaRadii {
  static const double card = 16;
  static const double sheet = 24;
  static const double pill = 100;
  static const double button = 12;
  static const double barTop = 6;
  static const double fab = 28;
}

/// Typography sizes (kept for widgets using raw sizes).
abstract final class PaisaTypo {
  static const double heroSize = 64;
  static const FontWeight heroWeight = FontWeight.w700;
  static const double symbolSize = 28;
  static const FontWeight symbolWeight = FontWeight.w300;
  static const double titleSize = 20;
  static const FontWeight titleWeight = FontWeight.w600;
  static const double bodySize = 15;
  static const FontWeight bodyWeight = FontWeight.w400;
  static const double captionSize = 10;
  static const FontWeight captionWeight = FontWeight.w600;
  static const double microSize = 10;
  static const FontWeight microWeight = FontWeight.w500;
  static const double subHeroSize = 28;
  static const FontWeight subHeroWeight = FontWeight.w700;
  static const double subSymbolSize = 14;
}

/// Animation durations & curves.
abstract final class PaisaMotion {
  // Micro-interactions (button press, toggle)
  static const Duration micro = Duration(milliseconds: 150);
  // Transitions (sheet open, screen change)
  static const Duration transition = Duration(milliseconds: 300);
  // Numbers
  static const Duration number = Duration(milliseconds: 600);
  // Dramatic (sunday digest hero)
  static const Duration dramatic = Duration(milliseconds: 800);

  static const Curve neoPopCurve = Curves.easeOut;
  static const Curve numberCurve = Curves.elasticOut;
  static const Curve surfaceCurve = Curves.easeOutCubic;
  static const Curve sheetCurve = Cubic(0.4, 0, 0.2, 1);

  // Legacy aliases
  static const Duration neoPopPress = micro;
  static const Duration numberRoll = number;
  static const Curve numberRollCurve = numberCurve;
  static const Duration sheetEnter = transition;
  static const Duration sheetExit = Duration(milliseconds: 250);
  static const Duration barGrow = Duration(milliseconds: 400);
  static const Curve barGrowCurve = Curves.elasticOut;
  static const Duration tabTransition = Duration(milliseconds: 200);
  static const Curve tabCurve = Curves.easeInOut;
}

/// Shadow presets.
abstract final class PaisaShadows {
  static List<BoxShadow> card = const [
    BoxShadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 8),
  ];

  static List<BoxShadow> fab = const [
    BoxShadow(color: Color(0x66000000), offset: Offset(0, 4), blurRadius: 12),
  ];
}

// ---------------------------------------------------------------------------
// Spendler Design Tokens v1.0
// Light theme, system font, clean cards.
// ---------------------------------------------------------------------------

/// Spendler colour palette — light-first.
abstract final class SpendlerColors {
  // -- Backgrounds --
  static const Color scaffold = Color(0xFFF5F5F7);
  static const Color card = Color(0xFFFFFFFF);
  static const Color heroBackground = Color(0xFF1C1C1E);

  // -- Text --
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFAEAEB2);
  static const Color heroText = Color(0xFFFFFFFF);
  static const Color heroTextSecondary = Color(0xFF9999A3);

  // -- Semantic --
  static const Color overBudget = Color(0xFFFF3B30);
  static const Color onTrack = Color(0xFF34C759);
  static const Color accent = Color(0xFF007AFF);

  // -- Progress --
  static const Color progressTrack = Color(0xFFE5E5EA);
  static const Color separator = Color(0xFFE5E5EA);

  // -- Category colours (light-friendly, slightly more saturated) --
  static const Map<TransactionCategory, Color> categoryActive = {
    TransactionCategory.rent: Color(0xFF5E8BA0),
    TransactionCategory.transport: Color(0xFF4A8A56),
    TransactionCategory.food: Color(0xFFB8784A),
    TransactionCategory.family: Color(0xFFC9A84C),
    TransactionCategory.social: Color(0xFF8E6FBF),
    TransactionCategory.other: Color(0xFF8E8E93),
  };

  static Color categoryColor(TransactionCategory cat) =>
      categoryActive[cat] ?? const Color(0xFF8E8E93);
}

/// Spendler spacing (8-pt grid, matches Paisa scale).
abstract final class SpendlerSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double cardPadding = 16;
  static const double screenH = 16;
  static const double screenTop = 24;
  static const double cardGap = 12;
  static const double sectionGap = 32;
}

/// Spendler corner radii.
abstract final class SpendlerRadii {
  static const double card = 20;
  static const double progressBar = 3; // half of 6pt bar height → fully rounded
  static const double sheet = 24;
  static const double pill = 100;
  static const double button = 12;
  static const double ring = 40; // progress ring size
}

/// Spendler card shadow (subtle for light bg).
abstract final class SpendlerShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];
}

import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/enums.dart';

// ---------------------------------------------------------------------------
// Spendler Design Tokens v1.0
// Light-first, clean, modern finance tracker.
// ---------------------------------------------------------------------------

/// Colour palette.
abstract final class SpendlerColors {
  // -- Backgrounds (light theme) --
  static const Color scaffold = Color(0xFFF5F5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceHigh = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF0F1F3);

  // -- Borders --
  static const Color border = Color(0xFFE5E7EB);

  // -- Text --
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // -- Primary accent --
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFFEEF2FF);

  // -- Semantic --
  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFEF4444);
  static const Color splitPending = Color(0xFFF59E0B);

  // -- Accent palette --
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentOrange = Color(0xFFF97316);

  // Legacy aliases for migration compatibility
  static const Color yellow = primary;
  static const Color yellowShadow = Color(0xFF4F46E5);
  static const Color gold = Color(0xFFF59E0B);
  static const Color amber = Color(0xFFF59E0B);
  static const Color accentYellow = primary;
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color neoPopShadow = yellowShadow;
  static const Color success = income;
  static const Color warning = amber;
  static const Color error = expense;
  static const Color info = accentBlue;

  // -- Category colours: hue (accent) / tint (background) pairs --
  static const Map<TransactionCategory, Color> categoryHue = {
    TransactionCategory.housing: Color(0xFF6366F1),
    TransactionCategory.transport: Color(0xFF3B82F6),
    TransactionCategory.food: Color(0xFFF97316),
    TransactionCategory.shopping: Color(0xFFEC4899),
    TransactionCategory.entertainment: Color(0xFF8B5CF6),
    TransactionCategory.health: Color(0xFFEF4444),
    TransactionCategory.education: Color(0xFF14B8A6),
    TransactionCategory.utilities: Color(0xFFF59E0B),
    TransactionCategory.other: Color(0xFF6B7280),
  };

  static const Map<TransactionCategory, Color> categoryTint = {
    TransactionCategory.housing: Color(0xFFEEF2FF),
    TransactionCategory.transport: Color(0xFFEFF6FF),
    TransactionCategory.food: Color(0xFFFFF7ED),
    TransactionCategory.shopping: Color(0xFFFDF2F8),
    TransactionCategory.entertainment: Color(0xFFF5F3FF),
    TransactionCategory.health: Color(0xFFFEF2F2),
    TransactionCategory.education: Color(0xFFF0FDFA),
    TransactionCategory.utilities: Color(0xFFFFFBEB),
    TransactionCategory.other: Color(0xFFF9FAFB),
  };

  // Legacy aliases
  static const Map<TransactionCategory, Color> categoryActive = categoryHue;
  static const Color categoryMuted = Color(0xFFE5E7EB);

  static Color categoryColor(TransactionCategory cat) =>
      categoryHue[cat] ?? const Color(0xFF6B7280);
}

/// Typography styles (system font).
abstract final class SpendlerTextStyles {
  static const TextStyle heroSymbol = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w300,
    color: SpendlerColors.textSecondary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle heroAmount = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    color: SpendlerColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -2.0,
    height: 1,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: SpendlerColors.textTertiary,
    letterSpacing: 1.5,
  );

  static const TextStyle merchantName = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: SpendlerColors.textPrimary,
  );

  static const TextStyle pillLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle emptyState = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: SpendlerColors.textSecondary,
    height: 1.6,
  );

  static const TextStyle greeting = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: SpendlerColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle insightBody = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: SpendlerColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle onboardingHeadline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: SpendlerColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle onboardingBody = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: SpendlerColors.textSecondary,
    height: 1.6,
  );
}

/// Spacing scale (8-pt grid).
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
}

/// Corner radii.
abstract final class SpendlerRadii {
  static const double card = 16;
  static const double sheet = 24;
  static const double pill = 100;
  static const double button = 12;
  static const double barTop = 6;
  static const double fab = 28;
}

/// Typography sizes (kept for widgets using raw sizes).
abstract final class SpendlerTypo {
  static const double heroSize = 56;
  static const FontWeight heroWeight = FontWeight.w700;
  static const double symbolSize = 24;
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
abstract final class SpendlerMotion {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration transition = Duration(milliseconds: 300);
  static const Duration number = Duration(milliseconds: 600);
  static const Duration dramatic = Duration(milliseconds: 800);

  static const Curve neoPopCurve = Curves.easeOut;
  static const Curve numberCurve = Curves.elasticOut;
  static const Curve surfaceCurve = Curves.easeOutCubic;
  static const Curve sheetCurve = Cubic(0.4, 0, 0.2, 1);

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

/// Shadow presets (subtle for light theme).
abstract final class SpendlerShadows {
  static List<BoxShadow> card = const [
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 2), blurRadius: 8),
  ];

  static List<BoxShadow> fab = const [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 12),
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

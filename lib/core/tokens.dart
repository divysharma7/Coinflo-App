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
  static const Color border = Color(0xFFE5E5EA);

  // -- Text --
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color textTertiary = Color(0xFF6E6E73);

  // -- Primary accent --
  static const Color primary = Color(0xFF000000);

  // -- Semantic --
  static const Color income = Color(0xFF34C759);
  static const Color expense = Color(0xFFFF3B30);
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

  // -- Semantic aliases --
  static const Color destructive = expense;
  static const Color success = income;
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = expense;
  static const Color info = Color(0xFF007AFF);
  static const Color paused = textTertiary;

  // -- Additional surface aliases --
  static const Color card = surface;
  static const Color heroBackground = Color(0xFF000000);
  static const Color heroText = Color(0xFFFFFFFF);
  static const Color heroTextSecondary = Color(0xFF9999A3);
  static const Color overBudget = expense;
  static const Color onTrack = income;
  static const Color accent = primary;
  static const Color progressTrack = Color(0xFFE5E5EA);
  static const Color separator = border;
  static const Color cardBorder = border;

  // -- Category colours: hue (accent) / tint (background) pairs --
  static const Map<TransactionCategory, Color> categoryHue = {
    TransactionCategory.foodAndDrink: Color(0xFFFF8A4C),
    TransactionCategory.transport: Color(0xFF4A8FE7),
    TransactionCategory.shopping: Color(0xFFB19CD9),
    TransactionCategory.billsAndUtilities: Color(0xFFF59E0B),
    TransactionCategory.healthAndWellness: Color(0xFF22C55E),
    TransactionCategory.entertainment: Color(0xFFE91E63),
    TransactionCategory.streaming: Color(0xFFEC407A),
    TransactionCategory.gymFitness: Color(0xFF4CAF50),
    TransactionCategory.productivityTools: Color(0xFF9575CD),
    TransactionCategory.personalCare: Color(0xFFF8BBD0),
    TransactionCategory.education: Color(0xFF5C6BC0),
    TransactionCategory.travel: Color(0xFF14B8A6),
    TransactionCategory.other: Color(0xFF6E6E73),
  };

  static const Map<TransactionCategory, Color> categoryTint = {
    TransactionCategory.foodAndDrink: Color(0xFFFFF3E0),
    TransactionCategory.transport: Color(0xFFE3F2FD),
    TransactionCategory.shopping: Color(0xFFF3E5F5),
    TransactionCategory.billsAndUtilities: Color(0xFFFEF3C7),
    TransactionCategory.healthAndWellness: Color(0xFFDCFCE7),
    TransactionCategory.entertainment: Color(0xFFFCE4EC),
    TransactionCategory.streaming: Color(0xFFFCE4EC),
    TransactionCategory.gymFitness: Color(0xFFE8F5E9),
    TransactionCategory.productivityTools: Color(0xFFEDE7F6),
    TransactionCategory.personalCare: Color(0xFFFCE4EC),
    TransactionCategory.education: Color(0xFFE8EAF6),
    TransactionCategory.travel: Color(0xFFCCFBF1),
    TransactionCategory.other: Color(0xFFF5F5F7),
  };

  // Legacy aliases
  static const Map<TransactionCategory, Color> categoryActive = categoryHue;
  static const Color categoryMuted = Color(0xFFE5E7EB);

  static Color categoryColor(TransactionCategory cat) =>
      categoryHue[cat] ?? const Color(0xFF6E6E73);
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
  static const double screenH = 20;
  static const double screenTop = 24;
  static const double cardGap = 12;
  static const double sectionGap = 32;
}

/// Corner radii.
abstract final class SpendlerRadii {
  static const double card = 20;
  static const double sheet = 24;
  static const double pill = 100;
  static const double button = 12;
  static const double barTop = 6;
  static const double fab = 28;
  static const double progressBar = 3;
  static const double ring = 40;
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
  static const Duration number = Duration(milliseconds: 240);
  static const Duration dramatic = Duration(milliseconds: 800);

  static const Curve neoPopCurve = Curves.easeOut;
  static const Curve numberCurve = Curves.easeOut;
  static const Curve surfaceCurve = Curves.easeOutCubic;
  static const Curve sheetCurve = Cubic(0.4, 0, 0.2, 1);

  static const Duration neoPopPress = micro;
  static const Duration numberRoll = number;
  static const Curve numberRollCurve = numberCurve;
  static const Duration sheetEnter = transition;
  static const Duration sheetExit = Duration(milliseconds: 250);
  static const Duration barGrow = Duration(milliseconds: 400);
  static const Curve barGrowCurve = Curves.easeOut;
  static const Duration tabTransition = Duration.zero;
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


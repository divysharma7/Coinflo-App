import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/enums.dart';

class AppColors {
  AppColors._();

  // Base
  static const Color black = Color(0xFF0A0A0A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F5F5);

  // Grays
  static const Color gray100 = Color(0xFFF0F0F0);
  static const Color gray200 = Color(0xFFE0E0E0);
  static const Color gray300 = Color(0xFFC8C8C8);
  static const Color gray400 = Color(0xFFA0A0A0);
  static const Color gray500 = Color(0xFF6E6E6E);
  static const Color gray600 = Color(0xFF4A4A4A);

  // Semantic
  static const Color green = Color(0xFF22C55E);
  static const Color red = Color(0xFFEF4444);

  /// Neutral charcoal for amount entry — avoids the "error" feel of red.
  static const Color amountNeutral = Color(0xFF3A3A3A);
  static const Color orange = Color(0xFFF97316);

  // Semantic — additional
  static const Color aiPurple = Color(0xFF8B5CF6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color gold = Color(0xFFFBBF24);
  static const Color alertRed = Color(0xFFE53935);
  static const Color alertOrange = Color(0xFFEF6C00);
  static const Color nearBlack = Color(0xFF1E1E1E);

  // Semantic — opacity variants for badges
  static const Color orangeLight = Color(0x1AF97316);
  static const Color redLight = Color(0x1AEF4444);

  // Shadows
  static const Color shadow = Color(0x08000000);
  static const Color shadowMd = Color(0x0D000000);

  // Category pill pairs
  static const Color catPinkBg = Color(0xFFFCE7F3);
  static const Color catPinkText = Color(0xFFBE185D);
  static const Color catOrangeBg = Color(0xFFFEF3C7);
  static const Color catOrangeText = Color(0xFFB45309);
  static const Color catPurpleBg = Color(0xFFEDE9FE);
  static const Color catPurpleText = Color(0xFF6D28D9);
  static const Color catBlueBg = Color(0xFFDBEAFE);
  static const Color catBlueText = Color(0xFF1D40AE);
  static const Color catGreenBg = Color(0xFFDCFCE7);
  static const Color catGreenText = Color(0xFF15803D);
  static const Color catGrayBg = Color(0xFFF3F4F6);
  static const Color catGrayText = Color(0xFF374151);

  // Category accent colours (migrated from tokens.dart)
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
    TransactionCategory.income: Color(0xFF059669),
    TransactionCategory.cash: Color(0xFF78716C),
    TransactionCategory.investments: Color(0xFF2563EB),
    TransactionCategory.insurance: Color(0xFF7C3AED),
    TransactionCategory.other: Color(0xFF6E6E73),
  };

  static Color categoryColor(TransactionCategory cat) =>
      categoryHue[cat] ?? const Color(0xFF6E6E73);

  // ── Unified category bg / fg system ────────────────────────
  // Every TransactionCategory resolves via its `.group` so legacy
  // subcategories (streaming, gymFitness, productivityTools) inherit
  // from their parent automatically.

  static const Map<TransactionCategory, Color> _categoryBgMap = {
    TransactionCategory.foodAndDrink: catOrangeBg,
    TransactionCategory.transport: catBlueBg,
    TransactionCategory.shopping: catPurpleBg,
    TransactionCategory.billsAndUtilities: catOrangeBg,
    TransactionCategory.healthAndWellness: catGreenBg,
    TransactionCategory.entertainment: catPinkBg,
    TransactionCategory.personalCare: catPinkBg,
    TransactionCategory.education: catPurpleBg,
    TransactionCategory.travel: catBlueBg,
    TransactionCategory.income: catGreenBg,
    TransactionCategory.cash: catGrayBg,
    TransactionCategory.investments: catBlueBg,
    TransactionCategory.insurance: catPurpleBg,
    TransactionCategory.other: catGrayBg,
  };

  static const Map<TransactionCategory, Color> _categoryFgMap = {
    TransactionCategory.foodAndDrink: catOrangeText,
    TransactionCategory.transport: catBlueText,
    TransactionCategory.shopping: catPurpleText,
    TransactionCategory.billsAndUtilities: catOrangeText,
    TransactionCategory.healthAndWellness: catGreenText,
    TransactionCategory.entertainment: catPinkText,
    TransactionCategory.personalCare: catPinkText,
    TransactionCategory.education: catPurpleText,
    TransactionCategory.travel: catBlueText,
    TransactionCategory.income: catGreenText,
    TransactionCategory.cash: catGrayText,
    TransactionCategory.investments: catBlueText,
    TransactionCategory.insurance: catPurpleText,
    TransactionCategory.other: catGrayText,
  };

  /// Background / tint colour for a category pill or avatar.
  static Color categoryBg(TransactionCategory cat) =>
      _categoryBgMap[cat.group] ?? catGrayBg;

  /// Foreground / text colour for a category pill or avatar.
  static Color categoryFg(TransactionCategory cat) =>
      _categoryFgMap[cat.group] ?? catGrayText;
}

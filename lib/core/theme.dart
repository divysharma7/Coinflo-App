import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finance_buddy_app/core/tokens.dart';

class SpendlerTheme {
  SpendlerTheme._();

  // Legacy accessors kept for migration compatibility.
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color expenseRed = SpendlerColors.accentRed;
  static const Color incomeGreen = SpendlerColors.accentGreen;
  static const Color unconfirmedYellow = Color(0xFFFFFBEB);
  static const Color unconfirmedBorder = SpendlerColors.accentAmber;

  static const List<Color> categoryColors = [
    SpendlerColors.accentIndigo, // housing
    SpendlerColors.accentBlue, // transport
    SpendlerColors.accentOrange, // food
    SpendlerColors.accentPink, // shopping
    SpendlerColors.accentPurple, // entertainment
    SpendlerColors.accentRed, // health
    SpendlerColors.accentTeal, // education
    SpendlerColors.accentAmber, // utilities
    Color(0xFF6B7280), // other
  ];

  /// The single theme for Spendler — light, clean.
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = base.textTheme.apply(
      bodyColor: SpendlerColors.textPrimary,
      displayColor: SpendlerColors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: SpendlerColors.scaffold,
      colorScheme: const ColorScheme.light(
        surface: SpendlerColors.surface,
        primary: SpendlerColors.primary,
        onPrimary: Colors.white,
        secondary: SpendlerColors.accentAmber,
        onSecondary: Colors.white,
        error: SpendlerColors.error,
        onSurface: SpendlerColors.textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: SpendlerColors.scaffold,
        foregroundColor: SpendlerColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: SpendlerTypo.titleSize,
          fontWeight: SpendlerTypo.titleWeight,
          color: SpendlerColors.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: SpendlerColors.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(
          horizontal: SpendlerSpacing.screenH,
          vertical: SpendlerSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpendlerRadii.card),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SpendlerColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SpendlerRadii.sheet),
          ),
        ),
        dragHandleColor: SpendlerColors.textTertiary,
        dragHandleSize: Size(40, 4),
        showDragHandle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SpendlerColors.surface,
        height: 64,
        indicatorColor: SpendlerColors.primary.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: SpendlerColors.primary,
              size: 24,
            );
          }
          return const IconThemeData(
            color: SpendlerColors.textTertiary,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: SpendlerTypo.captionSize,
              fontWeight: SpendlerTypo.captionWeight,
              color: SpendlerColors.primary,
            );
          }
          return TextStyle(
            fontSize: SpendlerTypo.captionSize,
            fontWeight: SpendlerTypo.captionWeight,
            color: SpendlerColors.textTertiary,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SpendlerColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: SpendlerColors.border,
        thickness: 1,
        space: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SpendlerColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpendlerRadii.card),
        ),
      ),
    );
  }

  // Keep darkTheme around so nothing crashes — maps to lightTheme.
  static ThemeData get darkTheme => lightTheme;
}

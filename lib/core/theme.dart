import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finance_buddy_app/core/tokens.dart';

class SpendlerTheme {
  SpendlerTheme._();

  // Legacy accessors kept so existing code doesn't break during migration.
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color expenseRed = SpendlerColors.accentRed;
  static const Color incomeGreen = SpendlerColors.accentGreen;
  static const Color unconfirmedYellow = Color(0xFF3A2E00);
  static const Color unconfirmedBorder = SpendlerColors.accentAmber;

  static const List<Color> categoryColors = [
    SpendlerColors.accentYellow, // foodAndDrink
    SpendlerColors.accentBlue, // transport
    SpendlerColors.accentGreen, // shopping
    SpendlerColors.accentPurple, // entertainment
    Color(0xFFF97316), // streaming - orange
    Color(0xFF4DA8FF), // gymFitness - blue
    Color(0xFF9CA3AF), // productivityTools - grey
    Color(0xFFF59E0B), // personalCare - amber
    Color(0xFF34D399), // education - green
  ];

  /// The single theme for Spendler — dark, OLED-friendly.
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: SpendlerColors.textPrimary,
      displayColor: SpendlerColors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: SpendlerColors.scaffold,
      colorScheme: const ColorScheme.dark(
        surface: SpendlerColors.surface,
        primary: SpendlerColors.accentYellow,
        onPrimary: Colors.black,
        secondary: SpendlerColors.accentGold,
        onSecondary: Colors.black,
        error: SpendlerColors.error,
        onSurface: SpendlerColors.textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: SpendlerColors.scaffold,
        foregroundColor: SpendlerColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: SpendlerTypo.titleSize,
          fontWeight: SpendlerTypo.titleWeight,
          color: SpendlerColors.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
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
        backgroundColor: SpendlerColors.scaffold,
        height: 64,
        indicatorColor: SpendlerColors.accentYellow.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: SpendlerColors.accentYellow,
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
            return GoogleFonts.inter(
              fontSize: SpendlerTypo.captionSize,
              fontWeight: SpendlerTypo.captionWeight,
              color: SpendlerColors.accentYellow,
            );
          }
          return GoogleFonts.inter(
            fontSize: SpendlerTypo.captionSize,
            fontWeight: SpendlerTypo.captionWeight,
            color: SpendlerColors.textTertiary,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SpendlerColors.accentYellow,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1A1A1A),
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

  // Keep lightTheme around so nothing crashes — but it's no longer the default.
  static ThemeData get lightTheme => darkTheme;
}

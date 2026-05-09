import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finance_buddy_app/core/tokens.dart';

class PaisaTheme {
  PaisaTheme._();

  // Legacy accessors kept so existing code doesn't break during migration.
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color expenseRed = PaisaColors.accentRed;
  static const Color incomeGreen = PaisaColors.accentGreen;
  static const Color unconfirmedYellow = Color(0xFF3A2E00);
  static const Color unconfirmedBorder = PaisaColors.accentAmber;

  static const List<Color> categoryColors = [
    PaisaColors.accentYellow, // rent
    PaisaColors.accentBlue, // transport
    PaisaColors.accentGreen, // food
    PaisaColors.accentPurple, // family
    Color(0xFFF97316), // social - orange
    Color(0xFF9CA3AF), // other - grey
  ];

  /// The single theme for Pulse — dark, OLED-friendly.
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: PaisaColors.textPrimary,
      displayColor: PaisaColors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: PaisaColors.scaffold,
      colorScheme: const ColorScheme.dark(
        surface: PaisaColors.surface,
        primary: PaisaColors.accentYellow,
        onPrimary: Colors.black,
        secondary: PaisaColors.accentGold,
        onSecondary: Colors.black,
        error: PaisaColors.error,
        onSurface: PaisaColors.textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: PaisaColors.scaffold,
        foregroundColor: PaisaColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: PaisaTypo.titleSize,
          fontWeight: PaisaTypo.titleWeight,
          color: PaisaColors.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: PaisaColors.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(
          horizontal: PaisaSpacing.screenH,
          vertical: PaisaSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PaisaRadii.card),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: PaisaColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(PaisaRadii.sheet),
          ),
        ),
        dragHandleColor: PaisaColors.textTertiary,
        dragHandleSize: Size(40, 4),
        showDragHandle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: PaisaColors.scaffold,
        height: 64,
        indicatorColor: PaisaColors.accentYellow.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: PaisaColors.accentYellow,
              size: 24,
            );
          }
          return const IconThemeData(
            color: PaisaColors.textTertiary,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: PaisaTypo.captionSize,
              fontWeight: PaisaTypo.captionWeight,
              color: PaisaColors.accentYellow,
            );
          }
          return GoogleFonts.inter(
            fontSize: PaisaTypo.captionSize,
            fontWeight: PaisaTypo.captionWeight,
            color: PaisaColors.textTertiary,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: PaisaColors.accentYellow,
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
        backgroundColor: PaisaColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PaisaRadii.card),
        ),
      ),
    );
  }

  // Keep lightTheme around so nothing crashes — but it's no longer the default.
  static ThemeData get lightTheme => darkTheme;
}

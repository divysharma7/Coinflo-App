import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/app_colors.dart';

/// Wraps a Material time/date picker so it matches CoinFlo's monochrome
/// black-on-white design system instead of the default teal/purple accents.
///
/// Usage:
/// ```dart
/// showTimePicker(context: context, initialTime: t, builder: monoPickerBuilder);
/// ```
Widget monoPickerBuilder(BuildContext context, Widget? child) {
  final base = Theme.of(context);

  return Theme(
    data: base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.black,
        onPrimary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.black,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.white,
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.black
              : AppColors.gray100,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.black,
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.black
              : AppColors.white,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.black,
        ),
        dayPeriodBorderSide: const BorderSide(color: AppColors.gray300),
        dialHandColor: AppColors.black,
        dialBackgroundColor: AppColors.gray100,
        dialTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.black,
        ),
        entryModeIconColor: AppColors.black,
        hourMinuteTextStyle: base.textTheme.displayMedium,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.black),
      ),
    ),
    child: child!,
  );
}

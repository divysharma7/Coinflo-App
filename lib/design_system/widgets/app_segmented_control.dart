import 'package:flutter/material.dart';

import 'package:finance_buddy_app/design_system/app_colors.dart';
import 'package:finance_buddy_app/design_system/app_radius.dart';
import 'package:finance_buddy_app/design_system/app_shadows.dart';
import 'package:finance_buddy_app/design_system/app_text_styles.dart';

/// Pill segmented control — white track, ink active segment.
/// Mirrors `.seg` in the CoinFlo Hi-Fi system (Week/Month/Year, Expense/Income).
class AppSegmentedControl extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.full,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? AppColors.black
                        : Colors.transparent,
                    borderRadius: AppRadius.full,
                  ),
                  child: Text(
                    segments[i],
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyM.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: i == selectedIndex
                          ? AppColors.white
                          : AppColors.gray500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/app_colors.dart';
import 'package:finance_buddy_app/design_system/app_text_styles.dart';

class AppBottomTabBar extends StatelessWidget {
  const AppBottomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray200, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _tab(0, PhosphorIcons.house(), PhosphorIcons.house(PhosphorIconsStyle.fill), 'Home'),
              _tab(1, PhosphorIcons.chartBar(), PhosphorIcons.chartBar(PhosphorIconsStyle.fill), 'Report'),
              const SizedBox(width: 56), // space for FAB
              _tab(2, PhosphorIcons.calendarBlank(), PhosphorIcons.calendarBlank(PhosphorIconsStyle.fill), 'Plan'),
              _tab(3, PhosphorIcons.gear(), PhosphorIcons.gear(PhosphorIconsStyle.fill), 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = currentIndex == index;
    final color = isActive ? AppColors.black : AppColors.gray500;

    return Expanded(
      child: Semantics(
        selected: isActive,
        label: label,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(index),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelS.copyWith(color: color),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:finance_buddy_app/design_system/app_colors.dart';
import 'package:finance_buddy_app/design_system/app_radius.dart';
import 'package:finance_buddy_app/design_system/app_shadows.dart';
import 'package:finance_buddy_app/design_system/app_text_styles.dart';

/// Small stat tile (icon + label + mono value) used in the Home quick-stats
/// row and the Transactions summary row. Supports a `dark` (ink) variant.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.dark = false,
    this.valueColor,
  });

  final Widget icon;
  final String label;
  final String value;
  final bool dark;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? AppColors.white : AppColors.black;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: dark ? AppColors.black : AppColors.white,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: dark ? AppColors.white.withValues(alpha: 0.12)
                  : AppColors.gray100,
              borderRadius: AppRadius.s,
            ),
            child: Center(child: SizedBox(width: 16, height: 16, child: icon)),
          ),
          const SizedBox(height: 11),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.1,
              color: dark ? AppColors.white.withValues(alpha: 0.6)
                  : AppColors.gray500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.numericL.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: valueColor ?? fg,
            ),
          ),
        ],
      ),
    );
  }
}

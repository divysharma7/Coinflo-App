import 'package:flutter/material.dart';

import 'package:finance_buddy_app/design_system/app_colors.dart';
import 'package:finance_buddy_app/design_system/app_radius.dart';
import 'package:finance_buddy_app/design_system/app_shadows.dart';
import 'package:finance_buddy_app/design_system/app_spacing.dart';

enum AppCardVariant { light, dark }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.light,
    this.padding,
    this.shadow,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final isDark = variant == AppCardVariant.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.black : AppColors.white,
        borderRadius: AppRadius.xl,
        boxShadow: shadow ?? AppShadows.sm,
      ),
      child: child,
    );
  }
}

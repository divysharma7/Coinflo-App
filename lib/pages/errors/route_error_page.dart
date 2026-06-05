import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_buddy_app/design_system/app_colors.dart';
import 'package:finance_buddy_app/design_system/app_spacing.dart';
import 'package:finance_buddy_app/design_system/app_text_styles.dart';
import 'package:finance_buddy_app/design_system/app_radius.dart';

class RouteErrorPage extends StatelessWidget {
  final String message;

  const RouteErrorPage({
    super.key,
    this.message = 'Page not found',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: AppRadius.lg,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 36,
                    color: AppColors.gray400,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  message,
                  style: AppTextStyles.headingM.copyWith(
                    color: AppColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'The page you\'re looking for doesn\'t exist\nor could not be loaded.',
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.gray400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.go('/home'),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.base,
                      ),
                    ),
                    child: Text(
                      'Go to Home',
                      style: AppTextStyles.headingS.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

class ErrorCard extends StatelessWidget {
  const ErrorCard({
    super.key,
    this.message = 'Something went wrong',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIcons.warningCircle(),
              size: 32,
              color: AppColors.gray500,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  'Tap to retry',
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.black),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';

class ImportPromptBanner extends StatelessWidget {
  const ImportPromptBanner({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: AppRadius.xl,
          border: Border.all(color: AppColors.gray200, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'See your real money story',
                    style: AppTextStyles.headingS,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Import 6 months of bank data',
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              PhosphorIcons.caretRight(),
              size: 20,
              color: AppColors.gray500,
            ),
          ],
        ),
      ),
    );
  }
}

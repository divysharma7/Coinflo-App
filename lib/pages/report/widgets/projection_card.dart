import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';

import 'package:finance_buddy_app/pages/report/widgets/report_helpers.dart';

// ---------------------------------------------------------------------------
// Month-End Projection Card
// ---------------------------------------------------------------------------

class ProjectionCard extends ConsumerWidget {
  const ProjectionCard({super.key, required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projAsync = ref.watch(monthEndProjectionProvider);
    return projAsync.when(
      data: (proj) {
        if (proj == null) return const SizedBox.shrink();
        final vsLast = proj.percentVsLast;

        // Sparse data — too early for a meaningful forecast
        if (proj.isSparse) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: reportCardDecor(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIcons.trendUp(), size: 18, color: AppColors.gray500),
                      const SizedBox(width: 8),
                      Text('Month-End Forecast',
                          style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tracking ${DateTime.now().day} days of spend \u2014 too early to forecast.',
                    style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
                  ),
                ],
              ),
            ),
          );
        }

        final forecastCopy = proj.usedShape
            ? 'You\'re on track for ~$symbol${reportFmt(proj.projected)} by month end based on your spending shape.'
            : 'At your current pace, you\'ll spend $symbol${reportFmt(proj.projected)} by month end.';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: reportCardDecor(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIcons.trendUp(), size: 18, color: AppColors.gray500),
                    const SizedBox(width: 8),
                    Text('Month-End Forecast',
                        style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  forecastCopy,
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
                ),
                if (vsLast != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    vsLast >= 0
                        ? 'That\'s $vsLast% more than last month.'
                        : 'That\'s ${vsLast.abs()}% less than last month.',
                    style: AppTextStyles.bodyS.copyWith(
                      color: vsLast >= 0
                          ? AppColors.red
                          : AppColors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text('${proj.daysLeft} days remaining',
                    style: AppTextStyles.labelS.copyWith(color: AppColors.gray500)),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const ErrorCard(),
    );
  }
}

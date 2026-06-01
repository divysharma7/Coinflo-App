import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/animated_progress_bar.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';

import 'package:finance_buddy_app/pages/report/widgets/report_helpers.dart';

// ---------------------------------------------------------------------------
// Savings Goals
// ---------------------------------------------------------------------------

class SavingsGoalsSection extends ConsumerWidget {
  const SavingsGoalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final sym = reportSym(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: reportCardDecor(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Savings Progress',
                    style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
                const SizedBox(height: 4),
                Text('Your goals at a glance',
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500)),
                const SizedBox(height: AppSpacing.lg),
                ...goals.map((g) {
                  final pct = g.targetAmount > 0
                      ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0)
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(g.name,
                                style: AppTextStyles.bodyM
                                    .copyWith(fontWeight: FontWeight.w500)),
                            Text(
                              '$sym${reportFmt(g.currentAmount)} / $sym${reportFmt(g.targetAmount)}',
                              style: AppTextStyles.bodyS
                                  .copyWith(color: AppColors.gray500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AnimatedProgressBar(
                          value: pct,
                          backgroundColor: AppColors.gray200,
                          valueColor: AppColors.green,
                        ),
                      ],
                    ),
                  );
                }),
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

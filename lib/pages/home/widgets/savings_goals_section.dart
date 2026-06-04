import 'package:finance_buddy_app/widgets/common/error_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/animated_progress_bar.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

import 'home_format_helpers.dart';

class SavingsGoalsSection extends ConsumerWidget {
  const SavingsGoalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final symbol = currencySymbol(currencyAsync.valueOrNull ?? 'inr');

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Savings Goals',
                  style:
                      AppTextStyles.headingS.copyWith(color: AppColors.black)),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: goals.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final g = goals[i];
                    final pct = g.targetAmount > 0
                        ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0)
                        : 0.0;
                    return GestureDetector(
                      onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
                      onLongPress: () => _showGoalActions(context, ref, g),
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: AppRadius.mdLg,
                          boxShadow: AppShadows.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(g.name,
                                style: AppTextStyles.bodyM.copyWith(
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(
                              '$symbol${formatHomeNumber(g.currentAmount)} / $symbol${formatHomeNumber(g.targetAmount)}',
                              style: AppTextStyles.labelS
                                  .copyWith(color: AppColors.gray500),
                            ),
                            AnimatedProgressBar(
                              value: pct,
                              backgroundColor: AppColors.gray200,
                              valueColor: AppColors.green,
                            ),
                            Text('${(pct * 100).round()}%',
                                style: AppTextStyles.labelS.copyWith(
                                    color: AppColors.green,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (goals.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(goals.length, (i) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0
                              ? AppColors.gray500
                              : AppColors.gray300,
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const ErrorCard(),
    );
  }

  void _showGoalActions(BuildContext context, WidgetRef ref, SavingsGoal g) {
    HapticFeedback.mediumImpact();
    showSpendlerSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(g.name,
                  style: AppTextStyles.headingS
                      .copyWith(color: AppColors.black)),
            ),
            ListTile(
              leading: PhosphorIcon(PhosphorIcons.pencilSimple(),
                  color: AppColors.black),
              title: const Text('Edit Goal'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/plan');
              },
            ),
            ListTile(
              leading: PhosphorIcon(PhosphorIcons.trash(),
                  color: AppColors.red),
              title: Text('Delete Goal',
                  style: TextStyle(color: AppColors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteGoal(context, ref, g);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGoal(BuildContext context, WidgetRef ref, SavingsGoal g) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "${g.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(repositoryProvider);
              await deleteGoal(repo, g.id);
              invalidateAnalytics(ref);
            },
            child: Text('Delete',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

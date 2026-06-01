import 'package:finance_buddy_app/widgets/common/error_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:finance_buddy_app/pages/plan/widgets/budget_card.dart';
import 'package:finance_buddy_app/pages/plan/widgets/goal_card.dart';
import 'package:finance_buddy_app/pages/plan/widgets/add_budget_sheet.dart';
import 'package:finance_buddy_app/pages/plan/widgets/add_goal_sheet.dart';
import 'package:finance_buddy_app/pages/plan/widgets/add_money_sheet.dart';
import 'package:finance_buddy_app/pages/plan/widgets/plan_shared_widgets.dart';

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          const _HeroHeader(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.xl),
                const _BudgetsSection()
                    .animate().fadeIn(duration: AppDurations.slow).slideY(begin: 0.05, duration: AppDurations.slow),
                const SizedBox(height: AppSpacing.xxl),
                const _GoalsSection()
                    .animate().fadeIn(delay: 120.ms, duration: AppDurations.slow).slideY(begin: 0.05, delay: 120.ms, duration: AppDurations.slow),
                const SizedBox(height: AppSpacing.xxxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Header ──────────────────────────────────────

class _HeroHeader extends ConsumerWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sym = currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan',
                  style: AppTextStyles.headingL.copyWith(
                    color: AppColors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                ref.watch(budgetStatusProvider).when(
                  data: (status) {
                    if (status.totalLimit == 0) {
                      return Text(
                        'Set budgets to track your spending',
                        style: AppTextStyles.bodyM.copyWith(
                          color: AppColors.gray500,
                        ),
                      );
                    }
                    return Text(
                      status.remaining >= 0
                          ? '$sym${status.remaining.toStringAsFixed(0)} left this month'
                          : '$sym${status.remaining.abs().toStringAsFixed(0)} over budget',
                      style: AppTextStyles.bodyM.copyWith(
                        color: status.isOverBudget
                            ? AppColors.red
                            : AppColors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                  loading: () => Container(
                    height: 16,
                    width: 160,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.08),
                      borderRadius: AppRadius.s,
                    ),
                  ),
                  error: (_, _) => const ErrorCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Budgets Section ──────────────────────────────────

class _BudgetsSection extends ConsumerWidget {
  const _BudgetsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider);
    final spending = ref.watch(monthlyCategorySpendingProvider);
    final sym = currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BUDGETS',
              style: AppTextStyles.labelS.copyWith(
                color: AppColors.gray500,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () => _showAddBudgetSheet(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.1),
                  borderRadius: AppRadius.full,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.plus(),
                      size: 14,
                      color: AppColors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
                      style: AppTextStyles.labelM.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        budgets.when(
          data: (budgetList) {
            if (budgetList.isEmpty) {
              return PlanEmptyCard(
                icon: PhosphorIcons.chartPieSlice(),
                message: 'No budgets yet.\nTap + to set a monthly limit.',
              );
            }
            return spending.when(
              data: (spendingMap) {
                return Column(
                  children: [
                    for (int i = 0; i < budgetList.length; i++) ...[
                      StaggeredItem(
                        index: i,
                        child: BudgetCard(
                          budget: budgetList[i],
                          spent: spendingMap[budgetList[i].category] ?? 0,
                          onDelete: () => _deleteBudget(ref, budgetList[i].id),
                          onEdit: () => _showAddBudgetSheet(context, ref, existingBudget: budgetList[i]),
                          symbol: sym,
                        ),
                      ),
                      if (i < budgetList.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              },
              loading: () => const PlanLoadingCard(),
              error: (_, _) => const ErrorCard(),
            );
          },
          loading: () => const PlanLoadingCard(),
          error: (_, _) => const ErrorCard(),
        ),
      ],
    );
  }

  void _showAddBudgetSheet(BuildContext context, WidgetRef ref, {CategoryBudget? existingBudget}) {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) => AddBudgetSheet(existingBudget: existingBudget),
    );
  }

  Future<void> _deleteBudget(WidgetRef ref, int id) async {
    await deleteBudget(ref.read(repositoryProvider), id);
    invalidateAnalytics(ref);
  }
}

// ─── Goals Section ────────────────────────────────────

class _GoalsSection extends ConsumerWidget {
  const _GoalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final sym = currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GOALS',
              style: AppTextStyles.labelS.copyWith(
                color: AppColors.gray500,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () => _showAddGoalSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.1),
                  borderRadius: AppRadius.full,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.plus(),
                      size: 14,
                      color: AppColors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
                      style: AppTextStyles.labelM.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        goals.when(
          data: (goalList) {
            if (goalList.isEmpty) {
              return PlanEmptyCard(
                icon: PhosphorIcons.target(),
                message: 'No savings goals yet.\nTap + to create one.',
              );
            }
            return Column(
              children: [
                for (int i = 0; i < goalList.length; i++) ...[
                  StaggeredItem(
                    index: i,
                    child: GoalCard(
                      goal: goalList[i],
                      onAddMoney: () => _showAddMoneySheet(context, ref, goalList[i]),
                      onDelete: () => _deleteGoal(ref, goalList[i].id),
                      onEdit: () => _showAddGoalSheet(context, existingGoal: goalList[i]),
                      symbol: sym,
                    ),
                  ),
                  if (i < goalList.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
          loading: () => const PlanLoadingCard(),
          error: (_, _) => const ErrorCard(),
        ),
      ],
    );
  }

  void _showAddGoalSheet(BuildContext context, {SavingsGoal? existingGoal}) {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) => AddGoalSheet(existingGoal: existingGoal),
    );
  }

  void _showAddMoneySheet(
      BuildContext context, WidgetRef ref, SavingsGoal goal) {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) => AddMoneySheet(goal: goal),
    );
  }

  Future<void> _deleteGoal(WidgetRef ref, int id) async {
    await deleteGoal(ref.read(repositoryProvider), id);
    invalidateAnalytics(ref);
  }
}


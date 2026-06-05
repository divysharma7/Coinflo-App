import 'package:finance_buddy_app/widgets/common/error_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/animations.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';
import 'package:finance_buddy_app/pages/plan/widgets/budget_card.dart';
import 'package:finance_buddy_app/pages/plan/widgets/goal_card.dart';
import 'package:finance_buddy_app/pages/plan/widgets/add_budget_sheet.dart';
import 'package:finance_buddy_app/pages/plan/widgets/add_goal_sheet.dart';
import 'package:finance_buddy_app/pages/plan/widgets/add_money_sheet.dart';
import 'package:finance_buddy_app/pages/plan/widgets/plan_shared_widgets.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Indian-style digit grouping for amounts (₹42,380 / ₹1,20,000).
String _grouped(num value) {
  final s = value.abs().toStringAsFixed(0);
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          const _PlanHeader(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.lg),
                // NOTE: these sections are intentionally NOT wrapped in
                // `flutter_animate` (`.animate().fadeIn().slideY()`). A slide
                // transform at a sliver-child boundary desyncs the sliver's
                // paint offset from its layout offset. Because the Plan tab is
                // laid out offstage inside the shell `IndexedStack` at startup,
                // that desync makes the viewport read a null sliver geometry
                // (`RenderViewportBase._paintContents` / `layoutChildSequence`)
                // and crashes the frame. Entrance motion lives *inside* the
                // sections via `StaggeredItem`, which animates already-laid-out
                // box content and is sliver-safe.
                const _MonthlyBudgetCard(),
                const SizedBox(height: AppSpacing.xxl),
                const _BudgetsSection(),
                const SizedBox(height: AppSpacing.xxl),
                const _GoalsSection(),
                const SizedBox(height: AppSpacing.xxxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────

class _PlanHeader extends StatelessWidget {
  const _PlanHeader();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = '${_monthNames[now.month - 1]} ${now.year}';
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Plan',
                style: AppTextStyles.displayL.copyWith(color: AppColors.black),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.full,
                  boxShadow: AppShadows.sm,
                ),
                child: Text(
                  monthLabel,
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Monthly Budget Card ──────────────────────────────

class _MonthlyBudgetCard extends ConsumerWidget {
  const _MonthlyBudgetCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sym = currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');
    final daysLeft = ref.watch(monthEndProjectionProvider).valueOrNull?.daysLeft;

    return ref.watch(budgetStatusProvider).when(
      data: (status) {
        if (status.totalLimit == 0) {
          return PlanEmptyCard(
            icon: PhosphorIcons.chartPieSlice(),
            message: 'Set a monthly budget to track\nyour spending this month.',
          );
        }
        final progress =
            (status.totalSpent / status.totalLimit).clamp(0.0, 1.0);
        final percentUsed = (progress * 100).round();
        final isOver = status.isOverBudget;
        final ringColor = isOver ? AppColors.red : AppColors.black;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.xl,
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            children: [
              ProgressRing(
                progress: progress,
                size: 104,
                strokeWidth: 9,
                color: ringColor,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentUsed%',
                      style: AppTextStyles.numericL.copyWith(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      'USED',
                      style: AppTextStyles.labelS.copyWith(
                        fontSize: 10,
                        color: AppColors.gray400,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monthly budget', style: AppTextStyles.section),
                    const SizedBox(height: 6),
                    Text(
                      '$sym${_grouped(status.totalSpent)}',
                      style: AppTextStyles.numericL.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'of $sym${_grouped(status.totalLimit)}',
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOver
                                ? AppColors.redLight
                                : AppColors.catGreenBg,
                            borderRadius: AppRadius.full,
                          ),
                          child: Text(
                            isOver
                                ? '$sym${_grouped(status.remaining.abs())} over'
                                : '$sym${_grouped(status.remaining)} left',
                            style: AppTextStyles.labelS.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isOver
                                  ? AppColors.red
                                  : AppColors.catGreenText,
                            ),
                          ),
                        ),
                        if (daysLeft != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '· $daysLeft days',
                            style: AppTextStyles.bodyS.copyWith(
                              fontSize: 12,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const PlanLoadingCard(),
      error: (_, _) => const ErrorCard(),
    );
  }
}

// ─── Section header ───────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action, required this.onTap});

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyM.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.black,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action,
                style: AppTextStyles.bodyS.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                PhosphorIcons.caretRight(),
                size: 14,
                color: AppColors.gray500,
              ),
            ],
          ),
        ),
      ],
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
        _SectionHeader(
          title: 'Category budgets',
          action: 'Edit',
          onTap: () => _showAddBudgetSheet(context, ref),
        ),
        const SizedBox(height: AppSpacing.sm),
        budgets.when(
          data: (budgetList) {
            if (budgetList.isEmpty) {
              return PlanEmptyCard(
                icon: PhosphorIcons.chartPieSlice(),
                message: 'No budgets yet.\nTap Edit to set a monthly limit.',
              );
            }
            return spending.when(
              data: (spendingMap) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.xl,
                    boxShadow: AppShadows.sm,
                  ),
                  child: Column(
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
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.gray100,
                          ),
                      ],
                    ],
                  ),
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
        _SectionHeader(
          title: 'Savings goals',
          action: 'All',
          onTap: () => _showAddGoalSheet(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        goals.when(
          data: (goalList) {
            if (goalList.isEmpty) {
              return PlanEmptyCard(
                icon: PhosphorIcons.target(),
                message: 'No savings goals yet.\nTap All to create one.',
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisExtent: 196,
              ),
              itemCount: goalList.length,
              itemBuilder: (context, i) => StaggeredItem(
                index: i,
                child: GoalCard(
                  goal: goalList[i],
                  onAddMoney: () => _showAddMoneySheet(context, ref, goalList[i]),
                  onDelete: () => _deleteGoal(ref, goalList[i].id),
                  onEdit: () => _showAddGoalSheet(context, existingGoal: goalList[i]),
                  symbol: sym,
                ),
              ),
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

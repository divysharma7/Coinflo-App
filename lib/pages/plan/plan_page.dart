import 'dart:math';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/animations.dart';

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: SpendlerColors.scaffold,
      body: CustomScrollView(
        slivers: [
          const _HeroHeader(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: SpendlerSpacing.lg),
                const _BudgetsSection(),
                const SizedBox(height: SpendlerSpacing.sectionGap),
                const _GoalsSection(),
                const SizedBox(height: SpendlerSpacing.xxl),
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
    final budgets = ref.watch(budgetsProvider);
    final spending = ref.watch(monthlyCategorySpendingProvider);

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          color: SpendlerColors.heroBackground,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(SpendlerRadii.card),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SpendlerSpacing.screenH,
              SpendlerSpacing.md,
              SpendlerSpacing.screenH,
              SpendlerSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plan',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: SpendlerColors.heroText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: SpendlerSpacing.xs),
                budgets.when(
                  data: (budgetList) {
                    return spending.when(
                      data: (spendingMap) {
                        double totalLimit = 0;
                        double totalSpent = 0;
                        for (final b in budgetList) {
                          totalLimit += b.monthlyLimit;
                          totalSpent += spendingMap[b.category] ?? 0;
                        }
                        if (budgetList.isEmpty) {
                          return const Text(
                            'Set budgets to track your spending',
                            style: TextStyle(
                              fontSize: 15,
                              color: SpendlerColors.heroTextSecondary,
                            ),
                          );
                        }
                        final remaining = totalLimit - totalSpent;
                        return Text(
                          remaining >= 0
                              ? '\$${remaining.toStringAsFixed(0)} left this month'
                              : '\$${remaining.abs().toStringAsFixed(0)} over budget',
                          style: TextStyle(
                            fontSize: 15,
                            color: remaining >= 0
                                ? SpendlerColors.onTrack
                                : SpendlerColors.overBudget,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                      loading: () => const Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 15,
                          color: SpendlerColors.heroTextSecondary,
                        ),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'BUDGETS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SpendlerColors.textTertiary,
                letterSpacing: 1.5,
              ),
            ),
            GestureDetector(
              onTap: () => _showAddBudgetSheet(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpendlerSpacing.sm,
                  vertical: SpendlerSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: SpendlerColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(SpendlerRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.plus(),
                      size: 14,
                      color: SpendlerColors.accent,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SpendlerColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpendlerSpacing.cardGap),
        budgets.when(
          data: (budgetList) {
            if (budgetList.isEmpty) {
              return _EmptyCard(
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
                        child: _BudgetCard(
                          budget: budgetList[i],
                          spent: spendingMap[budgetList[i].category] ?? 0,
                          onDelete: () => _deleteBudget(ref, budgetList[i].id),
                        ),
                      ),
                      if (i < budgetList.length - 1)
                        const SizedBox(height: SpendlerSpacing.cardGap),
                    ],
                  ],
                );
              },
              loading: () => const _LoadingCard(),
              error: (_, _) => const SizedBox.shrink(),
            );
          },
          loading: () => const _LoadingCard(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _showAddBudgetSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SpendlerRadii.sheet),
        ),
      ),
      showDragHandle: true,
      builder: (_) => _AddBudgetSheet(),
    );
  }

  Future<void> _deleteBudget(WidgetRef ref, int id) async {
    final repo = ref.read(repositoryProvider);
    await repo.deleteBudget(id);
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.spent,
    required this.onDelete,
  });

  final CategoryBudget budget;
  final double spent;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final category = TransactionCategory.values.firstWhere(
      (c) => c.name == budget.category,
      orElse: () => TransactionCategory.other,
    );
    final progress = budget.monthlyLimit > 0
        ? (spent / budget.monthlyLimit).clamp(0.0, 1.5)
        : 0.0;
    final isOver = spent > budget.monthlyLimit;
    final categoryColor = SpendlerColors.categoryColor(category);
    final barColor = isOver ? SpendlerColors.overBudget : categoryColor;

    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context),
      child: Container(
        padding: const EdgeInsets.all(SpendlerSpacing.cardPadding),
        decoration: BoxDecoration(
          color: SpendlerColors.card,
          borderRadius: BorderRadius.circular(SpendlerRadii.card),
          boxShadow: SpendlerShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: PhosphorIcon(
                      category.iconFill,
                      size: 18,
                      color: categoryColor,
                    ),
                  ),
                ),
                const SizedBox(width: SpendlerSpacing.cardGap),
                Expanded(
                  child: Text(
                    category.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: SpendlerColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '\$${spent.toStringAsFixed(0)} / \$${budget.monthlyLimit.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isOver
                        ? SpendlerColors.overBudget
                        : SpendlerColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpendlerSpacing.cardGap),
            // Progress bar — 6pt tall, fully rounded
            ClipRRect(
              borderRadius: BorderRadius.circular(SpendlerRadii.progressBar),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    // Track
                    Container(
                      decoration: BoxDecoration(
                        color: SpendlerColors.progressTrack,
                        borderRadius:
                            BorderRadius.circular(SpendlerRadii.progressBar),
                      ),
                    ),
                    // Fill
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius:
                              BorderRadius.circular(SpendlerRadii.progressBar),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isOver) ...[
              const SizedBox(height: SpendlerSpacing.sm),
              Text(
                '\$${(spent - budget.monthlyLimit).toStringAsFixed(0)} over limit',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: SpendlerColors.overBudget,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Remove this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: SpendlerColors.overBudget)),
          ),
        ],
      ),
    );
  }
}

// ─── Goals Section ────────────────────────────────────

class _GoalsSection extends ConsumerWidget {
  const _GoalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'GOALS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SpendlerColors.textTertiary,
                letterSpacing: 1.5,
              ),
            ),
            GestureDetector(
              onTap: () => _showAddGoalSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpendlerSpacing.sm,
                  vertical: SpendlerSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: SpendlerColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(SpendlerRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.plus(),
                      size: 14,
                      color: SpendlerColors.accent,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SpendlerColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpendlerSpacing.cardGap),
        goals.when(
          data: (goalList) {
            if (goalList.isEmpty) {
              return _EmptyCard(
                icon: PhosphorIcons.target(),
                message: 'No savings goals yet.\nTap + to create one.',
              );
            }
            return Column(
              children: [
                for (int i = 0; i < goalList.length; i++) ...[
                  StaggeredItem(
                    index: i,
                    child: _GoalCard(
                      goal: goalList[i],
                      onAddMoney: () => _showAddMoneySheet(context, ref, goalList[i]),
                      onDelete: () => _deleteGoal(ref, goalList[i].id),
                    ),
                  ),
                  if (i < goalList.length - 1)
                    const SizedBox(height: SpendlerSpacing.cardGap),
                ],
              ],
            );
          },
          loading: () => const _LoadingCard(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _showAddGoalSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SpendlerRadii.sheet),
        ),
      ),
      showDragHandle: true,
      builder: (_) => const _AddGoalSheet(),
    );
  }

  void _showAddMoneySheet(
      BuildContext context, WidgetRef ref, SavingsGoal goal) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SpendlerRadii.sheet),
        ),
      ),
      showDragHandle: true,
      builder: (_) => _AddMoneySheet(goal: goal),
    );
  }

  Future<void> _deleteGoal(WidgetRef ref, int id) async {
    final repo = ref.read(repositoryProvider);
    await repo.deleteGoal(id);
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onAddMoney,
    required this.onDelete,
  });

  final SavingsGoal goal;
  final VoidCallback onAddMoney;
  final VoidCallback onDelete;

  IconData _resolveIcon(String iconName) {
    switch (iconName) {
      case 'airplane':
        return PhosphorIconsFill.airplane;
      case 'car':
        return PhosphorIconsFill.car;
      case 'house':
        return PhosphorIconsFill.house;
      case 'graduationCap':
        return PhosphorIconsFill.graduationCap;
      case 'heartbeat':
        return PhosphorIconsFill.heartbeat;
      case 'laptop':
        return PhosphorIconsFill.laptop;
      case 'gift':
        return PhosphorIconsFill.gift;
      case 'piggyBank':
        return PhosphorIconsFill.piggyBank;
      default:
        return PhosphorIconsFill.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final remaining = goal.targetAmount - goal.currentAmount;

    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context),
      child: Container(
        padding: const EdgeInsets.all(SpendlerSpacing.cardPadding),
        decoration: BoxDecoration(
          color: SpendlerColors.card,
          borderRadius: BorderRadius.circular(SpendlerRadii.card),
          boxShadow: SpendlerShadows.card,
        ),
        child: Row(
          children: [
            // Progress ring
            SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(
                painter: _GoalRingPainter(
                  progress: progress,
                  strokeWidth: 5,
                  foregroundColor: SpendlerColors.accent,
                  backgroundColor: SpendlerColors.progressTrack,
                ),
                child: Center(
                  child: PhosphorIcon(
                    _resolveIcon(goal.iconName),
                    size: 22,
                    color: SpendlerColors.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: SpendlerSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: SpendlerColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${goal.currentAmount.toStringAsFixed(0)} of \$${goal.targetAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: SpendlerColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remaining > 0
                        ? '\$${remaining.toStringAsFixed(0)} to go'
                        : 'Goal reached!',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: remaining > 0
                          ? SpendlerColors.textTertiary
                          : SpendlerColors.onTrack,
                    ),
                  ),
                ],
              ),
            ),
            // Add money button
            GestureDetector(
              onTap: onAddMoney,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SpendlerColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(SpendlerRadii.button),
                ),
                child: Center(
                  child: Icon(
                    PhosphorIcons.plus(),
                    size: 20,
                    color: SpendlerColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Remove this savings goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: SpendlerColors.overBudget)),
          ),
        ],
      ),
    );
  }
}

// ─── Goal Ring Painter ────────────────────────────────

class _GoalRingPainter extends CustomPainter {
  _GoalRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final double progress;
  final double strokeWidth;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = foregroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -pi / 2, progress * 2 * pi, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoalRingPainter old) =>
      old.progress != progress ||
      old.foregroundColor != foregroundColor ||
      old.backgroundColor != backgroundColor;
}

// ─── Add Budget Sheet ─────────────────────────────────

class _AddBudgetSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<_AddBudgetSheet> {
  TransactionCategory _selected = TransactionCategory.foodAndDrink;
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: SpendlerSpacing.screenH,
        right: SpendlerSpacing.screenH,
        bottom: MediaQuery.viewInsetsOf(context).bottom + SpendlerSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set Budget',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: SpendlerColors.textPrimary,
            ),
          ),
          const SizedBox(height: SpendlerSpacing.lg),
          // Category picker
          Wrap(
            spacing: SpendlerSpacing.sm,
            runSpacing: SpendlerSpacing.sm,
            children: TransactionCategory.values.map((cat) {
              final isSelected = cat == _selected;
              final color = SpendlerColors.categoryColor(cat);
              return GestureDetector(
                onTap: () => setState(() => _selected = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : SpendlerColors.progressTrack,
                    borderRadius: BorderRadius.circular(SpendlerRadii.pill),
                    border: isSelected
                        ? Border.all(color: color, width: 1.5)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(cat.icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? color
                              : SpendlerColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: SpendlerSpacing.lg),
          // Amount field
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Monthly limit (\$)',
              labelStyle: const TextStyle(color: SpendlerColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SpendlerRadii.button),
                borderSide: const BorderSide(color: SpendlerColors.separator),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SpendlerRadii.button),
                borderSide:
                    const BorderSide(color: SpendlerColors.accent, width: 1.5),
              ),
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: SpendlerColors.textPrimary,
            ),
          ),
          const SizedBox(height: SpendlerSpacing.lg),
          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: SpendlerColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SpendlerRadii.button),
                ),
              ),
              child: const Text(
                'Set Budget',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    final repo = ref.read(repositoryProvider);

    // Upsert: check if budget already exists for this category
    final existing = await repo.getBudgetForCategory(_selected.name);
    if (existing != null) {
      await repo.updateBudget(
        existing.id,
        CategoryBudgetsCompanion(monthlyLimit: Value(amount)),
      );
    } else {
      await repo.insertBudget(CategoryBudgetsCompanion(
        category: Value(_selected.name),
        monthlyLimit: Value(amount),
      ));
    }

    // Invalidate spending cache so UI refreshes
    ref.invalidate(monthlyCategorySpendingProvider);

    if (mounted) Navigator.pop(context);
  }
}

// ─── Add Goal Sheet ───────────────────────────────────

class _AddGoalSheet extends ConsumerStatefulWidget {
  const _AddGoalSheet();

  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedIcon = 'piggyBank';

  static const _iconOptions = [
    ('piggyBank', 'Savings'),
    ('airplane', 'Travel'),
    ('car', 'Car'),
    ('house', 'Home'),
    ('graduationCap', 'Education'),
    ('heartbeat', 'Health'),
    ('laptop', 'Tech'),
    ('gift', 'Gift'),
  ];

  IconData _resolveIcon(String name) {
    switch (name) {
      case 'airplane':
        return PhosphorIcons.airplane();
      case 'car':
        return PhosphorIcons.car();
      case 'house':
        return PhosphorIcons.house();
      case 'graduationCap':
        return PhosphorIcons.graduationCap();
      case 'heartbeat':
        return PhosphorIcons.heartbeat();
      case 'laptop':
        return PhosphorIcons.laptop();
      case 'gift':
        return PhosphorIcons.gift();
      case 'piggyBank':
        return PhosphorIcons.piggyBank();
      default:
        return PhosphorIcons.star();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: SpendlerSpacing.screenH,
        right: SpendlerSpacing.screenH,
        bottom: MediaQuery.viewInsetsOf(context).bottom + SpendlerSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Goal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: SpendlerColors.textPrimary,
            ),
          ),
          const SizedBox(height: SpendlerSpacing.lg),
          // Icon picker
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _iconOptions.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: SpendlerSpacing.sm),
              itemBuilder: (_, i) {
                final (iconName, label) = _iconOptions[i];
                final isSelected = iconName == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconName),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SpendlerColors.accent.withValues(alpha: 0.15)
                              : SpendlerColors.progressTrack,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: SpendlerColors.accent, width: 1.5)
                              : null,
                        ),
                        child: Center(
                          child: PhosphorIcon(
                            _resolveIcon(iconName),
                            size: 20,
                            color: isSelected
                                ? SpendlerColors.accent
                                : SpendlerColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected
                              ? SpendlerColors.accent
                              : SpendlerColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: SpendlerSpacing.md),
          // Name field
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Goal name',
              labelStyle: const TextStyle(color: SpendlerColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SpendlerRadii.button),
                borderSide: const BorderSide(color: SpendlerColors.separator),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SpendlerRadii.button),
                borderSide:
                    const BorderSide(color: SpendlerColors.accent, width: 1.5),
              ),
            ),
            style: const TextStyle(
              fontSize: 15,
              color: SpendlerColors.textPrimary,
            ),
          ),
          const SizedBox(height: SpendlerSpacing.cardGap),
          // Target amount field
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Target amount (\$)',
              labelStyle: const TextStyle(color: SpendlerColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SpendlerRadii.button),
                borderSide: const BorderSide(color: SpendlerColors.separator),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SpendlerRadii.button),
                borderSide:
                    const BorderSide(color: SpendlerColors.accent, width: 1.5),
              ),
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: SpendlerColors.textPrimary,
            ),
          ),
          const SizedBox(height: SpendlerSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: SpendlerColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SpendlerRadii.button),
                ),
              ),
              child: const Text(
                'Create Goal',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final target = double.tryParse(_amountCtrl.text.trim());
    if (name.isEmpty || target == null || target <= 0) return;

    final repo = ref.read(repositoryProvider);
    await repo.insertGoal(SavingsGoalsCompanion(
      name: Value(name),
      targetAmount: Value(target),
      iconName: Value(_selectedIcon),
    ));

    if (mounted) Navigator.pop(context);
  }
}

// ─── Add Money Sheet ──────────────────────────────────

class _AddMoneySheet extends ConsumerStatefulWidget {
  const _AddMoneySheet({required this.goal});
  final SavingsGoal goal;

  @override
  ConsumerState<_AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends ConsumerState<_AddMoneySheet> {
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.goal.targetAmount - widget.goal.currentAmount;

    return Padding(
      padding: EdgeInsets.only(
        left: SpendlerSpacing.screenH,
        right: SpendlerSpacing.screenH,
        bottom: MediaQuery.viewInsetsOf(context).bottom + SpendlerSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add to "${widget.goal.name}"',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: SpendlerColors.textPrimary,
            ),
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          Text(
            '\$${remaining.toStringAsFixed(0)} remaining',
            style: const TextStyle(
              fontSize: 13,
              color: SpendlerColors.textSecondary,
            ),
          ),
          const SizedBox(height: SpendlerSpacing.lg),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Amount (\$)',
              labelStyle: const TextStyle(color: SpendlerColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SpendlerRadii.button),
                borderSide: const BorderSide(color: SpendlerColors.separator),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SpendlerRadii.button),
                borderSide:
                    const BorderSide(color: SpendlerColors.accent, width: 1.5),
              ),
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: SpendlerColors.textPrimary,
            ),
          ),
          const SizedBox(height: SpendlerSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: SpendlerColors.onTrack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SpendlerRadii.button),
                ),
              ),
              child: const Text(
                'Add Money',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    final repo = ref.read(repositoryProvider);
    await repo.addMoney(widget.goal.id, amount);

    if (mounted) Navigator.pop(context);
  }
}

// ─── Shared widgets ───────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: SpendlerSpacing.lg,
        vertical: SpendlerSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: SpendlerColors.card,
        borderRadius: BorderRadius.circular(SpendlerRadii.card),
        boxShadow: SpendlerShadows.card,
      ),
      child: Column(
        children: [
          PhosphorIcon(icon, size: 32, color: SpendlerColors.textTertiary),
          const SizedBox(height: SpendlerSpacing.cardGap),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: SpendlerColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: SpendlerColors.card,
        borderRadius: BorderRadius.circular(SpendlerRadii.card),
        boxShadow: SpendlerShadows.card,
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: SpendlerColors.accent,
          ),
        ),
      ),
    );
  }
}

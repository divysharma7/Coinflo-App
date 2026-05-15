import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/animations.dart';

// ─── Category color helper ────────────────────────────

Color _categoryColor(TransactionCategory cat) {
  const map = <TransactionCategory, Color>{
    TransactionCategory.foodAndDrink: Color(0xFFFF8A4C),
    TransactionCategory.transport: Color(0xFF4A8FE7),
    TransactionCategory.shopping: Color(0xFFB19CD9),
    TransactionCategory.billsAndUtilities: Color(0xFFF59E0B),
    TransactionCategory.healthAndWellness: Color(0xFF22C55E),
    TransactionCategory.entertainment: Color(0xFFE91E63),
    TransactionCategory.streaming: Color(0xFFEC407A),
    TransactionCategory.gymFitness: Color(0xFF4CAF50),
    TransactionCategory.productivityTools: Color(0xFF9575CD),
    TransactionCategory.personalCare: Color(0xFFF8BBD0),
    TransactionCategory.education: Color(0xFF5C6BC0),
    TransactionCategory.travel: Color(0xFF14B8A6),
    TransactionCategory.other: Color(0xFF6E6E73),
  };
  return map[cat] ?? const Color(0xFF6E6E73);
}

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

// ─── Hero Header ──────────────────────────────────────

class _HeroHeader extends ConsumerWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                          color: AppColors.gray400,
                        ),
                      );
                    }
                    return Text(
                      status.remaining >= 0
                          ? '\$${status.remaining.toStringAsFixed(0)} left this month'
                          : '\$${status.remaining.abs().toStringAsFixed(0)} over budget',
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
                        const SizedBox(height: AppSpacing.sm),
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
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      showDragHandle: true,
      builder: (_) => _AddBudgetSheet(),
    );
  }

  Future<void> _deleteBudget(WidgetRef ref, int id) async {
    await deleteBudget(ref.read(repositoryProvider), id);
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
    final percent = budget.monthlyLimit > 0
        ? (spent / budget.monthlyLimit * 100)
        : 0.0;
    final isOver = spent > budget.monthlyLimit;
    final isCritical = percent > 150;
    final categoryColor = _categoryColor(category);
    final barColor = isCritical
        ? AppColors.red
        : isOver
            ? AppColors.orange
            : categoryColor;

    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.lg,
          boxShadow: AppShadows.sm,
          border: isCritical
              ? Border.all(color: AppColors.red.withValues(alpha: 0.4), width: 1.5)
              : isOver
                  ? Border.all(color: AppColors.orange.withValues(alpha: 0.3), width: 1)
                  : null,
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
                    color: isOver
                        ? barColor.withValues(alpha: 0.12)
                        : categoryColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.sm,
                  ),
                  child: Center(
                    child: PhosphorIcon(
                      category.iconFill,
                      size: 18,
                      color: isOver ? barColor : categoryColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: AppTextStyles.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      if (isOver)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              PhosphorIcon(
                                isCritical
                                    ? PhosphorIconsFill.warning
                                    : PhosphorIcons.warning(),
                                size: 12,
                                color: barColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCritical
                                    ? 'Way over budget (${percent.toStringAsFixed(0)}%)'
                                    : 'Over budget (${percent.toStringAsFixed(0)}%)',
                                style: AppTextStyles.labelS.copyWith(
                                  color: barColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '\$${spent.toStringAsFixed(0)} / \$${budget.monthlyLimit.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyS.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isOver ? barColor : AppColors.gray500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Progress bar — 6pt tall, fully rounded
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(3)),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    // Track
                    Container(
                      decoration: BoxDecoration(
                        color: isOver
                            ? barColor.withValues(alpha: 0.15)
                            : AppColors.gray200,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                    // Fill
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(3)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isOver) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '\$${(spent - budget.monthlyLimit).toStringAsFixed(0)} over limit',
                style: AppTextStyles.labelS.copyWith(
                  color: barColor,
                  fontWeight: isCritical ? FontWeight.w700 : FontWeight.w400,
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
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
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
                    const SizedBox(height: AppSpacing.sm),
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
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
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
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      showDragHandle: true,
      builder: (_) => _AddMoneySheet(goal: goal),
    );
  }

  Future<void> _deleteGoal(WidgetRef ref, int id) async {
    await deleteGoal(ref.read(repositoryProvider), id);
  }
}

class _GoalCard extends StatefulWidget {
  const _GoalCard({
    required this.goal,
    required this.onAddMoney,
    required this.onDelete,
  });

  final SavingsGoal goal;
  final VoidCallback onAddMoney;
  final VoidCallback onDelete;

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebrationCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  static const _goldColor = Color(0xFFFBBF24); // amber-400
  static const _goldDark = Color(0xFFF59E0B); // amber-500

  bool get _isCompleted => widget.goal.currentAmount >= widget.goal.targetAmount;

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
  void initState() {
    super.initState();
    _celebrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.03), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _celebrationCtrl,
      curve: Curves.easeInOut,
    ));
    _glowAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _celebrationCtrl,
      curve: Curves.easeInOut,
    ));

    if (_isCompleted) {
      _celebrationCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _GoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isCompleted && !_celebrationCtrl.isAnimating) {
      _celebrationCtrl.repeat();
    } else if (!_isCompleted && _celebrationCtrl.isAnimating) {
      _celebrationCtrl.stop();
      _celebrationCtrl.reset();
    }
  }

  @override
  void dispose() {
    _celebrationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final remaining = goal.targetAmount - goal.currentAmount;

    final ringFg = _isCompleted ? _goldDark : AppColors.black;
    final ringBg = _isCompleted ? _goldColor.withValues(alpha: 0.25) : AppColors.gray200;

    Widget card = GestureDetector(
      onLongPress: () => _showDeleteDialog(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          boxShadow: const [
            ...AppShadows.sm,
          ],
          border: _isCompleted
              ? Border.all(color: _goldColor.withValues(alpha: 0.6), width: 1.5)
              : null,
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
                  foregroundColor: ringFg,
                  backgroundColor: ringBg,
                ),
                child: Center(
                  child: _isCompleted
                      ? const PhosphorIcon(
                          PhosphorIconsFill.trophy,
                          size: 24,
                          color: _goldDark,
                        )
                      : PhosphorIcon(
                          _resolveIcon(goal.iconName),
                          size: 22,
                          color: AppColors.black,
                        ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          goal.name,
                          style: AppTextStyles.bodyM.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      if (_isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _goldColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const PhosphorIcon(
                                PhosphorIconsFill.star,
                                size: 12,
                                color: _goldDark,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Goal reached!',
                                style: AppTextStyles.labelS.copyWith(
                                  color: _goldDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${goal.currentAmount.toStringAsFixed(0)} of \$${goal.targetAmount.toStringAsFixed(0)}',
                    style: AppTextStyles.bodyS.copyWith(
                      color: _isCompleted ? _goldDark : AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remaining > 0
                        ? '\$${remaining.toStringAsFixed(0)} to go'
                        : 'Congratulations!',
                    style: AppTextStyles.labelS.copyWith(
                      color: remaining > 0
                          ? AppColors.gray500
                          : _goldDark,
                      fontWeight: remaining > 0
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Add money button
            if (!_isCompleted)
              GestureDetector(
                onTap: widget.onAddMoney,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.1),
                    borderRadius: AppRadius.sm,
                  ),
                  child: Center(
                    child: Icon(
                      PhosphorIcons.plus(),
                      size: 20,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Wrap in animated scale + glow when completed
    if (_isCompleted) {
      card = AnimatedBuilder(
        animation: _celebrationCtrl,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: _goldColor.withValues(alpha: _glowAnim.value),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: card,
      );
    }

    return card;
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
              widget.onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
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
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Budget',
            style: AppTextStyles.headingM.copyWith(
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Category picker
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: TransactionCategory.values.map((cat) {
              final isSelected = cat == _selected;
              final color = _categoryColor(cat);
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
                        : AppColors.gray200,
                    borderRadius: AppRadius.full,
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
                        style: AppTextStyles.bodyS.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? color : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Amount field
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Monthly limit (\$)',
              labelStyle: TextStyle(color: AppColors.gray500),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.sm,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.sm,
                borderSide: BorderSide(color: AppColors.black, width: 1.5),
              ),
            ),
            style: AppTextStyles.headingS.copyWith(
              color: AppColors.black,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Save button
          AppButton(
            label: 'Set Budget',
            onTap: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    await upsertBudget(
      ref.read(repositoryProvider),
      category: _selected.name,
      monthlyLimit: amount,
    );

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
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Goal',
            style: AppTextStyles.headingM.copyWith(
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Icon picker
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _iconOptions.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.xs),
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
                              ? AppColors.black.withValues(alpha: 0.15)
                              : AppColors.gray200,
                          borderRadius: AppRadius.sm,
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.black, width: 1.5)
                              : null,
                        ),
                        child: Center(
                          child: PhosphorIcon(
                            _resolveIcon(iconName),
                            size: 20,
                            color: isSelected
                                ? AppColors.black
                                : AppColors.gray500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: AppTextStyles.labelS.copyWith(
                          fontSize: 9,
                          color: isSelected
                              ? AppColors.black
                              : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Name field
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Goal name',
              labelStyle: TextStyle(color: AppColors.gray500),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.sm,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.sm,
                borderSide: BorderSide(color: AppColors.black, width: 1.5),
              ),
            ),
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Target amount field
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Target amount (\$)',
              labelStyle: TextStyle(color: AppColors.gray500),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.sm,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.sm,
                borderSide: BorderSide(color: AppColors.black, width: 1.5),
              ),
            ),
            style: AppTextStyles.headingS.copyWith(
              color: AppColors.black,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Create Goal',
            onTap: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final target = double.tryParse(_amountCtrl.text.trim());
    if (name.isEmpty || target == null || target <= 0) return;

    await insertGoal(
      ref.read(repositoryProvider),
      name: name,
      targetAmount: target,
      iconName: _selectedIcon,
    );

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
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add to "${widget.goal.name}"',
            style: AppTextStyles.headingM.copyWith(
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '\$${remaining.toStringAsFixed(0)} remaining',
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Amount (\$)',
              labelStyle: TextStyle(color: AppColors.gray500),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.sm,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.sm,
                borderSide: BorderSide(color: AppColors.black, width: 1.5),
              ),
            ),
            style: AppTextStyles.headingS.copyWith(
              color: AppColors.black,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Add Money',
            onTap: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    await addMoneyToGoal(ref.read(repositoryProvider), widget.goal.id, amount);

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
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          PhosphorIcon(icon, size: 32, color: AppColors.gray500),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.gray500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatefulWidget {
  const _LoadingCard();

  @override
  State<_LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<_LoadingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, child) {
        final shimmerValue = _shimmerCtrl.value;
        final baseColor = AppColors.gray200;
        final highlightColor = AppColors.gray100;
        final color = Color.lerp(
          baseColor,
          highlightColor,
          (0.5 + 0.5 * (shimmerValue * 2 - 1).abs()).clamp(0.0, 1.0),
        )!;
        return Column(
          children: [
            _SkeletonCard(color: color),
            const SizedBox(height: AppSpacing.sm),
            _SkeletonCard(color: color),
          ],
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon placeholder
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: AppRadius.sm,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Title placeholder
              Expanded(
                child: Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              // Amount placeholder
              Container(
                height: 12,
                width: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Progress bar placeholder
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

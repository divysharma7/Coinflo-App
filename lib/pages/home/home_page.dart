import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/notification_bell.dart';
import 'package:finance_buddy_app/widgets/charts/spend_bar_chart.dart';
import 'package:finance_buddy_app/widgets/common/animated_progress_bar.dart';
import 'package:finance_buddy_app/pages/home/daily_view_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _HeaderSection()),
        SliverToBoxAdapter(child: _BudgetProgressBar()),
        SliverToBoxAdapter(child: _QuickStatsRow()),
        SliverToBoxAdapter(child: _DailySpendChart()),
        SliverToBoxAdapter(child: _TopCategoriesSection()),
        SliverToBoxAdapter(child: _SavingsGoalsSection()),
        SliverToBoxAdapter(child: _RecentTransactionsSection()),
        SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ─── Dark Header ──────────────────────────────────────────

class _HeaderSection extends ConsumerWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final userName = ref.watch(userNameProvider);

    final monthLabel = DateFormat('MMMM yyyy').format(month);
    final name = userName.valueOrNull;
    final hasName = name != null && name.trim().isNotEmpty;
    final greeting = hasName ? 'Hi, $name' : 'Hi there';

    return Container(
      color: AppColors.black,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.paddingOf(context).top + AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          // Avatar
          hasName
              ? _UserAvatar(userName: name)
              : Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(PhosphorIcons.user(),
                      color: AppColors.white.withValues(alpha: 0.6), size: 18),
                ),
          const SizedBox(width: AppSpacing.sm),
          // Greeting + month
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: AppTextStyles.headingS
                        .copyWith(color: AppColors.white)),
                GestureDetector(
                  onTap: () => _showMonthPicker(context, ref, month),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(monthLabel,
                          style: AppTextStyles.bodyS.copyWith(
                              color: AppColors.white.withValues(alpha: 0.6))),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down,
                          color: AppColors.white.withValues(alpha: 0.6),
                          size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const NotificationBell(color: AppColors.white),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref, DateTime current) {
    final now = DateTime.now();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final months = List.generate(12, (i) => DateTime(now.year, now.month - i));
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...months.map((m) {
                final isSelected =
                    m.year == current.year && m.month == current.month;
                return ListTile(
                  title: Text(DateFormat('MMMM yyyy').format(m),
                      style: AppTextStyles.bodyM.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.black
                              : AppColors.gray500)),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.black, size: 20)
                      : null,
                  onTap: () {
                    ref.read(selectedMonthProvider.notifier).state = m;
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}

// ─── Budget Progress Bar (HERO) ───────────────────────────

class _BudgetProgressBar extends ConsumerWidget {
  const _BudgetProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expense = ref.watch(monthlyExpenseProvider);
    final budgetAsync = ref.watch(monthlyBudgetProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final month = ref.watch(selectedMonthProvider);
    final symbol = _currencySymbol(currencyAsync.valueOrNull ?? 'inr');

    final budgetVal = budgetAsync.valueOrNull;
    final now = DateTime.now();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final daysLeft = month.year == now.year && month.month == now.month
        ? daysInMonth - now.day
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: expense.when(
        data: (spent) {
          if (budgetVal == null || budgetVal <= 0) {
            return _noBudgetCard(context, ref);
          }
          final pct = (spent / budgetVal).clamp(0.0, 1.0);
          final remaining = (budgetVal - spent).clamp(0.0, double.infinity);
          final barColor = pct < 0.6
              ? const Color(0xFF22C55E)
              : pct < 0.85
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFEF4444);

          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 20,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                // Spent / Budget labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$symbol${_formatNumber(spent)} spent',
                        style: AppTextStyles.headingS
                            .copyWith(color: AppColors.black)),
                    Text('of $symbol${_formatNumber(budgetVal)}',
                        style: AppTextStyles.bodyM
                            .copyWith(color: AppColors.gray400)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Progress bar
                AnimatedProgressBar(
                  value: pct,
                  backgroundColor: AppColors.gray200,
                  valueColor: barColor,
                  minHeight: 12,
                  borderRadius: 6,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Stats below bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(pct * 100).round()}% used',
                      style: AppTextStyles.bodyS.copyWith(color: barColor, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$symbol${_formatNumber(remaining)} left · $daysLeft days',
                      style: AppTextStyles.bodyS.copyWith(color: AppColors.gray400),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox(height: 100),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _noBudgetCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray200, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(PhosphorIcons.target(), size: 20, color: AppColors.gray400),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set a monthly budget',
                    style: AppTextStyles.bodyM
                        .copyWith(fontWeight: FontWeight.w600)),
                Text('Track your spending against a limit',
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.gray400)),
              ],
            ),
          ),
          Icon(PhosphorIcons.caretRight(), size: 18, color: AppColors.gray400),
        ],
      ),
    );
  }
}

// ─── Quick Stats Row ──────────────────────────────────────

class _QuickStatsRow extends ConsumerWidget {
  const _QuickStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todaySpendingProvider);
    final monthExpense = ref.watch(monthlyExpenseProvider);
    final lastMonthAsync = ref.watch(lastMonthExpenseProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final symbol = _currencySymbol(currencyAsync.valueOrNull ?? 'inr');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          // Today
          Expanded(
            child: _StatCard(
              label: 'Today',
              value: todayAsync.when(
                data: (v) => '$symbol${_formatNumber(v)}',
                loading: () => '—',
                error: (_, _) => '—',
              ),
              icon: PhosphorIcons.sun(),
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // This month
          Expanded(
            child: _StatCard(
              label: 'This month',
              value: monthExpense.when(
                data: (v) => '$symbol${_formatNumber(v)}',
                loading: () => '—',
                error: (_, _) => '—',
              ),
              icon: PhosphorIcons.calendarBlank(),
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // vs Last month
          Expanded(
            child: _vsLastMonthCard(monthExpense, lastMonthAsync),
          ),
        ],
      ),
    );
  }

  Widget _vsLastMonthCard(
      AsyncValue<double> current, AsyncValue<double> last) {
    final curVal = current.valueOrNull ?? 0;
    final lastVal = last.valueOrNull ?? 0;

    String label;
    Color color;
    IconData icon;

    if (lastVal == 0) {
      label = '—';
      color = AppColors.gray400;
      icon = PhosphorIcons.trendUp();
    } else {
      final pct = ((curVal - lastVal) / lastVal * 100).round();
      if (pct >= 0) {
        label = '\u2191 $pct%';
        color = const Color(0xFFEF4444);
        icon = PhosphorIcons.trendUp();
      } else {
        label = '\u2193 ${pct.abs()}%';
        color = const Color(0xFF22C55E);
        icon = PhosphorIcons.trendDown();
      }
    }

    return _StatCard(
      label: 'vs Last month',
      value: label,
      icon: icon,
      color: color,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.gray400),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style: AppTextStyles.headingS
                  .copyWith(color: color, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  AppTextStyles.labelS.copyWith(color: AppColors.gray400)),
        ],
      ),
    );
  }
}

// ─── Daily Spend Bar Chart ────────────────────────────────

class _DailySpendChart extends ConsumerWidget {
  const _DailySpendChart();

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekStartProvider);
    final dailyAsync = ref.watch(dailySpendingForWeekProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final symbol = _currencySymbol(currencyAsync.valueOrNull ?? 'inr');

    final weekEnd = weekStart.add(const Duration(days: 6));
    final label =
        '${DateFormat('d MMM').format(weekStart)} – ${DateFormat('d MMM').format(weekEnd)}';
    final now = DateTime.now();
    final currentWeekStart =
        DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final canForward = weekStart.isBefore(currentWeekStart);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000),
                blurRadius: 16,
                offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daily Spend',
                    style: AppTextStyles.headingS
                        .copyWith(color: AppColors.black)),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => ref
                          .read(selectedWeekStartProvider.notifier)
                          .state = weekStart.subtract(const Duration(days: 7)),
                      child: const Icon(Icons.chevron_left,
                          color: AppColors.gray400, size: 22),
                    ),
                    Text(label,
                        style: AppTextStyles.labelS
                            .copyWith(color: AppColors.gray500)),
                    GestureDetector(
                      onTap: canForward
                          ? () => ref
                              .read(selectedWeekStartProvider.notifier)
                              .state = weekStart.add(const Duration(days: 7))
                          : null,
                      child: Icon(Icons.chevron_right,
                          color: canForward
                              ? AppColors.gray400
                              : AppColors.gray200,
                          size: 22),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            dailyAsync.when(
              data: (values) => SpendBarChart(
                values: values,
                labels: _dayLabels,
                currencySymbol: symbol,
                onBarTap: (i) {
                  final tappedDate = weekStart.add(Duration(days: i));
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => DailyViewPage(date: tappedDate),
                    ),
                  );
                },
              ),
              loading: () => const SizedBox(
                  height: 180,
                  child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.black))),
              error: (_, _) => const SizedBox(height: 180),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top 3 Categories ─────────────────────────────────────

class _TopCategoriesSection extends ConsumerWidget {
  const _TopCategoriesSection();

  static const Map<TransactionCategory, Color> _catColors = {
    TransactionCategory.foodAndDrink: Color(0xFFFF8A4C),
    TransactionCategory.transport: Color(0xFF4A8FE7),
    TransactionCategory.shopping: Color(0xFFB19CD9),
    TransactionCategory.billsAndUtilities: Color(0xFFF59E0B),
    TransactionCategory.healthAndWellness: Color(0xFF22C55E),
    TransactionCategory.entertainment: Color(0xFFE91E63),
    TransactionCategory.personalCare: Color(0xFFF8BBD0),
    TransactionCategory.education: Color(0xFF5C6BC0),
    TransactionCategory.travel: Color(0xFF14B8A6),
    TransactionCategory.other: Color(0xFF6E6E73),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topCats = ref.watch(topCategoriesProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final symbol = _currencySymbol(currencyAsync.valueOrNull ?? 'inr');

    return topCats.when(
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();
        final maxVal = entries.first.value;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 16,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Where it\'s going',
                    style: AppTextStyles.headingS
                        .copyWith(color: AppColors.black)),
                const SizedBox(height: AppSpacing.lg),
                ...entries.map((entry) {
                  final cat = TransactionCategory.values.firstWhere(
                    (c) => c.name == entry.key,
                    orElse: () => TransactionCategory.other,
                  );
                  final color =
                      _catColors[cat.group] ?? const Color(0xFF6E6E73);
                  final pct = maxVal > 0 ? entry.value / maxVal : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(cat.iconFill, size: 18, color: color),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(cat.label,
                                      style: AppTextStyles.bodyM.copyWith(
                                          fontWeight: FontWeight.w500)),
                                  Text(
                                      '$symbol${_formatNumber(entry.value)}',
                                      style: AppTextStyles.bodyM.copyWith(
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              AnimatedProgressBar(
                                value: pct,
                                backgroundColor: AppColors.gray100,
                                valueColor: color,
                              ),
                            ],
                          ),
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
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ─── Savings Goals ────────────────────────────────────────

class _SavingsGoalsSection extends ConsumerWidget {
  const _SavingsGoalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final symbol = _currencySymbol(currencyAsync.valueOrNull ?? 'inr');

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
                    return Container(
                      width: 160,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 8,
                              offset: Offset(0, 2)),
                        ],
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
                            '$symbol${_formatNumber(g.currentAmount)} / $symbol${_formatNumber(g.targetAmount)}',
                            style: AppTextStyles.labelS
                                .copyWith(color: AppColors.gray400),
                          ),
                          AnimatedProgressBar(
                            value: pct,
                            backgroundColor: AppColors.gray200,
                            valueColor: const Color(0xFF22C55E),
                          ),
                          Text('${(pct * 100).round()}%',
                              style: AppTextStyles.labelS.copyWith(
                                  color: const Color(0xFF22C55E),
                                  fontWeight: FontWeight.w600)),
                        ],
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
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ─── Recent Transactions (last 5) ─────────────────────────

class _RecentTransactionsSection extends ConsumerWidget {
  const _RecentTransactionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(monthlyTransactionsForHomeProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final symbol = _currencySymbol(currencyAsync.valueOrNull ?? 'inr');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with See All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent',
                  style:
                      AppTextStyles.headingS.copyWith(color: AppColors.black)),
              GestureDetector(
                onTap: () {
                  // Switch to transactions tab
                  ref.read(selectedTabProvider.notifier).state = 1;
                },
                child: Text('See all',
                    style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          txnsAsync.when(
            data: (txns) {
              if (txns.isEmpty) return _buildEmptyState();

              final sorted = List<SpendlerTransaction>.from(txns)
                ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
              final recent = sorted.take(5).toList();

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: recent.asMap().entries.map((e) {
                    final isLast = e.key == recent.length - 1;
                    return Column(
                      children: [
                        _TransactionRow(transaction: e.value, symbol: symbol),
                        if (!isLast)
                          const Padding(
                            padding: EdgeInsets.only(left: 56),
                            child: Divider(
                                height: 1,
                                thickness: 0.5,
                                color: AppColors.gray200),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.black)),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(PhosphorIcons.receipt(),
                  size: 24, color: AppColors.gray300),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No transactions yet',
                style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
            const SizedBox(height: AppSpacing.xxs),
            Text('Tap + to add your first expense',
                style: AppTextStyles.bodyS.copyWith(color: AppColors.gray400)),
          ],
        ),
      ),
    );
  }
}

// ─── Transaction Row ──────────────────────────────────────

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.symbol});

  final SpendlerTransaction transaction;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == transaction.category,
      orElse: () => TransactionCategory.other,
    );
    final isExpense = transaction.amount < 0;
    final displayAmount =
        '${isExpense ? '-' : '+'}$symbol${transaction.amount.abs().toStringAsFixed(0)}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DailyViewPage(date: transaction.happenedAt),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _catBgColor(cat),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.iconFill, size: 18, color: _catIconColor(cat)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.note ?? transaction.merchant ?? cat.label,
                      style: AppTextStyles.bodyM.copyWith(
                          fontWeight: FontWeight.w500, color: AppColors.black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(cat.label,
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.gray400, fontSize: 12)),
                ],
              ),
            ),
            Text(displayAmount,
                style: AppTextStyles.numericL.copyWith(
                    color: isExpense ? AppColors.black : AppColors.green)),
          ],
        ),
      ),
    );
  }

  Color _catBgColor(TransactionCategory cat) {
    switch (cat.group) {
      case TransactionCategory.foodAndDrink:
        return AppColors.catOrangeBg;
      case TransactionCategory.transport:
        return AppColors.catBlueBg;
      case TransactionCategory.shopping:
        return AppColors.catPurpleBg;
      case TransactionCategory.entertainment:
        return AppColors.catPinkBg;
      case TransactionCategory.healthAndWellness:
        return AppColors.catGreenBg;
      default:
        return AppColors.catGrayBg;
    }
  }

  Color _catIconColor(TransactionCategory cat) {
    switch (cat.group) {
      case TransactionCategory.foodAndDrink:
        return AppColors.catOrangeText;
      case TransactionCategory.transport:
        return AppColors.catBlueText;
      case TransactionCategory.shopping:
        return AppColors.catPurpleText;
      case TransactionCategory.entertainment:
        return AppColors.catPinkText;
      case TransactionCategory.healthAndWellness:
        return AppColors.catGreenText;
      default:
        return AppColors.catGrayText;
    }
  }
}

// ─── User Avatar ──────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.userName});
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(userName);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(initials,
            style: AppTextStyles.bodyS
                .copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

// ─── Helpers ──────────────────────────────────────────────

String _formatNumber(double value) {
  if (value >= 100000) {
    return NumberFormat('#,##,###', 'en_IN').format(value.toInt());
  }
  return NumberFormat('#,###').format(value.toInt());
}

String _currencySymbol(String code) {
  switch (code.toLowerCase()) {
    case 'inr':
      return '\u20B9';
    case 'usd':
      return '\$';
    case 'eur':
      return '\u20AC';
    case 'gbp':
      return '\u00A3';
    case 'jpy':
      return '\u00A5';
    default:
      return '\$';
  }
}

import 'package:finance_buddy_app/widgets/common/error_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/services/export/csv_exporter.dart';
import 'package:finance_buddy_app/widgets/charts/spend_bar_chart.dart';
import 'package:finance_buddy_app/widgets/common/animated_progress_bar.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Page-local providers
// ---------------------------------------------------------------------------

final _reportMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

enum _ReportScope { week, month, year }

final _reportScopeProvider =
    StateProvider<_ReportScope>((ref) => _ReportScope.week);

final _monthCategoryTotalsProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final month = ref.watch(_reportMonthProvider);
  return repo.getCategoryTotalsForMonth(month);
});

final _prevMonthCategoryTotalsProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final month = ref.watch(_reportMonthProvider);
  final prev = DateTime(month.year, month.month - 1);
  return repo.getCategoryTotalsForMonth(prev);
});

// ---------------------------------------------------------------------------
// Colors & helpers
// ---------------------------------------------------------------------------

String _sym(String code) {
  switch (code.toLowerCase()) {
    case 'inr': return '\u20B9';
    case 'usd': return '\$';
    case 'eur': return '\u20AC';
    case 'gbp': return '\u00A3';
    default: return '\$';
  }
}

String _fmt(double v) {
  if (v >= 100000) return NumberFormat('#,##,###', 'en_IN').format(v.toInt());
  return NumberFormat('#,###').format(v.toInt());
}

// ---------------------------------------------------------------------------
// Report Page
// ---------------------------------------------------------------------------

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});
  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final scope = ref.watch(_reportScopeProvider);
    final symbol = _sym(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.black,
          backgroundColor: AppColors.white,
          onRefresh: () async {
            ref.invalidate(_monthCategoryTotalsProvider);
            ref.invalidate(_prevMonthCategoryTotalsProvider);
            ref.invalidate(budgetsProvider);
            ref.invalidate(weeklyTotalsForMonthProvider);
            ref.invalidate(monthlyTotalsForYearProvider);
            ref.invalidate(yearlyTotalsProvider);
            ref.invalidate(monthEndProjectionProvider);
            ref.invalidate(goalsProvider);
            ref.invalidate(streakProvider);
            ref.invalidate(monthlyBudgetProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                _buildHeader(),
                const SizedBox(height: AppSpacing.lg),
                const _PeriodSelector(),
                const SizedBox(height: AppSpacing.lg),
                _buildPeriodNavigator(),
                const SizedBox(height: AppSpacing.xl),
                _buildBarChartSection(scope, symbol)
                    .animate().fadeIn(duration: AppDurations.slow).slideY(begin: 0.05, duration: AppDurations.slow),
                const SizedBox(height: AppSpacing.lg),
                _ProjectionCard(symbol: symbol)
                    .animate().fadeIn(delay: 80.ms, duration: AppDurations.slow).slideY(begin: 0.05, delay: 80.ms, duration: AppDurations.slow),
                const SizedBox(height: AppSpacing.lg),
                _buildBudgetVsActual(symbol)
                    .animate().fadeIn(delay: 160.ms, duration: AppDurations.slow).slideY(begin: 0.05, delay: 160.ms, duration: AppDurations.slow),
                const SizedBox(height: AppSpacing.lg),
                const _SavingsGoalsSection()
                    .animate().fadeIn(delay: 240.ms, duration: AppDurations.slow).slideY(begin: 0.05, delay: 240.ms, duration: AppDurations.slow),
                const SizedBox(height: AppSpacing.lg),
                _StreakBadge(symbol: symbol)
                    .animate().fadeIn(delay: 320.ms, duration: AppDurations.slow).slideY(begin: 0.05, delay: 320.ms, duration: AppDurations.slow),
                const SizedBox(height: AppSpacing.lg),
                _buildDonutSection(symbol)
                    .animate().fadeIn(delay: 400.ms, duration: AppDurations.slow).slideY(begin: 0.05, delay: 400.ms, duration: AppDurations.slow),
                const SizedBox(height: AppSpacing.xxl),
                _buildCategoryBreakdown(symbol)
                    .animate().fadeIn(delay: 480.ms, duration: AppDurations.slow).slideY(begin: 0.05, delay: 480.ms, duration: AppDurations.slow),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Import Banner (shown when < 10 transactions) ─────

  // ─── Header with Export ─────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Report',
              style: AppTextStyles.headingL.copyWith(color: AppColors.black)),
          GestureDetector(
            onTap: () => _showExportConfirmation(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.base,
              ),
              child: Icon(PhosphorIcons.export(), color: AppColors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportConfirmation() {
    final month = ref.read(_reportMonthProvider);
    final label = DateFormat('MMMM yyyy').format(month);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('Export Report',
            style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
        content: Text(
          'Export your $label spending report as CSV? This will include every transaction with date, merchant, category, amount, note, and type.',
          style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _exportCsv(month, label);
            },
            child: Text('Export',
                style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.black, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(DateTime month, String label) async {
    try {
      final repo = ref.read(repositoryProvider);
      final transactions = await repo.getTransactionsForMonth(month);
      if (transactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nothing to export this month.')),
          );
        }
        return;
      }
      await CsvExporter.exportAndShare(transactions, label);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  // ─── Period Navigator ───────────────────────────────────

  Widget _buildPeriodNavigator() {
    final scope = ref.watch(_reportScopeProvider);
    final month = ref.watch(_reportMonthProvider);
    final year = ref.watch(selectedChartYearProvider);

    String label;
    switch (scope) {
      case _ReportScope.week:
        label = DateFormat('MMMM yyyy').format(month);
      case _ReportScope.month:
        label = '$year';
      case _ReportScope.year:
        label = 'All Time';
    }

    final canForward = _canForward(scope, month, year);
    final showNav = scope != _ReportScope.year;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showNav)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _navigate(-1, scope, month, year);
              },
              child: const Icon(Icons.chevron_left, color: AppColors.gray500, size: 28),
            )
          else
            const SizedBox(width: 28),
          Text(label, style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          if (showNav)
            GestureDetector(
              onTap: canForward
                  ? () {
                      HapticFeedback.selectionClick();
                      _navigate(1, scope, month, year);
                    }
                  : null,
              child: Icon(Icons.chevron_right,
                  color: canForward ? AppColors.gray500 : AppColors.gray200,
                  size: 28),
            )
          else
            const SizedBox(width: 28),
        ],
      ),
    );
  }

  void _navigate(int dir, _ReportScope scope, DateTime month, int year) {
    switch (scope) {
      case _ReportScope.week:
        final next = DateTime(month.year, month.month + dir);
        ref.read(_reportMonthProvider.notifier).state = next;
        ref.read(selectedChartMonthProvider.notifier).state = next;
      case _ReportScope.month:
        ref.read(selectedChartYearProvider.notifier).state = year + dir;
      case _ReportScope.year:
        break;
    }
  }

  bool _canForward(_ReportScope scope, DateTime month, int year) {
    final now = DateTime.now();
    switch (scope) {
      case _ReportScope.week:
        final next = DateTime(month.year, month.month + 1);
        return next.isBefore(now) || (next.month == now.month && next.year == now.year);
      case _ReportScope.month:
        return year < now.year;
      case _ReportScope.year:
        return false;
    }
  }

  // ─── Bar Chart ──────────────────────────────────────────

  Widget _buildBarChartSection(_ReportScope scope, String symbol) {
    String title;
    switch (scope) {
      case _ReportScope.week:
        title = 'Weekly Breakdown';
      case _ReportScope.month:
        title = 'Monthly Overview';
      case _ReportScope.year:
        title = 'Yearly Totals';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: _cardDecor(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
            const SizedBox(height: AppSpacing.lg),
            _buildChart(scope, symbol),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(_ReportScope scope, String symbol) {
    switch (scope) {
      case _ReportScope.week:
        return _WeeklyBarChart(symbol: symbol);
      case _ReportScope.month:
        return _MonthlyBarChart(symbol: symbol);
      case _ReportScope.year:
        return _YearlyBarChart(symbol: symbol);
    }
  }

  // ─── Budget vs Actual (per category) ────────────────────

  Widget _buildBudgetVsActual(String symbol) {
    final budgets = ref.watch(budgetsProvider);
    final spending = ref.watch(_monthCategoryTotalsProvider);

    return budgets.when(
      data: (budgetList) {
        if (budgetList.isEmpty) return const SizedBox.shrink();
        final spendMap = spending.valueOrNull ?? {};

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: _cardDecor(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Budget Health',
                    style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
                const SizedBox(height: 4),
                Text('How each category is tracking',
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500)),
                const SizedBox(height: AppSpacing.lg),
                ...budgetList.map((b) {
                  final cat = TransactionCategory.values.firstWhere(
                    (c) => c.name == b.category,
                    orElse: () => TransactionCategory.other,
                  );
                  final spent = spendMap[b.category] ?? 0;
                  final pct = b.monthlyLimit > 0
                      ? (spent / b.monthlyLimit).clamp(0.0, 1.0)
                      : 0.0;
                  final color = AppColors.categoryColor(cat);
                  final barColor = pct < 0.6
                      ? AppColors.green
                      : pct < 0.85
                          ? AppColors.amber
                          : AppColors.red;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(cat.iconFill, size: 16, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(cat.label,
                                  style: AppTextStyles.bodyM
                                      .copyWith(fontWeight: FontWeight.w500)),
                            ),
                            Text(
                              '$symbol${_fmt(spent)} / $symbol${_fmt(b.monthlyLimit)}',
                              style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AnimatedProgressBar(
                          value: pct,
                          backgroundColor: AppColors.gray100,
                          valueColor: barColor,
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

  // ─── Donut Chart ────────────────────────────────────────

  Widget _buildDonutSection(String symbol) {
    final catTotals = ref.watch(_monthCategoryTotalsProvider);
    final budgetAsync = ref.watch(monthlyBudgetProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: catTotals.when(
        data: (data) {
          if (data.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: _cardDecor(),
              child: Center(
                child: Text('No spending this period — nice!',
                    style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
              ),
            );
          }

          final sorted = data.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final totalSpent = sorted.fold<double>(0, (s, e) => s + e.value);
          final budgetVal = budgetAsync.valueOrNull ?? 0;
          final pct = budgetVal > 0 ? (totalSpent / budgetVal * 100).round() : 0;
          final left = budgetVal > 0
              ? (budgetVal - totalSpent).clamp(0.0, double.infinity) : 0.0;

          final sections = <PieChartSectionData>[];
          for (int i = 0; i < sorted.length; i++) {
            final cat = TransactionCategory.values.firstWhere(
              (c) => c.name == sorted[i].key,
              orElse: () => TransactionCategory.other,
            );
            sections.add(PieChartSectionData(
              value: sorted[i].value,
              color: AppColors.categoryColor(cat),
              radius: _touchedIndex == i ? 32 : 26,
              title: '',
            ));
          }

          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: _cardDecor(),
            child: Column(
              children: [
                Text('Spending Split',
                    style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(PieChartData(
                        sections: sections,
                        centerSpaceRadius: 65,
                        sectionsSpace: 3,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            if (!event.isInterestedForInteractions ||
                                response?.touchedSection == null) {
                              setState(() => _touchedIndex = null);
                              return;
                            }
                            setState(() => _touchedIndex =
                                response!.touchedSection!.touchedSectionIndex);
                          },
                        ),
                      )),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$pct%',
                              style: AppTextStyles.displayL
                                  .copyWith(color: AppColors.black, fontSize: 32)),
                          Text('of budget',
                              style: AppTextStyles.bodyS
                                  .copyWith(color: AppColors.gray500)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  alignment: WrapAlignment.center,
                  children: sorted.map((e) {
                    final cat = TransactionCategory.values.firstWhere(
                      (c) => c.name == e.key,
                      orElse: () => TransactionCategory.other,
                    );
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8,
                            decoration: BoxDecoration(
                                color: AppColors.categoryColor(cat),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(cat.label,
                            style: AppTextStyles.labelS
                                .copyWith(color: AppColors.gray500)),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dotLabel(AppColors.black, 'Spent $symbol${_fmt(totalSpent)}'),
                    const SizedBox(width: AppSpacing.lg),
                    _dotLabel(AppColors.gray300, 'Left $symbol${_fmt(left)}'),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator(color: AppColors.black))),
        error: (_, _) => const ErrorCard(),
      ),
    );
  }

  Widget _dotLabel(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500)),
      ],
    );
  }

  // ─── Category Breakdown ─────────────────────────────────

  Widget _buildCategoryBreakdown(String symbol) {
    final catTotals = ref.watch(_monthCategoryTotalsProvider);
    final prevTotals = ref.watch(_prevMonthCategoryTotalsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('By Category',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          const SizedBox(height: 4),
          Text('Tap to see where each rupee went',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppSpacing.lg),
          catTotals.when(
            data: (data) {
              if (data.isEmpty) {
                return Text('No spending data yet.',
                    style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500));
              }
              final sorted = data.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final totalSpent = sorted.fold<double>(0, (s, e) => s + e.value);
              final prevData = prevTotals.valueOrNull ?? {};

              return Column(
                children: sorted.map((entry) {
                  final cat = TransactionCategory.values.firstWhere(
                    (c) => c.name == entry.key,
                    orElse: () => TransactionCategory.other,
                  );
                  final amount = entry.value;
                  final pct = totalSpent > 0 ? amount / totalSpent : 0.0;
                  final catColor = AppColors.categoryColor(cat);

                  // Fixed delta: handle zero correctly
                  final prevAmount = prevData[entry.key] ?? 0.0;
                  int? delta;
                  if (prevAmount > 0) {
                    delta = ((amount - prevAmount) / prevAmount * 100).round();
                  }

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final month = ref.read(_reportMonthProvider);
                      context.push('/report/category', extra: {
                        'category': entry.key,
                        'month': month,
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: _cardDecor(),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: AppRadius.base,
                            ),
                            child: Icon(cat.iconFill, size: 20, color: catColor),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat.label,
                                    style: AppTextStyles.bodyM.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.black)),
                                if (delta != null && delta != 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${delta > 0 ? '\u2191' : '\u2193'} ${delta.abs()}% vs last month',
                                    style: AppTextStyles.labelS.copyWith(
                                      color: delta > 0
                                          ? AppColors.red
                                          : AppColors.green,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ] else if (delta == 0) ...[
                                  const SizedBox(height: 2),
                                  Text('Same as last month',
                                      style: AppTextStyles.labelS
                                          .copyWith(color: AppColors.gray500)),
                                ],
                              ],
                            ),
                          ),
                          Text('$symbol${_fmt(amount)}',
                              style: AppTextStyles.numericL
                                  .copyWith(color: AppColors.black)),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 40,
                            child: Column(
                              children: [
                                Text('${(pct * 100).round()}%',
                                    style: AppTextStyles.labelS
                                        .copyWith(color: AppColors.gray500)),
                                const SizedBox(height: 4),
                                AnimatedProgressBar(
                                  value: pct,
                                  backgroundColor: AppColors.gray200,
                                  valueColor: catColor,
                                  minHeight: 4,
                                  borderRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 18, color: AppColors.gray300),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const ErrorCard(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card decoration helper
// ---------------------------------------------------------------------------

BoxDecoration _cardDecor() => BoxDecoration(
      color: AppColors.white,
      borderRadius: AppRadius.lg,
      boxShadow: const [
        BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 4)),
      ],
    );

// ---------------------------------------------------------------------------
// Period Selector
// ---------------------------------------------------------------------------

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_reportScopeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: AppRadius.xxl,
        ),
        child: Row(
          children: _ReportScope.values.map((scope) {
            final isSel = scope == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(_reportScopeProvider.notifier).state = scope;
                },
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.black : Colors.transparent,
                    borderRadius: AppRadius.xlSm,
                  ),
                  child: Center(
                    child: Text(
                      scope.name[0].toUpperCase() + scope.name.substring(1),
                      style: AppTextStyles.bodyS.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSel ? AppColors.white : AppColors.gray500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bar Chart Widgets
// ---------------------------------------------------------------------------

class _WeeklyBarChart extends ConsumerWidget {
  const _WeeklyBarChart({required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weeklyTotalsForMonthProvider);
    return async.when(
      data: (v) => SpendBarChart(
          values: v,
          labels: const ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
          currencySymbol: symbol),
      loading: () => const SizedBox(height: 180,
          child: Center(child: CircularProgressIndicator(color: AppColors.black))),
      error: (_, _) => const SizedBox(height: 180),
    );
  }
}

class _MonthlyBarChart extends ConsumerWidget {
  const _MonthlyBarChart({required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(monthlyTotalsForYearProvider);
    return async.when(
      data: (v) => SpendBarChart(
          values: v,
          labels: const ['J','F','M','A','M','J','J','A','S','O','N','D'],
          currencySymbol: symbol, height: 200),
      loading: () => const SizedBox(height: 200,
          child: Center(child: CircularProgressIndicator(color: AppColors.black))),
      error: (_, _) => const SizedBox(height: 200),
    );
  }
}

class _YearlyBarChart extends ConsumerWidget {
  const _YearlyBarChart({required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(yearlyTotalsProvider);
    return async.when(
      data: (data) {
        if (data.isEmpty) {
          return SizedBox(height: 180,
              child: Center(child: Text('Not enough data yet',
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500))));
        }
        final years = data.keys.toList()..sort();
        return SpendBarChart(
            values: years.map((y) => data[y]!).toList(),
            labels: years.map((y) => '$y').toList(),
            currencySymbol: symbol);
      },
      loading: () => const SizedBox(height: 180,
          child: Center(child: CircularProgressIndicator(color: AppColors.black))),
      error: (_, _) => const SizedBox(height: 180),
    );
  }
}

// ---------------------------------------------------------------------------
// Month-End Projection Card
// ---------------------------------------------------------------------------

class _ProjectionCard extends ConsumerWidget {
  const _ProjectionCard({required this.symbol});
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
              decoration: _cardDecor(),
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
            ? 'You\'re on track for ~$symbol${_fmt(proj.projected)} by month end based on your spending shape.'
            : 'At your current pace, you\'ll spend $symbol${_fmt(proj.projected)} by month end.';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: _cardDecor(),
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

// ---------------------------------------------------------------------------
// Savings Goals
// ---------------------------------------------------------------------------

class _SavingsGoalsSection extends ConsumerWidget {
  const _SavingsGoalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final sym = _sym(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: _cardDecor(),
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
                              '$sym${_fmt(g.currentAmount)} / $sym${_fmt(g.targetAmount)}',
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

// ---------------------------------------------------------------------------
// Streak Badge
// ---------------------------------------------------------------------------

class _StreakBadge extends ConsumerWidget {
  const _StreakBadge({required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    return streakAsync.when(
      data: (weeks) {
        if (weeks <= 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.08),
              borderRadius: AppRadius.lg,
              border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.15),
                    borderRadius: AppRadius.md,
                  ),
                  child: const Icon(Icons.local_fire_department,
                      color: AppColors.green, size: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$weeks-week streak!',
                          style: AppTextStyles.headingS.copyWith(
                              color: AppColors.green)),
                      Text('Consecutive weeks under your spending target',
                          style: AppTextStyles.bodyS
                              .copyWith(color: AppColors.gray500)),
                    ],
                  ),
                ),
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

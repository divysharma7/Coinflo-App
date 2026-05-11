import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _reportMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

enum _ReportScope { week, month, year }

final _reportScopeProvider =
    StateProvider<_ReportScope>((ref) => _ReportScope.month);

final _monthCategoryTotalsProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final month = ref.watch(_reportMonthProvider);
  return repo.getCategoryTotalsForMonth(month);
});

/// Previous month category totals for delta comparison.
final _prevMonthCategoryTotalsProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final month = ref.watch(_reportMonthProvider);
  final prev = DateTime(month.year, month.month - 1);
  return repo.getCategoryTotalsForMonth(prev);
});

// ---------------------------------------------------------------------------
// Category colors
// ---------------------------------------------------------------------------

const Map<TransactionCategory, Color> _categoryColors = {
  TransactionCategory.foodAndDrink: Color(0xFFFF8A4C),
  TransactionCategory.transport: Color(0xFF4A8FE7),
  TransactionCategory.shopping: Color(0xFFB19CD9),
  TransactionCategory.billsAndUtilities: Color(0xFFF97316),
  TransactionCategory.healthAndWellness: Color(0xFF22C55E),
  TransactionCategory.entertainment: Color(0xFFE91E63),
  TransactionCategory.streaming: Color(0xFFEC407A),
  TransactionCategory.gymFitness: Color(0xFF4CAF50),
  TransactionCategory.productivityTools: Color(0xFF9575CD),
  TransactionCategory.personalCare: Color(0xFFF8BBD0),
  TransactionCategory.education: Color(0xFF5C6BC0),
  TransactionCategory.travel: Color(0xFF14B8A6),
  TransactionCategory.other: Color(0xFF6E6E6E),
};

Color _colorForCategory(TransactionCategory cat) =>
    _categoryColors[cat] ?? const Color(0xFF6E6E6E);

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
    default:
      return '\$';
  }
}

String _formatAmount(double value) {
  if (value >= 100000) {
    return NumberFormat('#,##,###', 'en_IN').format(value.toInt());
  }
  return NumberFormat('#,###').format(value.toInt());
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
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              _buildHeader(),
              const SizedBox(height: AppSpacing.lg),
              const _PeriodSelector(),
              const SizedBox(height: AppSpacing.lg),
              _buildMonthNavigator(),
              const SizedBox(height: AppSpacing.xl),
              _buildDonutSection(),
              const SizedBox(height: AppSpacing.xxl),
              _buildCategoryBreakdown(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Report',
              style: AppTextStyles.headingL.copyWith(color: AppColors.black)),
          GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: const Icon(Icons.download_outlined,
                color: AppColors.black, size: 24),
          ),
        ],
      ),
    );
  }

  // --- Month Navigator ---

  Widget _buildMonthNavigator() {
    final scope = ref.watch(_reportScopeProvider);
    final month = ref.watch(_reportMonthProvider);
    final label = DateFormat('MMMM yyyy').format(month);
    final canForward = _canNavigateForward(scope, month);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _navigatePeriod(-1, scope, month);
            },
            child: const Icon(Icons.chevron_left,
                color: AppColors.gray400, size: 28),
          ),
          Text(label,
              style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          GestureDetector(
            onTap: canForward
                ? () {
                    HapticFeedback.selectionClick();
                    _navigatePeriod(1, scope, month);
                  }
                : null,
            child: Icon(Icons.chevron_right,
                color: canForward ? AppColors.gray400 : AppColors.gray200,
                size: 28),
          ),
        ],
      ),
    );
  }

  void _navigatePeriod(int direction, _ReportScope scope, DateTime current) {
    DateTime next;
    switch (scope) {
      case _ReportScope.week:
        next = current.add(Duration(days: 7 * direction));
      case _ReportScope.month:
        next = DateTime(current.year, current.month + direction);
      case _ReportScope.year:
        next = DateTime(current.year + direction, current.month);
    }
    ref.read(_reportMonthProvider.notifier).state = next;
  }

  bool _canNavigateForward(_ReportScope scope, DateTime current) {
    final now = DateTime.now();
    switch (scope) {
      case _ReportScope.week:
        return current.add(const Duration(days: 7)).isBefore(now);
      case _ReportScope.month:
        final next = DateTime(current.year, current.month + 1);
        return next.isBefore(now) ||
            (next.month == now.month && next.year == now.year);
      case _ReportScope.year:
        return current.year < now.year;
    }
  }

  // --- Donut Chart ---

  Widget _buildDonutSection() {
    final catTotals = ref.watch(_monthCategoryTotalsProvider);
    final budgetAsync = ref.watch(monthlyBudgetProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.valueOrNull ?? 'inr';
    final symbol = _currencySymbol(currency);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: catTotals.when(
        data: (data) {
          if (data.isEmpty) {
            return SizedBox(
              height: 250,
              child: Center(
                child: Text('No expenses this month.',
                    style:
                        AppTextStyles.bodyM.copyWith(color: AppColors.gray400)),
              ),
            );
          }

          final sorted = data.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final totalSpent = sorted.fold<double>(0, (s, e) => s + e.value);
          final budgetVal = budgetAsync.valueOrNull ?? 0;
          final pct =
              budgetVal > 0 ? (totalSpent / budgetVal * 100).round() : 0;
          final left = budgetVal > 0 ? (budgetVal - totalSpent).clamp(0.0, double.infinity) : 0.0;

          // Pie sections
          final sections = <PieChartSectionData>[];
          for (int i = 0; i < sorted.length; i++) {
            final entry = sorted[i];
            final cat = TransactionCategory.values.firstWhere(
              (c) => c.name == entry.key,
              orElse: () => TransactionCategory.other,
            );
            final isTouched = _touchedIndex == i;
            sections.add(PieChartSectionData(
              value: entry.value,
              color: _colorForCategory(cat),
              radius: isTouched ? 32 : 26,
              title: '',
            ));
          }

          return Column(
            children: [
              // Donut chart
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 70,
                        sectionsSpace: 3,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              setState(() => _touchedIndex = null);
                              return;
                            }
                            setState(() => _touchedIndex =
                                response.touchedSection!.touchedSectionIndex);
                          },
                        ),
                      ),
                    ),
                    // Center text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pct%',
                          style: AppTextStyles.displayL.copyWith(
                            color: AppColors.black,
                            fontSize: 36,
                          ),
                        ),
                        Text(
                          'of budget',
                          style: AppTextStyles.bodyS
                              .copyWith(color: AppColors.gray400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Category legend dots
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                alignment: WrapAlignment.center,
                children: sorted.map((entry) {
                  final cat = TransactionCategory.values.firstWhere(
                    (c) => c.name == entry.key,
                    orElse: () => TransactionCategory.other,
                  );
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _colorForCategory(cat),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cat.label,
                        style: AppTextStyles.labelS
                            .copyWith(color: AppColors.gray500, letterSpacing: 0),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Spent / Left summary
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Spent $symbol${_formatAmount(totalSpent)}',
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.gray500),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.gray300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Left $symbol${_formatAmount(left)}',
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.gray500),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 250,
          child: Center(
              child: CircularProgressIndicator(color: AppColors.black)),
        ),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  // --- By Category Breakdown ---

  Widget _buildCategoryBreakdown() {
    final catTotals = ref.watch(_monthCategoryTotalsProvider);
    final prevTotals = ref.watch(_prevMonthCategoryTotalsProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.valueOrNull ?? 'inr';
    final symbol = _currencySymbol(currency);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('By Category',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
          const SizedBox(height: AppSpacing.lg),
          catTotals.when(
            data: (data) {
              if (data.isEmpty) {
                return Text('No spending data.',
                    style: AppTextStyles.bodyM
                        .copyWith(color: AppColors.gray400));
              }

              final sorted = data.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final totalSpent =
                  sorted.fold<double>(0, (s, e) => s + e.value);
              final prevData = prevTotals.valueOrNull ?? {};

              return Column(
                children: sorted.map((entry) {
                  final cat = TransactionCategory.values.firstWhere(
                    (c) => c.name == entry.key,
                    orElse: () => TransactionCategory.other,
                  );
                  final amount = entry.value;
                  final pct = totalSpent > 0 ? amount / totalSpent : 0.0;
                  final catColor = _colorForCategory(cat);

                  // Delta vs previous month
                  final prevAmount = prevData[entry.key] ?? 0;
                  int? delta;
                  if (prevAmount > 0) {
                    delta =
                        ((amount - prevAmount) / prevAmount * 100).round();
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Category icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(cat.iconFill,
                              size: 20, color: catColor),
                        ),
                        const SizedBox(width: AppSpacing.sm),

                        // Name + delta
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.label,
                                style: AppTextStyles.bodyM.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                              if (delta != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${delta > 0 ? '\u2191' : '\u2193'} ${delta.abs()}% vs last period',
                                  style: AppTextStyles.labelS.copyWith(
                                    color: delta > 0
                                        ? AppColors.red
                                        : AppColors.green,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Amount
                        Text(
                          '$symbol${_formatAmount(amount)}',
                          style: AppTextStyles.numericL
                              .copyWith(color: AppColors.black),
                        ),

                        const SizedBox(width: AppSpacing.sm),

                        // Percentage bar
                        SizedBox(
                          width: 40,
                          child: Column(
                            children: [
                              Text(
                                '${(pct * 100).round()}%',
                                style: AppTextStyles.labelS
                                    .copyWith(color: AppColors.gray400),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: AppColors.gray200,
                                  valueColor:
                                      AlwaysStoppedAnimation(catColor),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

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
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: _ReportScope.values.map((scope) {
            final isSelected = scope == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(_reportScopeProvider.notifier).state = scope;
                },
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Center(
                    child: Text(
                      scope.name[0].toUpperCase() + scope.name.substring(1),
                      style: AppTextStyles.bodyS.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? AppColors.white : AppColors.gray500,
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

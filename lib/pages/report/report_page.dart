import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
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

/// All transactions for the selected month.
final _monthTransactionsProvider =
    FutureProvider.autoDispose<List<SpendlerTransaction>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final month = ref.watch(_reportMonthProvider);
  return repo.getTransactionsForMonth(month);
});

/// Category totals (expenses only) for the selected month.
final _monthCategoryTotalsProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final month = ref.watch(_reportMonthProvider);
  return repo.getCategoryTotalsForMonth(month);
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Category color map using the new design system palette.
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
  TransactionCategory.other: AppColors.gray500,
};

Color _colorForCategory(TransactionCategory cat) {
  return _categoryColors[cat] ?? AppColors.gray500;
}

String _formatCompact(double value) {
  if (value >= 100000) {
    return '${(value / 100000).toStringAsFixed(1)}L';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toStringAsFixed(0);
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
  int _selectedFilterIndex = 0; // 0=Expenses, 1=Income, 2=Net

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
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
                const SizedBox(height: AppSpacing.lg),
                _buildFilterCards(),
                const SizedBox(height: AppSpacing.lg),
                _buildSearchBar(),
                const SizedBox(height: AppSpacing.lg),
                _buildDonutSection(),
                const SizedBox(height: AppSpacing.xl),
                const _TransactionList(),
                const SizedBox(height: 100),
              ],
            ),
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
          Text(
            'Report',
            style: AppTextStyles.headingL.copyWith(color: AppColors.black),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
            },
            child: const Icon(
              Icons.download_outlined,
              color: AppColors.black,
              size: 24,
            ),
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
            child: const Icon(
              Icons.chevron_left,
              color: AppColors.gray400,
              size: 28,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.headingS.copyWith(color: AppColors.black),
          ),
          GestureDetector(
            onTap: canForward
                ? () {
                    HapticFeedback.selectionClick();
                    _navigatePeriod(1, scope, month);
                  }
                : null,
            child: Icon(
              Icons.chevron_right,
              color: canForward ? AppColors.gray400 : AppColors.gray200,
              size: 28,
            ),
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

  // --- Filter Cards ---

  Widget _buildFilterCards() {
    final txnsAsync = ref.watch(_monthTransactionsProvider);

    return txnsAsync.when(
      data: (txns) {
        final income = txns
            .where((t) => t.amount > 0)
            .fold<double>(0, (s, t) => s + t.amount);
        final expenses = txns
            .where((t) => t.amount < 0)
            .fold<double>(0, (s, t) => s + t.amount.abs());
        final net = income - expenses;

        final filters = [
          _FilterData(
            label: 'Expenses',
            amount: expenses,
            icon: Icons.arrow_upward_rounded,
            iconColor: AppColors.red,
          ),
          _FilterData(
            label: 'Income',
            amount: income,
            icon: Icons.arrow_downward_rounded,
            iconColor: AppColors.green,
          ),
          _FilterData(
            label: 'Net',
            amount: net,
            icon: Icons.compare_arrows_rounded,
            iconColor: net >= 0 ? AppColors.green : AppColors.red,
          ),
        ];

        return SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = _selectedFilterIndex == index;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedFilterIndex = index);
                },
                child: _FilterCard(
                  filter: filter,
                  isSelected: isSelected,
                  isNet: index == 2,
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 110,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.black),
        ),
      ),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  // --- Search Bar ---

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.gray100,
          borderRadius: AppRadius.md,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.gray400,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Search transactions...',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
            ),
          ],
        ),
      ),
    );
  }

  // --- Donut Chart ---

  Widget _buildDonutSection() {
    final catTotals = ref.watch(_monthCategoryTotalsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppCard(
        variant: AppCardVariant.dark,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: catTotals.when(
          data: (data) {
            if (data.isEmpty) {
              return SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    'No expenses this month.',
                    style: AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
                  ),
                ),
              );
            }

            final sorted = data.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final totalSpent =
                sorted.fold<double>(0, (s, e) => s + e.value);

            // Build sections
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
                radius: isTouched ? 28 : 22,
                title: '',
                borderSide: isTouched
                    ? BorderSide(
                        color:
                            _colorForCategory(cat).withValues(alpha: 0.6),
                        width: 2,
                      )
                    : BorderSide.none,
              ));
            }

            // Center label
            String centerValue;
            String centerLabel;
            if (_touchedIndex != null && _touchedIndex! < sorted.length) {
              final entry = sorted[_touchedIndex!];
              final cat = TransactionCategory.values.firstWhere(
                (c) => c.name == entry.key,
                orElse: () => TransactionCategory.other,
              );
              final pct = (entry.value / totalSpent * 100).round();
              centerValue = '$pct%';
              centerLabel = cat.label;
            } else {
              centerValue = '\$${_formatCompact(totalSpent)}';
              centerLabel = 'Total Spent';
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final chartSize = constraints.maxWidth.clamp(200.0, 320.0);
                final centerRadius = (chartSize * 0.25).clamp(40.0, 80.0);
                return SizedBox(
                  height: chartSize * 0.7,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: centerRadius,
                          sectionsSpace: 3,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              if (!event.isInterestedForInteractions ||
                                  response == null ||
                                  response.touchedSection == null) {
                                setState(() => _touchedIndex = null);
                                return;
                              }
                              setState(() => _touchedIndex = response
                                  .touchedSection!.touchedSectionIndex);
                            },
                          ),
                        ),
                      ),
                      // Center text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            centerValue,
                            style: AppTextStyles.headingM.copyWith(
                              color: AppColors.white,
                              fontSize: _touchedIndex != null ? 22 : 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            centerLabel,
                            style: AppTextStyles.bodyS
                                .copyWith(color: AppColors.gray400),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.white),
            ),
          ),
          error: (e, st) => SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'Error loading data',
                style: AppTextStyles.bodyM.copyWith(color: AppColors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Data Model
// ---------------------------------------------------------------------------

class _FilterData {
  const _FilterData({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
}

// ---------------------------------------------------------------------------
// Filter Card
// ---------------------------------------------------------------------------

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.filter,
    required this.isSelected,
    required this.isNet,
  });

  final _FilterData filter;
  final bool isSelected;
  final bool isNet;

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? AppColors.black : AppColors.white;
    final textColor = isSelected ? AppColors.white : AppColors.black;
    final labelColor = isSelected ? AppColors.gray300 : AppColors.gray500;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: filter.iconColor.withValues(alpha: 0.15),
              borderRadius: AppRadius.full,
            ),
            child: Center(
              child: Icon(filter.icon, size: 14, color: filter.iconColor),
            ),
          ),
          const Spacer(),
          Text(
            filter.label,
            style: AppTextStyles.bodyS.copyWith(color: labelColor),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '\$${_formatCompact(filter.amount.abs())}',
            style: AppTextStyles.headingM.copyWith(
              color: isNet && filter.amount >= 0 && !isSelected
                  ? AppColors.green
                  : textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Period Selector (Week / Month / Year pills)
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
        decoration: const BoxDecoration(
          color: AppColors.gray100,
          borderRadius: AppRadius.full,
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
                    borderRadius: AppRadius.full,
                  ),
                  child: Center(
                    child: Text(
                      scope.name[0].toUpperCase() + scope.name.substring(1),
                      style: AppTextStyles.bodyS.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.gray500,
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
// Transaction List (full month)
// ---------------------------------------------------------------------------

class _TransactionList extends ConsumerWidget {
  const _TransactionList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(_monthTransactionsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          txnsAsync.when(
            data: (txns) {
              if (txns.isEmpty) {
                return _buildEmptyState();
              }

              // Group by date
              final grouped = <String, List<SpendlerTransaction>>{};
              for (final t in txns) {
                final key = DateFormat('d MMM, EEEE').format(t.happenedAt);
                grouped.putIfAbsent(key, () => []).add(t);
              }

              return Column(
                children: grouped.entries.map((dayGroup) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day header
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.md,
                          bottom: AppSpacing.xs,
                        ),
                        child: Text(
                          dayGroup.key.toUpperCase(),
                          style: AppTextStyles.labelM
                              .copyWith(color: AppColors.gray400),
                        ),
                      ),
                      // Transactions
                      ...dayGroup.value.asMap().entries.map((mapEntry) {
                        final index = mapEntry.key;
                        final t = mapEntry.value;
                        final cat = TransactionCategory.values.firstWhere(
                          (c) => c.name == t.category,
                          orElse: () => TransactionCategory.other,
                        );
                        final catColor = _colorForCategory(cat);
                        final isExpense = t.amount < 0;
                        final isLast = index == dayGroup.value.length - 1;

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm),
                              child: Row(
                                children: [
                                  // Category icon circle
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          catColor.withValues(alpha: 0.12),
                                      borderRadius: AppRadius.full,
                                    ),
                                    child: Center(
                                      child: Icon(cat.iconFill,
                                          size: 18, color: catColor),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  // Title
                                  Expanded(
                                    child: Text(
                                      t.merchant ?? cat.label,
                                      style: AppTextStyles.bodyM.copyWith(
                                        color: AppColors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Amount
                                  Text(
                                    '${isExpense ? '-' : '+'}\$${t.amount.abs().toStringAsFixed(0)}',
                                    style: AppTextStyles.numericM.copyWith(
                                      color: isExpense
                                          ? AppColors.black
                                          : AppColors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              const Divider(
                                height: 1,
                                thickness: 0.5,
                                color: AppColors.gray200,
                              ),
                          ],
                        );
                      }),
                    ],
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.black),
              ),
            ),
            error: (e, st) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: AppCard(
        variant: AppCardVariant.light,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '\u{1F4CA}',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No data for this month',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "No data here. We really wish you'd found us sooner \u2014 this could've been a great month of insights! \u{1F49B}",
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

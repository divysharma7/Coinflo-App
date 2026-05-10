import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/data/db.dart';
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

Color _colorForCategory(TransactionCategory cat) {
  return SpendlerColors.categoryColor(cat);
}

String _formatCompact(double value) {
  if (value >= 100000) {
    return '${(value / 100000).toStringAsFixed(1)}L';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toStringAsFixed(0);
}

String _periodLabel(DateTime month, _ReportScope scope) {
  switch (scope) {
    case _ReportScope.week:
      final weekStart = month.subtract(Duration(days: month.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      return '${DateFormat('d MMM').format(weekStart)} - ${DateFormat('d MMM').format(weekEnd)}';
    case _ReportScope.month:
      return DateFormat('MMMM yyyy').format(month);
    case _ReportScope.year:
      return month.year.toString();
  }
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
    final month = ref.watch(_reportMonthProvider);
    final txnsAsync = ref.watch(_monthTransactionsProvider);

    return Scaffold(
      backgroundColor: SpendlerColors.scaffold,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Report',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: SpendlerColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: PhosphorIcon(
                        PhosphorIcons.downloadSimple(),
                        color: SpendlerColors.textPrimary,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Export coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Period Selector (Week / Month / Year)
              const _PeriodSelector(),
              const SizedBox(height: SpendlerSpacing.lg),

              // Period Navigation (< May 2026 >)
              _buildPeriodNavigator(scope, month),
              const SizedBox(height: SpendlerSpacing.xl),

              // Summary cards (Expenses / Income / Net)
              _buildSummaryCards(txnsAsync),
              const SizedBox(height: SpendlerSpacing.xl),

              // Content: donut chart + categories or empty state
              _buildContent(scope, month),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Period Navigator ──────────────────────────────────

  Widget _buildPeriodNavigator(_ReportScope scope, DateTime month) {
    final label = _periodLabel(month, scope);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _navigatePeriod(-1, scope, month);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SpendlerColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.chevron_left,
                    color: SpendlerColors.textTertiary, size: 22),
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: SpendlerColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () {
              if (_canNavigateForward(scope, month)) {
                HapticFeedback.selectionClick();
                _navigatePeriod(1, scope, month);
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SpendlerColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.chevron_right,
                  color: _canNavigateForward(scope, month)
                      ? SpendlerColors.textTertiary
                      : SpendlerColors.textTertiary.withValues(alpha: 0.3),
                  size: 22,
                ),
              ),
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

  // ─── Summary Cards ─────────────────────────────────────

  Widget _buildSummaryCards(AsyncValue<List<SpendlerTransaction>> txnsAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH),
      child: txnsAsync.when(
        data: (txns) {
          final income = txns
              .where((t) => t.amount > 0)
              .fold<double>(0, (s, t) => s + t.amount);
          final expenses = txns
              .where((t) => t.amount < 0)
              .fold<double>(0, (s, t) => s + t.amount.abs());
          final net = income - expenses;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterCard(
                  label: 'Expenses',
                  amount: expenses,
                  icon: PhosphorIcons.arrowDown(),
                  iconColor: SpendlerColors.expense,
                  isSelected: true,
                ),
                const SizedBox(width: SpendlerSpacing.sm),
                _FilterCard(
                  label: 'Income',
                  amount: income,
                  icon: PhosphorIcons.arrowUp(),
                  iconColor: SpendlerColors.income,
                  isSelected: false,
                ),
                const SizedBox(width: SpendlerSpacing.sm),
                _FilterCard(
                  label: 'Net',
                  amount: net,
                  icon: PhosphorIcons.waveSine(),
                  iconColor: net >= 0 ? SpendlerColors.income : SpendlerColors.expense,
                  isSelected: false,
                  amountColor: net >= 0 ? SpendlerColors.income : SpendlerColors.expense,
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox(
          height: 80,
          child: Center(
            child: CircularProgressIndicator(color: SpendlerColors.primary),
          ),
        ),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  // ─── Content Area ──────────────────────────────────────

  Widget _buildContent(_ReportScope scope, DateTime month) {
    final catTotals = ref.watch(_monthCategoryTotalsProvider);
    final txnsAsync = ref.watch(_monthTransactionsProvider);

    return catTotals.when(
      data: (data) {
        if (data.isEmpty) {
          return _buildEmptyState(scope, month);
        }

        return Column(
          children: [
            _buildDonutSection(data),
            const SizedBox(height: SpendlerSpacing.xl),
            const _TopCategoriesList(),
            const SizedBox(height: SpendlerSpacing.xl),
            // Transaction count
            txnsAsync.when(
              data: (txns) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: SpendlerSpacing.screenH + 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${txns.length} transactions',
                    style: const TextStyle(
                      color: SpendlerColors.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: SpendlerSpacing.md),
            const _TransactionList(),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: SpendlerColors.primary),
        ),
      ),
      error: (_, _) => const SizedBox(
        height: 300,
        child: Center(
          child: Text('Error loading data',
              style: TextStyle(color: SpendlerColors.expense)),
        ),
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────

  Widget _buildEmptyState(_ReportScope scope, DateTime month) {
    final String emoji;
    final String title;
    final String subtitle;

    switch (scope) {
      case _ReportScope.year:
        emoji = '\u{1F4CA}'; // chart emoji
        title = 'No data for ${month.year}';
        subtitle = 'Your numbers are on vacation.\nStart spending (or earning) to see insights.';
      case _ReportScope.month:
        emoji = '\u{1F575}\u{FE0F}'; // detective emoji
        title = 'No data for this month';
        subtitle = 'Nothing to report yet.\nTransactions will show up here once added.';
      case _ReportScope.week:
        emoji = '\u{1F575}\u{FE0F}';
        title = 'No data for this week';
        subtitle = 'A clean slate!\nAdd some transactions to get started.';
    }

    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: SpendlerSpacing.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: SpendlerColors.textPrimary,
              ),
            ),
            const SizedBox(height: SpendlerSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: SpendlerColors.textTertiary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Donut Chart ───────────────────────────────────────

  Widget _buildDonutSection(Map<String, double> data) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalSpent = sorted.fold<double>(0, (s, e) => s + e.value);

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
                color: _colorForCategory(cat).withValues(alpha: 0.6),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH),
      child: Container(
        padding: const EdgeInsets.all(SpendlerSpacing.cardPadding),
        decoration: BoxDecoration(
          color: SpendlerColors.surface,
          borderRadius: BorderRadius.circular(SpendlerRadii.card),
          boxShadow: SpendlerShadows.card,
        ),
        child: SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 64,
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
                    centerValue,
                    style: TextStyle(
                      fontSize: _touchedIndex != null ? 22 : 20,
                      fontWeight: FontWeight.w700,
                      color: SpendlerColors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    centerLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SpendlerColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Card
// ---------------------------------------------------------------------------

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    this.amountColor,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(SpendlerSpacing.cardGap),
      decoration: BoxDecoration(
        color: isSelected ? SpendlerColors.textPrimary : SpendlerColors.surface,
        borderRadius: BorderRadius.circular(SpendlerRadii.button),
        border: isSelected ? null : Border.all(color: SpendlerColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14,
                  color: isSelected ? Colors.white70 : iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white70 : SpendlerColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          Text(
            '\$${_formatCompact(amount.abs())}',
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (amountColor ?? SpendlerColors.textPrimary),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
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
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: SpendlerColors.surface,
          borderRadius: BorderRadius.circular(SpendlerRadii.pill),
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
                  duration: SpendlerMotion.micro,
                  curve: SpendlerMotion.surfaceCurve,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? SpendlerColors.textPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(SpendlerRadii.pill),
                  ),
                  child: Center(
                    child: Text(
                      scope.name[0].toUpperCase() + scope.name.substring(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? SpendlerColors.scaffold
                            : SpendlerColors.textTertiary,
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
// Top Categories List
// ---------------------------------------------------------------------------

class _TopCategoriesList extends ConsumerWidget {
  const _TopCategoriesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catTotals = ref.watch(_monthCategoryTotalsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOP CATEGORIES', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.md),
          catTotals.when(
            data: (data) {
              if (data.isEmpty) {
                return const Text(
                  'No data for this month.',
                  style: SpendlerTextStyles.emptyState,
                );
              }

              final sorted = data.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final totalSpent =
                  sorted.fold<double>(0, (s, e) => s + e.value);

              return Column(
                children: sorted.map((entry) {
                  final cat = TransactionCategory.values.firstWhere(
                    (c) => c.name == entry.key,
                    orElse: () => TransactionCategory.other,
                  );
                  final pct = totalSpent > 0
                      ? (entry.value / totalSpent * 100).round()
                      : 0;
                  final catColor = _colorForCategory(cat);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: SpendlerSpacing.cardGap),
                    child: Row(
                      children: [
                        // Tinted icon square
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              cat.iconFill,
                              size: 18,
                              color: catColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: SpendlerSpacing.cardGap),
                        // Name
                        Expanded(
                          child: Text(
                            cat.label,
                            style: const TextStyle(
                              color: SpendlerColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Amount + percentage
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${entry.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: SpendlerColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: TextStyle(
                                color: catColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(color: SpendlerColors.primary),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary Cards (Income / Expenses / Net)
// ---------------------------------------------------------------------------

class _SummaryCards extends ConsumerWidget {
  const _SummaryCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(_monthTransactionsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH),
      child: txnsAsync.when(
        data: (txns) {
          final income = txns
              .where((t) => t.amount > 0)
              .fold<double>(0, (s, t) => s + t.amount);
          final expenses = txns
              .where((t) => t.amount < 0)
              .fold<double>(0, (s, t) => s + t.amount.abs());
          final net = income - expenses;

          return Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Income',
                  amount: income,
                  color: SpendlerColors.income,
                  icon: PhosphorIcons.arrowDown(),
                ),
              ),
              const SizedBox(width: SpendlerSpacing.sm),
              Expanded(
                child: _SummaryCard(
                  label: 'Expenses',
                  amount: expenses,
                  color: SpendlerColors.expense,
                  icon: PhosphorIcons.arrowUp(),
                ),
              ),
              const SizedBox(width: SpendlerSpacing.sm),
              Expanded(
                child: _SummaryCard(
                  label: 'Net',
                  amount: net,
                  color: net >= 0 ? SpendlerColors.income : SpendlerColors.expense,
                  icon: PhosphorIcons.equals(),
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(color: SpendlerColors.primary),
          ),
        ),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpendlerSpacing.cardGap),
      decoration: BoxDecoration(
        color: SpendlerColors.surface,
        borderRadius: BorderRadius.circular(SpendlerRadii.card),
        border: Border.all(color: SpendlerColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          Text(
            '\$${_formatCompact(amount.abs())}',
            style: const TextStyle(
              color: SpendlerColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ALL TRANSACTIONS', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.md),
          txnsAsync.when(
            data: (txns) {
              if (txns.isEmpty) {
                return const Text(
                  'No transactions this month.',
                  style: SpendlerTextStyles.emptyState,
                );
              }

              // Group by date
              final grouped = <String, List<SpendlerTransaction>>{};
              for (final t in txns) {
                final key = DateFormat('d MMM, EEEE').format(t.happenedAt);
                grouped.putIfAbsent(key, () => []).add(t);
              }

              return Column(
                children: grouped.entries.map((dayGroup) {
                  final dayTotal = dayGroup.value
                      .where((t) => t.amount < 0)
                      .fold<double>(0, (s, t) => s + t.amount.abs());

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day header
                      Padding(
                        padding: const EdgeInsets.only(
                          top: SpendlerSpacing.md,
                          bottom: SpendlerSpacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                dayGroup.key,
                                style: const TextStyle(
                                  color: SpendlerColors.textTertiary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (dayTotal > 0)
                              Text(
                                '\$${dayTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: SpendlerColors.textTertiary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Transactions
                      ...dayGroup.value.map((t) {
                        final cat = TransactionCategory.values.firstWhere(
                          (c) => c.name == t.category,
                          orElse: () => TransactionCategory.other,
                        );
                        final catColor = _colorForCategory(cat);
                        final isExpense = t.amount < 0;

                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: SpendlerSpacing.sm),
                          child: Row(
                            children: [
                              // Category icon
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(cat.icon, size: 16,
                                      color: catColor),
                                ),
                              ),
                              const SizedBox(width: SpendlerSpacing.cardGap),
                              // Name + time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.merchant ?? cat.label,
                                      style: const TextStyle(
                                        color: SpendlerColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      DateFormat('h:mm a')
                                          .format(t.happenedAt),
                                      style: const TextStyle(
                                        color: SpendlerColors.textTertiary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Amount
                              Text(
                                '${isExpense ? '-' : '+'}\$${t.amount.abs().toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: isExpense
                                      ? SpendlerColors.textPrimary
                                      : SpendlerColors.income,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                child: CircularProgressIndicator(color: SpendlerColors.primary),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

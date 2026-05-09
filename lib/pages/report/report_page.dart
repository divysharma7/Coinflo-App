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
    FutureProvider.autoDispose<List<PaisaTransaction>>((ref) {
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
// Donut chart colour palette (muted, dark-friendly)
// ---------------------------------------------------------------------------

Color _colorForCategory(TransactionCategory cat) {
  return PaisaColors.categoryColor(cat);
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
      backgroundColor: PaisaColors.scaffold,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + PaisaSpacing.lg),
            _buildHeader(),
            const SizedBox(height: PaisaSpacing.lg),
            const _PeriodSelector(),
            const SizedBox(height: PaisaSpacing.lg),
            _buildMonthNavigator(),
            const SizedBox(height: PaisaSpacing.xl),
            _buildDonutSection(),
            const SizedBox(height: PaisaSpacing.xl),
            const _TopCategoriesList(),
            const SizedBox(height: PaisaSpacing.xl),
            const _SummaryCards(),
            const SizedBox(height: PaisaSpacing.xl),
            const _TransactionList(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PaisaSpacing.screenH + 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: PaisaColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: PaisaSpacing.cardGap),
          const Text(
            'Monthly Report',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: PaisaColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Month Navigator ──────────────────────────────────

  Widget _buildMonthNavigator() {
    final month = ref.watch(_reportMonthProvider);
    final label = DateFormat('MMMM yyyy').format(month);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PaisaSpacing.screenH + 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(_reportMonthProvider.notifier).state =
                  DateTime(month.year, month.month - 1);
            },
            child: const Icon(Icons.chevron_left,
                color: PaisaColors.textTertiary, size: 24),
          ),
          Text(
            label,
            style: const TextStyle(
              color: PaisaColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () {
              final next = DateTime(month.year, month.month + 1);
              if (next.isBefore(DateTime.now()) ||
                  next.month == DateTime.now().month &&
                      next.year == DateTime.now().year) {
                HapticFeedback.selectionClick();
                ref.read(_reportMonthProvider.notifier).state = next;
              }
            },
            child: Icon(
              Icons.chevron_right,
              color: DateTime(month.year, month.month + 1)
                      .isAfter(DateTime.now())
                  ? PaisaColors.textTertiary.withValues(alpha: 0.3)
                  : PaisaColors.textTertiary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Donut Chart ──────────────────────────────────────

  Widget _buildDonutSection() {
    final catTotals = ref.watch(_monthCategoryTotalsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PaisaSpacing.screenH),
      child: Container(
        padding: const EdgeInsets.all(PaisaSpacing.cardPadding),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E1E), PaisaColors.surface],
          ),
          borderRadius: BorderRadius.circular(PaisaRadii.card),
          boxShadow: PaisaShadows.card,
        ),
        child: catTotals.when(
          data: (data) {
            if (data.isEmpty) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    'No expenses this month.',
                    style: PaisaTextStyles.emptyState,
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
                        color: _colorForCategory(cat).withValues(alpha: 0.6),
                        width: 2,
                      )
                    : BorderSide.none,
              ));
            }

            // Center label
            String centerValue;
            String centerLabel;
            if (_touchedIndex != null &&
                _touchedIndex! < sorted.length) {
              final entry = sorted[_touchedIndex!];
              final cat = TransactionCategory.values.firstWhere(
                (c) => c.name == entry.key,
                orElse: () => TransactionCategory.other,
              );
              final pct = (entry.value / totalSpent * 100).round();
              centerValue = '$pct%';
              centerLabel = cat.label;
            } else {
              centerValue = '₹${_formatCompact(totalSpent)}';
              centerLabel = 'Total Spent';
            }

            return SizedBox(
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
                          color: PaisaColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        centerLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: PaisaColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(color: PaisaColors.yellow),
            ),
          ),
          error: (_, _) => const SizedBox(
            height: 220,
            child: Center(
              child: Text('Error loading data',
                  style: TextStyle(color: PaisaColors.expense)),
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: PaisaSpacing.screenH),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: PaisaColors.surface,
          borderRadius: BorderRadius.circular(PaisaRadii.pill),
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
                  duration: PaisaMotion.micro,
                  curve: PaisaMotion.surfaceCurve,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? PaisaColors.textPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(PaisaRadii.pill),
                  ),
                  child: Center(
                    child: Text(
                      scope.name[0].toUpperCase() + scope.name.substring(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? PaisaColors.scaffold
                            : PaisaColors.textTertiary,
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
      padding: const EdgeInsets.symmetric(horizontal: PaisaSpacing.screenH + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOP CATEGORIES', style: PaisaTextStyles.sectionLabel),
          const SizedBox(height: PaisaSpacing.md),
          catTotals.when(
            data: (data) {
              if (data.isEmpty) {
                return const Text(
                  'No data for this month.',
                  style: PaisaTextStyles.emptyState,
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
                    padding: const EdgeInsets.only(bottom: PaisaSpacing.cardGap),
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
                        const SizedBox(width: PaisaSpacing.cardGap),
                        // Name
                        Expanded(
                          child: Text(
                            cat.label,
                            style: const TextStyle(
                              color: PaisaColors.textPrimary,
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
                              '₹${entry.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: PaisaColors.textPrimary,
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
                child: CircularProgressIndicator(color: PaisaColors.yellow),
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
      padding: const EdgeInsets.symmetric(horizontal: PaisaSpacing.screenH),
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
                  color: PaisaColors.income,
                  icon: PhosphorIcons.arrowDown(),
                ),
              ),
              const SizedBox(width: PaisaSpacing.sm),
              Expanded(
                child: _SummaryCard(
                  label: 'Expenses',
                  amount: expenses,
                  color: PaisaColors.expense,
                  icon: PhosphorIcons.arrowUp(),
                ),
              ),
              const SizedBox(width: PaisaSpacing.sm),
              Expanded(
                child: _SummaryCard(
                  label: 'Net',
                  amount: net,
                  color: net >= 0 ? PaisaColors.income : PaisaColors.expense,
                  icon: PhosphorIcons.equals(),
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(color: PaisaColors.yellow),
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
      padding: const EdgeInsets.all(PaisaSpacing.cardGap),
      decoration: BoxDecoration(
        color: PaisaColors.surface,
        borderRadius: BorderRadius.circular(PaisaRadii.card),
        border: Border.all(color: PaisaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: PaisaSpacing.sm),
          Text(
            '₹${_formatCompact(amount.abs())}',
            style: const TextStyle(
              color: PaisaColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: PaisaSpacing.screenH + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ALL TRANSACTIONS', style: PaisaTextStyles.sectionLabel),
          const SizedBox(height: PaisaSpacing.md),
          txnsAsync.when(
            data: (txns) {
              if (txns.isEmpty) {
                return const Text(
                  'No transactions this month.',
                  style: PaisaTextStyles.emptyState,
                );
              }

              // Group by date
              final grouped = <String, List<PaisaTransaction>>{};
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
                          top: PaisaSpacing.md,
                          bottom: PaisaSpacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dayGroup.key,
                              style: const TextStyle(
                                color: PaisaColors.textTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (dayTotal > 0)
                              Text(
                                '₹${dayTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: PaisaColors.textTertiary,
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
                              bottom: PaisaSpacing.sm),
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
                              const SizedBox(width: PaisaSpacing.cardGap),
                              // Name + time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.merchant ?? cat.label,
                                      style: const TextStyle(
                                        color: PaisaColors.textPrimary,
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
                                        color: PaisaColors.textTertiary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Amount
                              Text(
                                '${isExpense ? '-' : '+'}₹${t.amount.abs().toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: isExpense
                                      ? PaisaColors.textPrimary
                                      : PaisaColors.income,
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
                child: CircularProgressIndicator(color: PaisaColors.yellow),
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
// Helpers
// ---------------------------------------------------------------------------

String _formatCompact(double value) {
  if (value >= 100000) {
    return '${(value / 100000).toStringAsFixed(1)}L';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toStringAsFixed(0);
}

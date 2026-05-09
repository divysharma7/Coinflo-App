import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/charts/spending_velocity_chart.dart';
import 'package:finance_buddy_app/widgets/charts/day_of_week_chart.dart';
import 'package:finance_buddy_app/widgets/common/neo_pop_button.dart';
import 'package:finance_buddy_app/widgets/posters/weekly_summary_poster.dart';
import 'package:finance_buddy_app/services/poster/poster_service.dart';
import 'package:finance_buddy_app/services/poster/poster_share.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeadlineInsightSection(),
          SizedBox(height: SpendlerSpacing.xl),
          _VelocitySection(),
          SizedBox(height: SpendlerSpacing.xl),
          _MonthlyComparisonSection(),
          SizedBox(height: SpendlerSpacing.xl),
          _DayOfWeekSection(),
          SizedBox(height: SpendlerSpacing.xl),
          _TopMerchantsSection(),
          SizedBox(height: SpendlerSpacing.xl),
          _ShareSection(),
          SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ─── Section 1: Headline Insight ─────────────────────

class _HeadlineInsightSection extends ConsumerWidget {
  const _HeadlineInsightSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thisMonth = ref.watch(thisMonthCumulativeProvider);
    final lastMonth = ref.watch(lastMonthCumulativeProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SpendlerSpacing.screenH + 4,
        MediaQuery.paddingOf(context).top + SpendlerSpacing.lg,
        SpendlerSpacing.screenH + 4,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PATTERNS', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.lg),
          thisMonth.when(
            data: (thisData) {
              if (thisData.isEmpty) {
                return const Text(
                  'Month just started.\nYour rhythm will build here.',
                  style: SpendlerTextStyles.insightBody,
                );
              }

              final today = DateTime.now().day;
              final spentSoFar = thisData[today - 1];
              final daysLeft = thisData.length - today;
              final monthName = DateFormat('MMMM').format(DateTime.now());

              // Project month-end
              final dailyRate = today > 0 ? spentSoFar / today : 0.0;
              final projected = spentSoFar + (dailyRate * daysLeft);

              final lastData = lastMonth.valueOrNull ?? [];
              final lastTotal = lastData.isNotEmpty ? lastData.last : 0.0;

              String headline;
              if (lastTotal > 0 && projected > 0) {
                final pctVsLast =
                    ((projected - lastTotal) / lastTotal * 100).round();
                if (pctVsLast > 5) {
                  headline =
                      '\$${spentSoFar.toStringAsFixed(0)} spent in $monthName so far.\n'
                      'At this pace, you\'ll hit \$\${projected.toStringAsFixed(0)} — '
                      '$pctVsLast% more than last month.';
                } else if (pctVsLast < -5) {
                  headline =
                      '\$${spentSoFar.toStringAsFixed(0)} in $monthName so far.\n'
                      'Running ${pctVsLast.abs()}% lighter than last month.';
                } else {
                  headline =
                      '\$${spentSoFar.toStringAsFixed(0)} in $monthName so far.\n'
                      'Same rhythm as last month.';
                }
              } else {
                headline =
                    '\$${spentSoFar.toStringAsFixed(0)} in $monthName so far.\n'
                    '$daysLeft days left this month.';
              }

              return Text(headline, style: SpendlerTextStyles.insightBody);
            },
            loading: () => const Text('...', style: TextStyle(color: SpendlerColors.textTertiary)),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Section 2: Spending Velocity Race ───────────────

class _VelocitySection extends ConsumerWidget {
  const _VelocitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thisMonth = ref.watch(thisMonthCumulativeProvider);
    final lastMonth = ref.watch(lastMonthCumulativeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text('SPENDING PACE', style: SpendlerTextStyles.sectionLabel),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: SpendlerSpacing.md),
            child: Text(
              'This month vs last month',
              style: TextStyle(color: SpendlerColors.textTertiary, fontSize: 12),
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: SpendlerSpacing.sm),
            child: Row(
              children: [
                Container(width: 16, height: 3, color: SpendlerColors.yellow),
                const SizedBox(width: 6),
                const Text('This month',
                    style: TextStyle(color: SpendlerColors.textSecondary, fontSize: 11)),
                const SizedBox(width: 16),
                Container(
                  width: 16,
                  height: 1,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: SpendlerColors.textTertiary, width: 1),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Last month',
                    style: TextStyle(color: SpendlerColors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(SpendlerSpacing.cardPadding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E1E), SpendlerColors.surface],
              ),
              borderRadius: BorderRadius.circular(SpendlerRadii.card),
              boxShadow: SpendlerShadows.card,
            ),
            child: thisMonth.when(
              data: (thisData) {
                final lastData = lastMonth.valueOrNull ?? [];
                return SpendingVelocityChart(
                  thisMonth: thisData,
                  lastMonth: lastData,
                );
              },
              loading: () => const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator(color: SpendlerColors.yellow))),
              error: (_, _) => const SizedBox(
                  height: 220,
                  child: Center(child: Text('Error', style: TextStyle(color: SpendlerColors.expense)))),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section 3: Monthly Category Comparison ──────────

class _MonthlyComparisonSection extends ConsumerWidget {
  const _MonthlyComparisonSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparison = ref.watch(monthlyComparisonProvider);
    final now = DateTime.now();
    final thisMonthName = DateFormat('MMM').format(now);
    final lastMonthName =
        DateFormat('MMM').format(DateTime(now.year, now.month - 1));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('THIS MONTH VS LAST', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.md),
          comparison.when(
            data: (data) {
              if (data.isEmpty) {
                return const Text(
                  'Two months of data needed for comparison.',
                  style: SpendlerTextStyles.emptyState,
                );
              }

              // Sort by this month amount descending
              final sorted = data.entries.toList()
                ..sort((a, b) => b.value[0].compareTo(a.value[0]));

              return Column(
                children: sorted.map((entry) {
                  final cat = TransactionCategory.values.firstWhere(
                    (c) => c.name == entry.key,
                    orElse: () => TransactionCategory.foodAndDrink,
                  );
                  final thisAmt = entry.value[0];
                  final lastAmt = entry.value[1];
                  final catColor = SpendlerColors.categoryColor(cat);

                  // Compute change
                  String changeText = '';
                  Color changeColor = SpendlerColors.textTertiary;
                  if (lastAmt > 0) {
                    final pct = ((thisAmt - lastAmt) / lastAmt * 100).round();
                    if (pct > 0) {
                      changeText = '↑$pct%';
                      changeColor = SpendlerColors.expense;
                    } else if (pct < 0) {
                      changeText = '↓${pct.abs()}%';
                      changeColor = SpendlerColors.income;
                    } else {
                      changeText = '—';
                    }
                  } else if (thisAmt > 0) {
                    changeText = 'NEW';
                    changeColor = SpendlerColors.amber;
                  }

                  final maxAmt =
                      thisAmt > lastAmt ? thisAmt : (lastAmt > 0 ? lastAmt : 1);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: SpendlerSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(cat.icon, size: 16, color: catColor),
                            const SizedBox(width: 8),
                            Text(cat.label,
                                style: const TextStyle(
                                    color: SpendlerColors.textSecondary, fontSize: 13)),
                            const Spacer(),
                            Text(changeText,
                                style: TextStyle(
                                    color: changeColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // This month bar
                        Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(thisMonthName,
                                  style: const TextStyle(
                                      color: SpendlerColors.textTertiary, fontSize: 10)),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: maxAmt > 0 ? thisAmt / maxAmt : 0,
                                  backgroundColor: SpendlerColors.border,
                                  valueColor: AlwaysStoppedAnimation(catColor),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 56,
                              child: Text(
                                '\$${thisAmt.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: SpendlerColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // Last month bar
                        Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(lastMonthName,
                                  style: const TextStyle(
                                      color: SpendlerColors.textTertiary, fontSize: 10)),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: maxAmt > 0 ? lastAmt / maxAmt : 0,
                                  backgroundColor: SpendlerColors.border,
                                  valueColor: AlwaysStoppedAnimation(
                                      catColor.withValues(alpha: 0.3)),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 56,
                              child: Text(
                                '\$${lastAmt.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: SpendlerColors.textTertiary,
                                    fontSize: 12),
                                textAlign: TextAlign.right,
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
                child: Center(child: CircularProgressIndicator(color: SpendlerColors.yellow))),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Section 4: Day-of-Week Pattern ──────────────────

class _DayOfWeekSection extends ConsumerWidget {
  const _DayOfWeekSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final averages = ref.watch(dayOfWeekAveragesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text('YOUR SPENDING DAYS', style: SpendlerTextStyles.sectionLabel),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: SpendlerSpacing.cardGap),
            child: Text(
              'Average per day of week (last 4 weeks)',
              style: TextStyle(color: SpendlerColors.textTertiary, fontSize: 12),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(SpendlerSpacing.cardPadding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E1E), SpendlerColors.surface],
              ),
              borderRadius: BorderRadius.circular(SpendlerRadii.card),
              boxShadow: SpendlerShadows.card,
            ),
            child: averages.when(
              data: (data) {
                // Insight text below chart
                final maxIndex = data.indexOf(data.reduce((a, b) => a > b ? a : b));
                const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                final maxDay = dayNames[maxIndex];
                final maxAmount = data[maxIndex];

                return Column(
                  children: [
                    DayOfWeekChart(averages: data),
                    if (maxAmount > 0) ...[
                      const SizedBox(height: SpendlerSpacing.md),
                      Text(
                        '$maxDay is your heaviest day — avg \$\${maxAmount.toStringAsFixed(0)}/week.',
                        style: const TextStyle(
                          color: SpendlerColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator(color: SpendlerColors.yellow))),
              error: (_, _) => const SizedBox(
                  height: 180,
                  child: Center(child: Text('Error', style: TextStyle(color: SpendlerColors.expense)))),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section 5: Top Merchants ────────────────────────

class _TopMerchantsSection extends ConsumerWidget {
  const _TopMerchantsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchants = ref.watch(topMerchantsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WHO GETS YOUR MONEY', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: 4),
          const Text(
            'This month, by frequency',
            style: TextStyle(color: SpendlerColors.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: SpendlerSpacing.md),
          merchants.when(
            data: (list) {
              if (list.isEmpty) {
                return const Text(
                  'No data yet this month.',
                  style: SpendlerTextStyles.emptyState,
                );
              }

              return Column(
                children: list.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  final isDominant = i == 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: SpendlerSpacing.cardGap),
                    child: Row(
                      children: [
                        // Rank
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: isDominant
                                  ? SpendlerColors.yellow
                                  : SpendlerColors.textTertiary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: SpendlerSpacing.sm),
                        // Name + count
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                style: TextStyle(
                                  color: isDominant
                                      ? SpendlerColors.textPrimary
                                      : SpendlerColors.textSecondary,
                                  fontSize: 15,
                                  fontWeight: isDominant
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              Text(
                                '${m.count} time${m.count > 1 ? 's' : ''} this month',
                                style: const TextStyle(
                                  color: SpendlerColors.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Total
                        Text(
                          '\$${m.total.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: isDominant
                                ? SpendlerColors.textPrimary
                                : SpendlerColors.textTertiary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator(color: SpendlerColors.yellow))),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Section 6: Share CTA ────────────────────────────

class _ShareSection extends ConsumerWidget {
  const _ShareSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH),
      child: NeoPOPButton(
        label: 'Share This Week',
        onTap: () => _share(context, ref, weekStart),
      ),
    );
  }

  Future<void> _share(
      BuildContext context, WidgetRef ref, DateTime weekStart) async {
    await HapticFeedback.mediumImpact();

    final repo = ref.read(repositoryProvider);
    final totalSpent = await repo.getTotalSpentForWeek(weekStart);
    final catTotals = await repo.getCategoryTotalsForMonth(
      DateTime(weekStart.year, weekStart.month),
    );

    if (!context.mounted) return;

    final poster = WeeklySummaryPoster(
      weekStart: weekStart,
      totalSpent: totalSpent,
      categoryTotals: catTotals,
      dailyTotals: const [],
    );

    final bytes = await PosterService.renderToPng(context, poster);
    if (bytes != null) {
      await PosterShare.share(bytes);
    }
  }
}

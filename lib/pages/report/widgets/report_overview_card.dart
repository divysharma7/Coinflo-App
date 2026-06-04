import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';

import 'package:finance_buddy_app/pages/report/widgets/report_helpers.dart';
import 'package:finance_buddy_app/pages/report/widgets/report_scope.dart';

// ─── Donut + ranked legend card ─────────────────────────
//
// Mirrors the "02 · REPORT" frame: CategoryDonut (148/22) with a SPENT
// center, a ranked legend of the top categories, divider, and an overflow
// row for the remaining spend — all from the real per-category totals.

const int _kLegendVisible = 5;

class CategoryDonutCard extends ConsumerWidget {
  const CategoryDonutCard({super.key, required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catTotals = ref.watch(monthCategoryTotalsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: catTotals.when(
        data: (data) {
          if (data.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: reportCardDecor(),
              child: Center(
                child: Text('No spending this period — nice!',
                    style:
                        AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
              ),
            );
          }

          final sorted = data.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final total = sorted.fold<double>(0, (s, e) => s + e.value);

          final segments = sorted
              .map((e) => DonutSegment(
                    value: e.value,
                    color: AppColors.categoryColor(_catFor(e.key)),
                  ))
              .toList();

          final visible = sorted.take(_kLegendVisible).toList();
          final overflow = sorted.skip(_kLegendVisible).toList();

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.xl,
              boxShadow: AppShadows.md,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CategoryDonut(
                      segments: segments,
                      size: 148,
                      strokeWidth: 22,
                      center: _DonutCenter(
                        symbol: symbol,
                        total: total,
                        count: sorted.length,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final e in visible)
                            _LegendRow(
                              color: AppColors.categoryColor(_catFor(e.key)),
                              name: _catFor(e.key).label,
                              amount: '$symbol${reportFmt(e.value)}',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (overflow.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const Divider(height: 1, color: AppColors.gray100),
                  const SizedBox(height: AppSpacing.sm),
                  _OverflowRow(symbol: symbol, entries: overflow),
                ],
              ],
            ),
          );
        },
        loading: () => const SizedBox(
            height: 184,
            child:
                Center(child: CircularProgressIndicator(color: AppColors.black))),
        error: (_, _) => const ErrorCard(),
      ),
    );
  }
}

TransactionCategory _catFor(String key) => TransactionCategory.values.firstWhere(
      (c) => c.name == key,
      orElse: () => TransactionCategory.other,
    );

class _DonutCenter extends StatelessWidget {
  const _DonutCenter(
      {required this.symbol, required this.total, required this.count});
  final String symbol;
  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('SPENT', style: AppTextStyles.section.copyWith(fontSize: 10.5)),
        const SizedBox(height: 1),
        Text('$symbol${reportFmt(total)}',
            style: AppTextStyles.numericL.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              color: AppColors.black,
            )),
        const SizedBox(height: 1),
        Text('$count categories',
            style: AppTextStyles.bodyS
                .copyWith(fontSize: 11, color: AppColors.gray400)),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(
      {required this.color, required this.name, required this.amount});
  final Color color;
  final String name;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.xxs,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyS.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                )),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(amount,
              style: AppTextStyles.numericM
                  .copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _OverflowRow extends StatelessWidget {
  const _OverflowRow({required this.symbol, required this.entries});
  final String symbol;
  final List<MapEntry<String, double>> entries;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final e in entries.take(2))
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.categoryColor(_catFor(e.key)),
                    borderRadius: AppRadius.xxs,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${_catFor(e.key).label} · $symbol${reportFmt(e.value)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Daily spend bar card ───────────────────────────────
//
// 7 mini-bars (Mon–Sun) from the real per-day spend of the selected week;
// the peak day is inked, the rest are gray. Header shows the daily average.

const List<String> _kWeekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class DailySpendCard extends ConsumerWidget {
  const DailySpendCard({super.key, required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailySpendingForWeekProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: dailyAsync.when(
        data: (values) {
          final spentDays = values.where((v) => v > 0).length;
          final total = values.fold<double>(0, (s, v) => s + v);
          final avg = spentDays > 0 ? total / spentDays : 0.0;
          final peak = values.isEmpty
              ? 0.0
              : values.reduce((a, b) => a > b ? a : b);
          final peakIndex =
              peak > 0 ? values.indexWhere((v) => v == peak) : -1;

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.xl,
              boxShadow: AppShadows.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Daily spend',
                        style: AppTextStyles.headingS
                            .copyWith(fontSize: 15, color: AppColors.black)),
                    Text('avg $symbol${reportFmt(avg)}/day',
                        style: AppTextStyles.bodyS.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray400)),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 110,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: _Bar(
                            fraction: peak > 0 ? values[i] / peak : 0.0,
                            day: _kWeekdayLetters[i],
                            isPeak: i == peakIndex,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Container(
          height: 168,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.xl,
            boxShadow: AppShadows.md,
          ),
          child: const Center(
              child: CircularProgressIndicator(color: AppColors.black)),
        ),
        error: (_, _) => const ErrorCard(),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(
      {required this.fraction, required this.day, required this.isPeak});
  final double fraction;
  final String day;
  final bool isPeak;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fraction.clamp(0.0, 1.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 26),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isPeak ? AppColors.black : AppColors.gray200,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7),
                    bottom: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(day,
            style: AppTextStyles.labelS.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPeak ? AppColors.black : AppColors.gray400,
            )),
      ],
    );
  }
}

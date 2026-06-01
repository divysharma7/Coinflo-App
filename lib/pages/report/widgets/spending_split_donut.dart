import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';

import 'package:finance_buddy_app/pages/report/widgets/report_helpers.dart';
import 'package:finance_buddy_app/pages/report/widgets/report_scope.dart';

// ─── Donut Chart ────────────────────────────────────────

class SpendingSplitDonut extends ConsumerStatefulWidget {
  const SpendingSplitDonut({super.key, required this.symbol});
  final String symbol;

  @override
  ConsumerState<SpendingSplitDonut> createState() => _SpendingSplitDonutState();
}

class _SpendingSplitDonutState extends ConsumerState<SpendingSplitDonut> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final symbol = widget.symbol;
    final catTotals = ref.watch(monthCategoryTotalsProvider);
    final budgetAsync = ref.watch(monthlyBudgetProvider);

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
            decoration: reportCardDecor(),
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
                    _dotLabel(AppColors.black, 'Spent $symbol${reportFmt(totalSpent)}'),
                    const SizedBox(width: AppSpacing.lg),
                    _dotLabel(AppColors.gray300, 'Left $symbol${reportFmt(left)}'),
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
}

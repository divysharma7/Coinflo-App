import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/widgets/common/animated_progress_bar.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';

import 'package:finance_buddy_app/pages/report/widgets/report_helpers.dart';
import 'package:finance_buddy_app/pages/report/widgets/report_scope.dart';

// ─── Category Breakdown ─────────────────────────────────

class CategoryBreakdownSection extends ConsumerWidget {
  const CategoryBreakdownSection({super.key, required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catTotals = ref.watch(monthCategoryTotalsProvider);
    final prevTotals = ref.watch(prevMonthCategoryTotalsProvider);

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
                      final month = ref.read(reportMonthProvider);
                      context.push('/report/category', extra: {
                        'category': entry.key,
                        'month': month,
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: reportCardDecor(),
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
                          Text('$symbol${reportFmt(amount)}',
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

import 'package:finance_buddy_app/widgets/common/error_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/animated_progress_bar.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

import 'home_format_helpers.dart';

class TopCategoriesSection extends ConsumerWidget {
  const TopCategoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topCats = ref.watch(topCategoriesProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final symbol = currencySymbol(currencyAsync.valueOrNull ?? 'inr');

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
              borderRadius: AppRadius.lg,
              boxShadow: AppShadows.lg,
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
                  final color = AppColors.categoryColor(cat.group);
                  final pct = maxVal > 0 ? entry.value / maxVal : 0.0;

                  return GestureDetector(
                    onTap: () {
                      final month = ref.read(selectedMonthProvider);
                      context.push('/report/category', extra: {
                        'category': cat.name,
                        'month': month,
                      });
                    },
                    child: Padding(
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
                                      '$symbol${formatHomeNumber(entry.value)}',
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

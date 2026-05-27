import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/amount_text.dart';
import 'package:finance_buddy_app/widgets/common/empty_state.dart';
import 'package:finance_buddy_app/widgets/common/hero_amount.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';

class DailyViewPage extends ConsumerWidget {
  final DateTime date;

  const DailyViewPage({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(dailyTransactionsProvider(date));
    final dayName = DateFormat('EEEE').format(date);
    final symbol = currencySymbol(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');

    return Scaffold(
      appBar: AppBar(title: Text(dayName)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: txns.when(
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.check_circle_outline,
              message: '${symbol}0 spent this day.',
              subtitle: 'A clean slate — nothing spent today.',
            );
          }
          final total = list
              .where((t) => t.amount < 0)
              .fold<double>(0, (s, t) => s + t.amount.abs());
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                color: AppColors.white,
                child: Column(
                  children: [
                    const Text('TOTAL SPENT', style: AppTextStyles.labelM),
                    const SizedBox(height: AppSpacing.xs),
                    HeroAmount(amount: total, symbol: symbol, amountSize: 36, symbolSize: 18),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.black,
                  backgroundColor: AppColors.white,
                  onRefresh: () async {
                    ref.invalidate(dailyTransactionsProvider(date));
                  },
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final t = list[i];
                      final cat = TransactionCategory.values.firstWhere(
                        (c) => c.name == t.category,
                        orElse: () => TransactionCategory.foodAndDrink,
                      );
                      final catColor = AppColors.categoryColor(cat);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: catColor.withValues(alpha: 0.15),
                          child: Icon(cat.iconFill, color: catColor, size: 20),
                        ),
                        title: Text(
                          t.merchant ?? cat.label,
                          style: AppTextStyles.bodyM,
                        ),
                        subtitle: Text(
                          DateFormat('h:mm a').format(t.happenedAt),
                          style: const TextStyle(color: AppColors.gray500, fontSize: 12),
                        ),
                        trailing: AmountText(amount: t.amount, symbol: symbol),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.black),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Something went wrong', style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => ref.invalidate(dailyTransactionsProvider(date)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: AppRadius.s,
                  ),
                  child: Text('Retry', style: AppTextStyles.bodyS.copyWith(color: AppColors.white)),
                ),
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }
}

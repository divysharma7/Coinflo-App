import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/amount_text.dart';
import 'package:finance_buddy_app/widgets/common/empty_state.dart';
import 'package:finance_buddy_app/widgets/common/hero_amount.dart';

class DailyViewPage extends ConsumerWidget {
  final DateTime date;

  const DailyViewPage({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(dailyTransactionsProvider(date));
    final dayName = DateFormat('EEEE').format(date);

    return Scaffold(
      appBar: AppBar(title: Text(dayName)),
      body: txns.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              message: '\$0 spent this day.',
              subtitle: 'No transactions recorded.',
            );
          }
          final total = list
              .where((t) => t.amount < 0)
              .fold<double>(0, (s, t) => s + t.amount.abs());
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SpendlerSpacing.lg),
                color: SpendlerColors.surface,
                child: Column(
                  children: [
                    const Text('TOTAL SPENT', style: SpendlerTextStyles.sectionLabel),
                    const SizedBox(height: SpendlerSpacing.sm),
                    HeroAmount(amount: total, amountSize: 36, symbolSize: 18),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final t = list[i];
                    final cat = TransactionCategory.values.firstWhere(
                      (c) => c.name == t.category,
                      orElse: () => TransactionCategory.foodAndDrink,
                    );
                    final catColor = SpendlerColors.categoryColor(cat);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: catColor.withValues(alpha: 0.15),
                        child: Icon(cat.iconFill, color: catColor, size: 20),
                      ),
                      title: Text(
                        t.merchant ?? cat.label,
                        style: SpendlerTextStyles.merchantName,
                      ),
                      subtitle: Text(
                        DateFormat('h:mm a').format(t.happenedAt),
                        style: const TextStyle(color: SpendlerColors.textTertiary, fontSize: 12),
                      ),
                      trailing: AmountText(amount: t.amount),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: SpendlerColors.primary),
        ),
        error: (_, _) => const Center(
          child: Text('Error loading', style: TextStyle(color: SpendlerColors.expense)),
        ),
      ),
    );
  }
}

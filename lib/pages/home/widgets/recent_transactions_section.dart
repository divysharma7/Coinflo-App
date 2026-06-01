import 'package:finance_buddy_app/widgets/common/error_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';
import 'package:finance_buddy_app/widgets/common/transaction_actions.dart';

class RecentTransactionsSection extends ConsumerWidget {
  const RecentTransactionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(monthlyTransactionsForHomeProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final symbol = currencySymbol(currencyAsync.valueOrNull ?? 'inr');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with See All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent',
                  style:
                      AppTextStyles.headingS.copyWith(color: AppColors.black)),
              GestureDetector(
                onTap: () {
                  // Switch to transactions tab
                  ref.read(selectedTabProvider.notifier).state = 1;
                },
                child: Text('See all',
                    style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          txnsAsync.when(
            data: (txns) {
              if (txns.isEmpty) return _buildEmptyState();

              final sorted = List<SpendlerTransaction>.from(txns)
                ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
              final recent = sorted.take(5).toList();

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.mdLg,
                ),
                child: Column(
                  children: recent.asMap().entries.map((e) {
                    final isLast = e.key == recent.length - 1;
                    return Column(
                      children: [
                        _TransactionRow(transaction: e.value, symbol: symbol),
                        if (!isLast)
                          const Padding(
                            padding: EdgeInsets.only(left: 56),
                            child: Divider(
                                height: 1,
                                thickness: 0.5,
                                color: AppColors.gray200),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.black)),
            ),
            error: (_, _) => const ErrorCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.mdLg,
              ),
              child: Icon(PhosphorIcons.receipt(),
                  size: 24, color: AppColors.gray300),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Nothing here yet',
                style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
            const SizedBox(height: AppSpacing.xxs),
            Text('Tap + to log your first spend',
                style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500)),
          ],
        ),
      ),
    );
  }
}

// ─── Transaction Row ──────────────────────────────────────

class _TransactionRow extends ConsumerWidget {
  const _TransactionRow({required this.transaction, required this.symbol});

  final SpendlerTransaction transaction;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == transaction.category,
      orElse: () => TransactionCategory.other,
    );
    final isExpense = transaction.amount < 0;
    final displayAmount =
        '${isExpense ? '-' : '+'}$symbol${transaction.amount.abs().toStringAsFixed(0)}';

    return GestureDetector(
      onTap: () => context.push('/transaction/${transaction.id}'),
      onLongPress: () => showTransactionActions(context, ref, transaction, symbol),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.categoryBg(cat),
                borderRadius: AppRadius.base,
              ),
              child: Icon(cat.iconFill, size: 18, color: AppColors.categoryFg(cat)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.note ?? transaction.merchant ?? cat.label,
                      style: AppTextStyles.bodyM.copyWith(
                          fontWeight: FontWeight.w500, color: AppColors.black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(cat.label,
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.gray500, fontSize: 12)),
                ],
              ),
            ),
            Text(displayAmount,
                style: AppTextStyles.numericL.copyWith(
                    color: isExpense ? AppColors.black : AppColors.green)),
          ],
        ),
      ),
    );
  }
}

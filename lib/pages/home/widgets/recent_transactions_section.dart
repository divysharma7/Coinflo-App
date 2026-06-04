import 'package:finance_buddy_app/widgets/common/error_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';
import 'package:finance_buddy_app/widgets/common/transaction_actions.dart';

import 'home_format_helpers.dart';

class RecentTransactionsSection extends ConsumerWidget {
  const RecentTransactionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(monthlyTransactionsForHomeProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final symbol = currencySymbol(currencyAsync.valueOrNull ?? 'inr');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md + 6, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header (ink, w700, not uppercase) + See all ›
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent activity',
                  style: AppTextStyles.headingS.copyWith(
                      color: AppColors.black,
                      fontSize: 17,
                      letterSpacing: -0.3)),
              GestureDetector(
                onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('See all',
                        style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.gray500,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                        size: 13, color: AppColors.gray500),
                  ],
                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.xl,
                  boxShadow: AppShadows.sm,
                ),
                child: Column(
                  children: recent.asMap().entries.map((e) {
                    final isLast = e.key == recent.length - 1;
                    return Column(
                      children: [
                        _TransactionRow(transaction: e.value, symbol: symbol),
                        if (!isLast)
                          const Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.gray100),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.md,
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
        '${isExpense ? '−' : '+'}$symbol${formatHomeNumber(transaction.amount.abs())}';

    final name = transaction.note ?? transaction.merchant ?? cat.label;
    final meta = '${cat.label} · ${_timeLabel(transaction.happenedAt)}';

    return GestureDetector(
      onTap: () => context.push('/transaction/${transaction.id}'),
      onLongPress: () => showTransactionActions(context, ref, transaction, symbol),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.categoryBg(cat),
                borderRadius: AppRadius.md,
              ),
              child: Icon(cat.iconFill,
                  size: 22, color: AppColors.categoryColor(cat)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTextStyles.bodyM.copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: AppColors.black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(meta,
                      style: AppTextStyles.bodyS.copyWith(
                          fontSize: 12.5, color: AppColors.gray500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(displayAmount,
                style: AppTextStyles.numericL.copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: isExpense ? AppColors.black : AppColors.catGreenText)),
          ],
        ),
      ),
    );
  }

  /// "8:24 PM" today, "Yesterday", else "12 May".
  String _timeLabel(DateTime when) {
    final now = DateTime.now();
    final day = DateTime(when.year, when.month, when.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return DateFormat('h:mm a').format(when);
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM').format(when);
  }
}

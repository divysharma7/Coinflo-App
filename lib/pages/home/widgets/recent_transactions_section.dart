import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/utils/currency_utils.dart';
import 'package:finance_buddy_app/widgets/common/error_card.dart';
import 'package:finance_buddy_app/widgets/common/transaction_actions.dart';

import 'home_format_helpers.dart';

/// Zone 4 — recent activity: a header with a "See all" link (→ /transactions)
/// and a white card listing up to 5 latest transactions, newest first.
class RecentTransactionsSection extends ConsumerWidget {
  const RecentTransactionsSection({super.key});

  static const int _maxRows = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Recent activity shows the genuinely LATEST transactions across all time
    // (spec: "latest 4–5 transactions"), not just the selected month — so a
    // transaction added in a different month still appears here. The budget
    // hero and stat tiles stay month-scoped; only this list is all-time.
    final txnsAsync = ref.watch(allTransactionsProvider);
    final code = ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr';
    final symbol = currencySymbol(code);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md + 6,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header (ink, w700) + See all ›.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent activity',
                style: AppTextStyles.headingS.copyWith(
                  color: AppColors.black,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/transactions'),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See all',
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                      size: 13,
                      color: AppColors.gray500,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          txnsAsync.when(
            data: (txns) {
              if (txns.isEmpty) return const _EmptyState();

              final sorted = List<SpendlerTransaction>.from(txns)
                ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
              final recent = sorted.take(_maxRows).toList();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.xl,
                  boxShadow: AppShadows.sm,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < recent.length; i++) ...[
                      _TransactionRow(transaction: recent[i], symbol: symbol, currencyCode: code),
                      if (i != recent.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.gray100,
                        ),
                    ],
                  ],
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.black),
              ),
            ),
            error: (_, _) => const ErrorCard(),
          ),
        ],
      ),
    );
  }
}

/// Empty state shown when there are no transactions for the period.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
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
              child: Icon(
                PhosphorIcons.receipt(),
                size: 24,
                color: AppColors.gray300,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nothing here yet',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Tap + to log your first spend',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Transaction Row ──────────────────────────────────────

class _TransactionRow extends ConsumerWidget {
  const _TransactionRow(
      {required this.transaction,
      required this.symbol,
      required this.currencyCode});

  final SpendlerTransaction transaction;
  final String symbol;
  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == transaction.category,
      orElse: () => TransactionCategory.other,
    );
    final isExpense = transaction.amount < 0;
    final displayAmount =
        '${isExpense ? '−' : '+'}$symbol${formatHomeNumber(transaction.amount.abs(), currencyCode: currencyCode)}';

    final name = transaction.merchant ?? transaction.note ?? cat.label;
    final meta = '${cat.label} · ${_timeLabel(transaction.happenedAt)}';

    return GestureDetector(
      onTap: () => context.push('/transaction/${transaction.id}'),
      onLongPress: () =>
          showTransactionActions(context, ref, transaction, symbol),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            // Category-colored 44px glyph tile.
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.categoryBg(cat),
                borderRadius: AppRadius.md,
              ),
              child: Icon(
                cat.iconFill,
                size: 22,
                color: AppColors.categoryColor(cat),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.bodyM.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: AppTextStyles.labelM.copyWith(
                      color: AppColors.gray500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              displayAmount,
              style: AppTextStyles.numericM.copyWith(
                fontWeight: FontWeight.w600,
                color: isExpense ? AppColors.black : AppColors.catGreenText,
              ),
            ),
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

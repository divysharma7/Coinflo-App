import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/pages/transactions/transaction_detail_page.dart';
import 'package:finance_buddy_app/widgets/common/animations.dart';

// ---------------------------------------------------------------------------
// Provider: transactions for a specific category within a month
// ---------------------------------------------------------------------------

final _categoryMonthTransactionsProvider = FutureProvider.autoDispose
    .family<List<SpendlerTransaction>, ({String category, DateTime month})>(
  (ref, params) async {
    final repo = ref.watch(repositoryProvider);
    final all = await repo.getTransactionsForMonth(params.month);
    return all.where((t) => t.category == params.category).toList();
  },
);

// ---------------------------------------------------------------------------
// CategoryTransactionsPage
// ---------------------------------------------------------------------------

class CategoryTransactionsPage extends ConsumerWidget {
  const CategoryTransactionsPage({
    super.key,
    required this.categoryName,
    required this.month,
  });

  /// The [TransactionCategory.name] value (e.g. "foodAndDrink").
  final String categoryName;

  /// The month to filter transactions for.
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => TransactionCategory.other,
    );
    final catColor = AppColors.categoryColor(cat);
    final symbol = _sym(ref.watch(selectedCurrencyProvider).valueOrNull ?? 'inr');
    final monthLabel = DateFormat('MMMM yyyy').format(month);

    final txnsAsync = ref.watch(
      _categoryMonthTransactionsProvider(
        (category: categoryName, month: month),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── App bar ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.md, AppSpacing.lg, 0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: AppColors.black),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(cat.iconFill, size: 18, color: catColor),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.label,
                            style: AppTextStyles.headingS
                                .copyWith(color: AppColors.black),
                          ),
                          Text(
                            monthLabel,
                            style: AppTextStyles.bodyS
                                .copyWith(color: AppColors.gray400),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ─── Summary strip ─────────────────────────
              txnsAsync.when(
                data: (txns) {
                  final total = txns.fold<double>(
                    0,
                    (sum, t) => sum + t.amount.abs(),
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${txns.length} transaction${txns.length == 1 ? '' : 's'}',
                                style: AppTextStyles.bodyM.copyWith(
                                  color: AppColors.gray500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$symbol${_fmt(total)}',
                            style: AppTextStyles.numericL.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: AppSpacing.sm),

              // ─── Transaction list ──────────────────────
              Expanded(
                child: txnsAsync.when(
                  data: (txns) {
                    if (txns.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.iconFill,
                                size: 48,
                                color: AppColors.gray300,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'No ${cat.label} transactions this month.',
                                style: AppTextStyles.bodyM
                                    .copyWith(color: AppColors.gray400),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: txns.length,
                      itemBuilder: (context, index) {
                        final t = txns[index];
                        final delay = Duration(
                          milliseconds: (30 * index).clamp(0, 600),
                        );
                        return _TransactionTile(
                          transaction: t,
                          symbol: symbol,
                          catColor: catColor,
                        )
                            .animate()
                            .fadeIn(delay: delay, duration: 300.ms)
                            .slideX(
                              begin: 0.05,
                              delay: delay,
                              duration: 300.ms,
                            );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.black),
                  ),
                  error: (_, _) => Center(
                    child: Text(
                      'Failed to load transactions.',
                      style:
                          AppTextStyles.bodyM.copyWith(color: AppColors.gray400),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single transaction tile (mirrors TransactionsPage style)
// ---------------------------------------------------------------------------

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.symbol,
    required this.catColor,
  });

  final SpendlerTransaction transaction;
  final String symbol;
  final Color catColor;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == t.category,
      orElse: () => TransactionCategory.other,
    );
    final isSent = t.amount < 0;

    return PressableCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => TransactionDetailPage(transactionId: t.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: catColor.withValues(alpha: 0.15),
              child: Icon(cat.iconFill, color: catColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.merchant ?? cat.label,
                          style: AppTextStyles.bodyM,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PhosphorIcon(
                        isSent
                            ? PhosphorIcons.arrowUpRight()
                            : PhosphorIcons.arrowDownLeft(),
                        size: 14,
                        color: isSent ? AppColors.red : AppColors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMM, h:mm a').format(t.happenedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$symbol${_fmt(t.amount.abs())}',
              style: AppTextStyles.numericL.copyWith(
                color: isSent ? AppColors.black : AppColors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers (mirrored from report_page.dart)
// ---------------------------------------------------------------------------

String _sym(String code) {
  switch (code.toLowerCase()) {
    case 'inr':
      return '\u20B9';
    case 'usd':
      return '\$';
    case 'eur':
      return '\u20AC';
    case 'gbp':
      return '\u00A3';
    default:
      return '\$';
  }
}

String _fmt(double v) {
  if (v >= 100000) return NumberFormat('#,##,###', 'en_IN').format(v.toInt());
  return NumberFormat('#,###').format(v.toInt());
}

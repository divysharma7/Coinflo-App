import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/notification_bell.dart';
import 'package:finance_buddy_app/pages/home/daily_view_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _HeaderSection()),
        SliverToBoxAdapter(child: _YourMoneyCard()),
        SliverToBoxAdapter(child: _TransactionsSection()),
        SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ─── Dark Header: Avatar + Month + Balance ─────────────

class _HeaderSection extends ConsumerWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final balance = ref.watch(currentBalanceProvider);
    final userName = ref.watch(userNameProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.valueOrNull ?? 'inr';
    final symbol = _currencySymbol(currency);

    final monthLabel = DateFormat('MMMM yyyy').format(month);
    final name = userName.valueOrNull;
    final hasName = name != null && name.trim().isNotEmpty;

    return Container(
      color: AppColors.black,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.paddingOf(context).top + AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        children: [
          // Top row: avatar, month picker, bell
          Row(
            children: [
              // User avatar — show initials or person icon
              hasName
                  ? _UserAvatar(userName: name)
                  : Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(PhosphorIcons.user(),
                          color: AppColors.white.withValues(alpha: 0.6),
                          size: 18),
                    ),
              const Spacer(),
              // Month selector
              GestureDetector(
                onTap: () => _showMonthPicker(context, ref, month),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthLabel,
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const NotificationBell(color: AppColors.white),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Current balance label
          Text(
            'CURRENT BALANCE',
            style: AppTextStyles.labelM.copyWith(
              color: AppColors.white.withValues(alpha: 0.5),
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Balance amount
          balance.when(
            data: (val) => Text(
              '$symbol${_formatNumber(val.abs())}',
              style: AppTextStyles.displayXL.copyWith(
                color: AppColors.white,
                fontSize: 44,
              ),
            ),
            loading: () => Text(
              '${symbol}0',
              style: AppTextStyles.displayXL.copyWith(
                color: AppColors.white,
                fontSize: 44,
              ),
            ),
            error: (_, _) => Text(
              '${symbol}0',
              style: AppTextStyles.displayXL.copyWith(
                color: AppColors.white,
                fontSize: 44,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref, DateTime current) {
    final now = DateTime.now();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final months = List.generate(12, (i) {
          return DateTime(now.year, now.month - i);
        });
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...months.map((m) {
                final isSelected =
                    m.year == current.year && m.month == current.month;
                return ListTile(
                  title: Text(
                    DateFormat('MMMM yyyy').format(m),
                    style: AppTextStyles.bodyM.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? AppColors.black : AppColors.gray500,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check,
                          color: AppColors.black, size: 20)
                      : null,
                  onTap: () {
                    ref.read(selectedMonthProvider.notifier).state = m;
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}

// ─── Your Money Card ───────────────────────────────────

class _YourMoneyCard extends ConsumerWidget {
  const _YourMoneyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(monthlyIncomeProvider);
    final expense = ref.watch(monthlyExpenseProvider);
    final budget = ref.watch(monthlyBudgetProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.valueOrNull ?? 'inr';
    final symbol = _currencySymbol(currency);

    return Transform.translate(
      offset: const Offset(0, -16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Money',
                  style:
                      AppTextStyles.headingS.copyWith(color: AppColors.black),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to Report tab
                    ref.read(selectedTabProvider.notifier).state = 1;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Details',
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Two cards side by side
            Row(
              children: [
                // Income card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.offWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_outward,
                            size: 18,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Income',
                          style: AppTextStyles.bodyS
                              .copyWith(color: AppColors.gray500),
                        ),
                        const SizedBox(height: 2),
                        income.when(
                          data: (val) => Text(
                            '$symbol${_formatNumber(val)}',
                            style: AppTextStyles.headingS,
                          ),
                          loading: () =>
                              Text('${symbol}0', style: AppTextStyles.headingS),
                          error: (_, _) =>
                              Text('${symbol}0', style: AppTextStyles.headingS),
                        ),
                        const SizedBox(height: 4),
                        income.when(
                          data: (val) => Text(
                            val > 0 ? 'New this month' : 'No income yet',
                            style: AppTextStyles.labelS.copyWith(
                              color: val > 0
                                  ? AppColors.green
                                  : AppColors.gray400,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // Spent ring card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.offWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: expense.when(
                      data: (spent) {
                        final budgetVal = budget.valueOrNull ?? 0;
                        final pct = budgetVal > 0
                            ? (spent / budgetVal).clamp(0.0, 1.0)
                            : 0.0;
                        return Column(
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CustomPaint(
                                painter: _SpentRingPainter(progress: pct),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${(pct * 100).toInt()}%',
                                        style: AppTextStyles.headingS
                                            .copyWith(fontSize: 18, height: 1),
                                      ),
                                      Text(
                                        'SPENT',
                                        style: AppTextStyles.labelS.copyWith(
                                            color: AppColors.gray400,
                                            fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '$symbol${_formatNumber(spent)}',
                              style: AppTextStyles.numericL,
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(height: 100),
                      error: (_, _) => const SizedBox(height: 100),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Transactions List ─────────────────────────────────

class _TransactionsSection extends ConsumerWidget {
  const _TransactionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(monthlyTransactionsForHomeProvider);
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.valueOrNull ?? 'inr';
    final symbol = _currencySymbol(currency);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Transactions',
              style: AppTextStyles.headingS.copyWith(color: AppColors.black)),

          const SizedBox(height: AppSpacing.lg),

          // Transaction list grouped by day
          txnsAsync.when(
            data: (txns) {
              if (txns.isEmpty) {
                return _buildEmptyState(symbol);
              }

              // Sort by date descending
              final sorted = List<SpendlerTransaction>.from(txns)
                ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));

              // Group by day
              final grouped = <DateTime, List<SpendlerTransaction>>{};
              for (final t in sorted) {
                final day = DateTime(
                    t.happenedAt.year, t.happenedAt.month, t.happenedAt.day);
                grouped.putIfAbsent(day, () => []).add(t);
              }

              return Column(
                children: grouped.entries.map((entry) {
                  final day = entry.key;
                  final dayTxns = entry.value;
                  final dayLabel =
                      DateFormat('EEEE, MMMM d').format(day);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day header
                      Padding(
                        padding: const EdgeInsets.only(
                            top: AppSpacing.sm, bottom: AppSpacing.xs),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dayLabel,
                              style: AppTextStyles.labelM.copyWith(
                                  color: AppColors.gray400,
                                  letterSpacing: 0.3),
                            ),
                            Text(
                              '${dayTxns.length}',
                              style: AppTextStyles.labelM
                                  .copyWith(color: AppColors.gray300),
                            ),
                          ],
                        ),
                      ),

                      // Transaction rows in a card
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: dayTxns.asMap().entries.map((e) {
                            final isLast = e.key == dayTxns.length - 1;
                            return Column(
                              children: [
                                _TransactionRow(
                                    transaction: e.value, symbol: symbol),
                                if (!isLast)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(left: 56),
                                    child: Divider(
                                      height: 1,
                                      thickness: 0.5,
                                      color: AppColors.gray200,
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),
                    ],
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.black),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String symbol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(PhosphorIcons.receipt(),
                  size: 28, color: AppColors.gray300),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No transactions yet',
              style:
                  AppTextStyles.headingS.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Tap + to add your first expense',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.gray400),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Single Transaction Row ────────────────────────────

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.symbol,
  });

  final SpendlerTransaction transaction;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == transaction.category,
      orElse: () => TransactionCategory.other,
    );
    final isExpense = transaction.amount < 0;
    final displayAmount =
        '${isExpense ? '-' : '+'}$symbol${transaction.amount.abs().toStringAsFixed(0)}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DailyViewPage(date: transaction.happenedAt),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _catBgColor(cat),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.iconFill, size: 18, color: _catIconColor(cat)),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Name + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.merchant ?? cat.label,
                    style: AppTextStyles.bodyM.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cat.label,
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.gray400, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              displayAmount,
              style: AppTextStyles.numericL.copyWith(
                color: isExpense ? AppColors.black : AppColors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _catBgColor(TransactionCategory cat) {
    switch (cat.group) {
      case TransactionCategory.foodAndDrink:
        return AppColors.catOrangeBg;
      case TransactionCategory.transport:
        return AppColors.catBlueBg;
      case TransactionCategory.shopping:
        return AppColors.catPurpleBg;
      case TransactionCategory.entertainment:
        return AppColors.catPinkBg;
      case TransactionCategory.healthAndWellness:
        return AppColors.catGreenBg;
      default:
        return AppColors.catGrayBg;
    }
  }

  Color _catIconColor(TransactionCategory cat) {
    switch (cat.group) {
      case TransactionCategory.foodAndDrink:
        return AppColors.catOrangeText;
      case TransactionCategory.transport:
        return AppColors.catBlueText;
      case TransactionCategory.shopping:
        return AppColors.catPurpleText;
      case TransactionCategory.entertainment:
        return AppColors.catPinkText;
      case TransactionCategory.healthAndWellness:
        return AppColors.catGreenText;
      default:
        return AppColors.catGrayText;
    }
  }
}

// ─── User Avatar ───────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.userName});

  final String? userName;

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(userName);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.bodyS.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

// ─── Spent Ring Painter ────────────────────────────────

class _SpentRingPainter extends CustomPainter {
  _SpentRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = AppColors.gray200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = AppColors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpentRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─── Helpers ───────────────────────────────────────────

String _formatNumber(double value) {
  if (value >= 100000) {
    return NumberFormat('#,##,###', 'en_IN').format(value.toInt());
  }
  return NumberFormat('#,###').format(value.toInt());
}

String _currencySymbol(String code) {
  switch (code.toLowerCase()) {
    case 'inr':
      return '\u20B9';
    case 'usd':
      return '\$';
    case 'eur':
      return '\u20AC';
    case 'gbp':
      return '\u00A3';
    case 'jpy':
      return '\u00A5';
    default:
      return '\$';
  }
}

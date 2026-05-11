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
              // User initials avatar
              _UserAvatar(userName: userName.valueOrNull),
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
              // Notification bell
              const NotificationBell(color: AppColors.white),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Current balance label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CURRENT BALANCE',
                style: AppTextStyles.labelM.copyWith(
                  color: AppColors.white.withValues(alpha: 0.5),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                PhosphorIcons.eye(),
                color: AppColors.white.withValues(alpha: 0.4),
                size: 16,
              ),
            ],
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
                      ? const Icon(Icons.check, color: AppColors.black, size: 20)
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
                Row(
                  children: [
                    Text(
                      'Your Money',
                      style: AppTextStyles.headingS
                          .copyWith(color: AppColors.black),
                    ),
                    const SizedBox(width: 4),
                    Icon(PhosphorIcons.info(),
                        size: 16, color: AppColors.gray400),
                  ],
                ),
                Text(
                  'Details >',
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
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
                        Row(
                          children: [
                            Text(
                              'Income',
                              style: AppTextStyles.bodyS
                                  .copyWith(color: AppColors.gray500),
                            ),
                            const SizedBox(width: 2),
                            Icon(PhosphorIcons.info(),
                                size: 12, color: AppColors.gray400),
                          ],
                        ),
                        const SizedBox(height: 2),
                        income.when(
                          data: (val) => Text(
                            '$symbol${_formatNumber(val)}',
                            style: AppTextStyles.headingS,
                          ),
                          loading: () => Text('${symbol}0',
                              style: AppTextStyles.headingS),
                          error: (_, _) => Text('${symbol}0',
                              style: AppTextStyles.headingS),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '> New this month',
                          style: AppTextStyles.labelS.copyWith(
                            color: AppColors.green,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
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
                                painter: _SpentRingPainter(
                                  progress: pct,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${(pct * 100).toInt()}%',
                                        style:
                                            AppTextStyles.headingS.copyWith(
                                          fontSize: 18,
                                          height: 1,
                                        ),
                                      ),
                                      Text(
                                        'SPENT',
                                        style:
                                            AppTextStyles.labelS.copyWith(
                                          color: AppColors.gray400,
                                          fontSize: 9,
                                        ),
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
          // Header row
          Row(
            children: [
              Text('Transactions',
                  style: AppTextStyles.headingS
                      .copyWith(color: AppColors.black)),
              const Spacer(),
              Icon(PhosphorIcons.funnelSimple(),
                  size: 20, color: AppColors.gray400),
              const SizedBox(width: AppSpacing.sm),
              Icon(PhosphorIcons.arrowsDownUp(),
                  size: 20, color: AppColors.gray400),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray200),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'For the Period',
                  style: AppTextStyles.labelS
                      .copyWith(color: AppColors.gray500, letterSpacing: 0),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Transaction list grouped by day
          txnsAsync.when(
            data: (txns) {
              if (txns.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(
                    child: Text(
                      'No transactions this month.',
                      style: AppTextStyles.bodyM
                          .copyWith(color: AppColors.gray400),
                    ),
                  ),
                );
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
                  final dayLabel = DateFormat('EEEE, MMMM d, yyyy').format(day);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              dayLabel,
                              style: AppTextStyles.bodyS.copyWith(
                                color: AppColors.gray400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${dayTxns.length} transaction${dayTxns.length > 1 ? 's' : ''}',
                            style: AppTextStyles.bodyS
                                .copyWith(color: AppColors.gray400),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Transaction rows
                      ...dayTxns.map((t) => _TransactionRow(
                            transaction: t,
                            symbol: symbol,
                          )),

                      const SizedBox(height: AppSpacing.md),
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
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.icon, size: 20, color: AppColors.gray500),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Name + category pill
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _catPillColor(cat),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _catPillTextColor(cat),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cash',
                        style: AppTextStyles.labelS.copyWith(
                          color: AppColors.gray400,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
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

  Color _catPillColor(TransactionCategory cat) {
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

  Color _catPillTextColor(TransactionCategory cat) {
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

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.gray200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
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

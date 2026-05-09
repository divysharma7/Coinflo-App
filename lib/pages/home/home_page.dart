import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/charts/weekly_bar_chart.dart';
import 'package:finance_buddy_app/widgets/common/animated_amount.dart';
import 'package:finance_buddy_app/widgets/common/contextual_pill.dart';
import 'package:finance_buddy_app/widgets/common/neo_pop_button.dart';
import 'package:finance_buddy_app/widgets/common/notification_bell.dart';
import 'package:finance_buddy_app/services/insight/insight_generator.dart';
import 'package:finance_buddy_app/pages/home/daily_view_page.dart';
import 'package:finance_buddy_app/pages/digest/sunday_digest_page.dart';
import 'package:finance_buddy_app/pages/settings/settings_page.dart';
import 'package:finance_buddy_app/pages/subscriptions/subscriptions_page.dart';
import 'package:finance_buddy_app/pages/report/report_page.dart';
import 'package:finance_buddy_app/pages/penny/penny_page.dart';
import 'package:finance_buddy_app/widgets/common/animations.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FadeSlideIn(delay: Duration.zero, child: _GreetingSection()),
          const SizedBox(height: SpendlerSpacing.xl),
          const FadeSlideIn(delay: Duration(milliseconds: 80), child: _WeeklyHeroSection()),
          const SizedBox(height: SpendlerSpacing.xl),
          const FadeSlideIn(delay: Duration(milliseconds: 160), child: _DailyBreakdownSection()),
          const SizedBox(height: SpendlerSpacing.xl),
          const FadeSlideIn(delay: Duration(milliseconds: 240), child: _CategoryBreakdownSection()),
          const SizedBox(height: SpendlerSpacing.xl),
          const FadeSlideIn(delay: Duration(milliseconds: 320), child: _ActionNeededSection()),
          const FadeSlideIn(delay: Duration(milliseconds: 360), child: _FriendsCardSection()),
          FadeSlideIn(
            delay: const Duration(milliseconds: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PaisaSpacing.screenH + 4,
                vertical: PaisaSpacing.sm,
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const SubscriptionsPage()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: PaisaSpacing.cardPadding,
                    vertical: PaisaSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: PaisaColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(PaisaRadii.card),
                    border: Border.all(color: PaisaColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.autorenew, color: PaisaColors.accentBlue, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Subscriptions',
                        style: TextStyle(
                          color: PaisaColors.accentBlue,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.chevron_right, color: PaisaColors.accentBlue, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          FadeSlideIn(
            delay: const Duration(milliseconds: 390),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpendlerSpacing.screenH + 4,
                vertical: SpendlerSpacing.sm,
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const ReportPage()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpendlerSpacing.cardPadding,
                    vertical: SpendlerSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: SpendlerColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(SpendlerRadii.card),
                    border: Border.all(color: SpendlerColors.border),
                  ),
                  child: Text(
                    'View monthly report \u2192',
                    style: TextStyle(
                      color: SpendlerColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          FadeSlideIn(
            delay: const Duration(milliseconds: 395),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpendlerSpacing.screenH + 4,
                vertical: SpendlerSpacing.sm,
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const PennyPage()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpendlerSpacing.cardPadding,
                    vertical: SpendlerSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: SpendlerColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(SpendlerRadii.card),
                    border: Border.all(
                      color: SpendlerColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: SpendlerColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'P',
                            style: TextStyle(
                              color: SpendlerColors.scaffold,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ask Penny a question \u2192',
                        style: TextStyle(
                          color: SpendlerColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const FadeSlideIn(delay: Duration(milliseconds: 400), child: _WeeklyInsightSection()),
          // Show a digest entry-point on Sundays
          if (DateTime.now().weekday == DateTime.sunday)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpendlerSpacing.screenH + 4,
                vertical: SpendlerSpacing.lg,
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SundayDigestPage(),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpendlerSpacing.cardPadding,
                    vertical: SpendlerSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: SpendlerColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(SpendlerRadii.card),
                    border: Border.all(color: SpendlerColors.border),
                  ),
                  child: const Text(
                    'Your weekly rhythm is ready \u2192',
                    style: TextStyle(
                      color: SpendlerColors.yellow,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ─── Section A: Greeting + Today's Pulse ─────────────

class _GreetingSection extends ConsumerWidget {
  const _GreetingSection();

  String _greeting(String? name) {
    final hour = DateTime.now().hour;
    String time;
    if (hour < 12) {
      time = 'Good morning';
    } else if (hour < 17) {
      time = 'Good afternoon';
    } else {
      time = 'Good evening';
    }
    if (name != null && name.isNotEmpty) {
      return '$time, $name.';
    }
    return '$time.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaySpent = ref.watch(todaySpendingProvider);
    final todayTopCat = ref.watch(todayTopCategoryProvider);
    final userName = ref.watch(userNameProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SpendlerSpacing.screenH + 4,
        MediaQuery.paddingOf(context).top + SpendlerSpacing.lg,
        SpendlerSpacing.screenH + 4,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bell + Settings in top-right
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const NotificationBell(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                  ),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.settings_outlined,
                      color: SpendlerColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          // Greeting with user's name
          Text(
            _greeting(userName.valueOrNull),
            style: SpendlerTextStyles.greeting,
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          // Today's pulse
          todaySpent.when(
            data: (spent) {
              if (spent == 0) {
                return const Text(
                  'Nothing spent today. A clean start.',
                  style: TextStyle(
                    color: SpendlerColors.textSecondary,
                    fontSize: 15,
                  ),
                );
              }
              final catName = todayTopCat.valueOrNull;
              final catSuffix = catName != null ? ' Mostly $catName.' : '';
              return Text(
                '\$${spent.toStringAsFixed(0)} spent today.$catSuffix',
                style: const TextStyle(
                  color: SpendlerColors.textSecondary,
                  fontSize: 15,
                ),
              );
            },
            loading: () => const Text(
              '...',
              style: TextStyle(color: SpendlerColors.textTertiary),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Section B: Weekly Hero Number + Context ─────────

class _WeeklyHeroSection extends ConsumerWidget {
  const _WeeklyHeroSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekProvider);
    final weeklyTxns = ref.watch(weeklyTransactionsProvider);
    final delta = ref.watch(weekOverWeekDeltaProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label + week nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('THIS WEEK', style: SpendlerTextStyles.sectionLabel),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => ref.read(selectedWeekProvider.notifier).state =
                        weekStart.subtract(const Duration(days: 7)),
                    child: const Icon(Icons.chevron_left,
                        color: SpendlerColors.textTertiary, size: 22),
                  ),
                  const SizedBox(width: SpendlerSpacing.sm),
                  GestureDetector(
                    onTap: () {
                      final next = weekStart.add(const Duration(days: 7));
                      if (next.isBefore(DateTime.now())) {
                        ref.read(selectedWeekProvider.notifier).state = next;
                      }
                    },
                    child: const Icon(Icons.chevron_right,
                        color: SpendlerColors.textTertiary, size: 22),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: SpendlerSpacing.md),
          // Hero amount
          weeklyTxns.when(
            data: (txns) {
              final spent = txns
                  .where((t) => t.amount < 0)
                  .fold<double>(0, (s, t) => s + t.amount.abs());
              return AnimatedAmount(
                value: spent,
                prefix: '\$',
                style: SpendlerTextStyles.heroAmount,
                duration: SpendlerMotion.number,
                curve: SpendlerMotion.numberCurve,
              );
            },
            loading: () => const AnimatedAmount(
                value: 0, prefix: '\$', style: SpendlerTextStyles.heroAmount),
            error: (_, _) => const Text('Error',
                style: TextStyle(color: SpendlerColors.expense)),
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          // Delta pill
          delta.when(
            data: (pct) {
              if (pct == 0) return const SizedBox.shrink();
              final sign = pct > 0 ? '↑' : '↓';
              final label = '$sign${pct.abs().toStringAsFixed(0)}% vs last week';
              return ContextualPill(
                text: label,
                type: pct > 0 ? DeltaType.negative : DeltaType.positive,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Section C: Daily Breakdown Chart ────────────────

class _DailyBreakdownSection extends ConsumerWidget {
  const _DailyBreakdownSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekProvider);
    final weeklyTxns = ref.watch(weeklyTransactionsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: SpendlerSpacing.cardGap),
            child: Text('DAILY BREAKDOWN', style: SpendlerTextStyles.sectionLabel),
          ),
          Container(
            padding: const EdgeInsets.all(SpendlerSpacing.cardPadding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E1E), SpendlerColors.surface],
              ),
              borderRadius: BorderRadius.circular(SpendlerRadii.card),
              boxShadow: SpendlerShadows.card,
            ),
            child: weeklyTxns.when(
              data: (txns) => WeeklyBarChart(
                transactions: txns,
                weekStart: weekStart,
                onBarTap: (day) {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => DailyViewPage(date: day)),
                  );
                },
              ),
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                    child:
                        CircularProgressIndicator(color: SpendlerColors.yellow)),
              ),
              error: (_, _) => const SizedBox(
                height: 200,
                child: Center(
                    child: Text('Error',
                        style: TextStyle(color: SpendlerColors.textTertiary))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section D: Where It Went (Category Rows) ───────

class _CategoryBreakdownSection extends ConsumerWidget {
  const _CategoryBreakdownSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyTxns = ref.watch(weeklyTransactionsProvider);
    final merchantCounts = ref.watch(weeklyMerchantCountsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WHERE IT WENT', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.md),
          weeklyTxns.when(
            data: (txns) {
              final totals = <TransactionCategory, double>{};
              for (final t in txns) {
                if (t.amount < 0) {
                  final cat = TransactionCategory.values.firstWhere(
                    (c) => c.name == t.category,
                    orElse: () => TransactionCategory.other,
                  );
                  totals[cat] = (totals[cat] ?? 0) + t.amount.abs();
                }
              }
              if (totals.isEmpty) {
                return const Text(
                  'No spending yet this week.',
                  style: SpendlerTextStyles.emptyState,
                );
              }

              final sorted = totals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final totalSpent =
                  sorted.fold<double>(0, (s, e) => s + e.value);

              // Get top merchant for subline
              final counts = merchantCounts.valueOrNull ?? {};
              String? topMerchantLine;
              if (counts.isNotEmpty) {
                final topEntry =
                    counts.entries.reduce((a, b) => a.value > b.value ? a : b);
                if (topEntry.value >= 2) {
                  topMerchantLine =
                      '${topEntry.key} ${topEntry.value}x this week';
                }
              }

              return Column(
                children: sorted.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cat = entry.value.key;
                  final amount = entry.value.value;
                  final pct =
                      totalSpent > 0 ? amount / totalSpent : 0.0;
                  final isDominant = i == 0;
                  final catColor = SpendlerColors.categoryColor(cat);

                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: SpendlerSpacing.md),
                    child: Row(
                      children: [
                        Icon(
                          cat.iconFill,
                          size: 22,
                          color: isDominant
                              ? catColor
                              : SpendlerColors.textTertiary,
                        ),
                        const SizedBox(width: SpendlerSpacing.cardGap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    cat.label,
                                    style: TextStyle(
                                      color: isDominant
                                          ? SpendlerColors.textPrimary
                                          : SpendlerColors.textSecondary,
                                      fontSize: 15,
                                      fontWeight: isDominant
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    '\$${amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isDominant
                                          ? SpendlerColors.textPrimary
                                          : SpendlerColors.textTertiary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: SpendlerColors.border,
                                  valueColor: AlwaysStoppedAnimation(
                                    isDominant
                                        ? catColor
                                        : SpendlerColors.textTertiary,
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                              if (isDominant && topMerchantLine != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  topMerchantLine,
                                  style: TextStyle(
                                    color: catColor.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Section E: Action Needed ────────────────────────

class _ActionNeededSection extends ConsumerWidget {
  const _ActionNeededSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unconfirmed = ref.watch(unconfirmedQueueProvider);

    return unconfirmed.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            SpendlerSpacing.screenH + 4,
            0,
            SpendlerSpacing.screenH + 4,
            SpendlerSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ACTION NEEDED', style: SpendlerTextStyles.sectionLabel),
              const SizedBox(height: SpendlerSpacing.md),
              Text(
                '${list.length} transaction${list.length > 1 ? 's' : ''} need a quick look.',
                style: const TextStyle(
                  color: SpendlerColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: SpendlerSpacing.md),
              if (list.length >= 2)
                NeoPOPButton(
                  label: 'Confirm All (${list.length})',
                  onTap: () async {
                    await HapticFeedback.mediumImpact();
                    final repo = ref.read(repositoryProvider);
                    await repo.confirmAllUnconfirmed();
                  },
                ),
              const SizedBox(height: SpendlerSpacing.sm),
              Center(
                child: GestureDetector(
                  onTap: () =>
                      ref.read(selectedTabProvider.notifier).state = 1,
                  child: const Text(
                    'Review individually →',
                    style: TextStyle(
                      color: SpendlerColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ─── Section F: Weekly Insight ───────────────────────

class _WeeklyInsightSection extends ConsumerWidget {
  const _WeeklyInsightSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyTxns = ref.watch(weeklyTransactionsProvider);
    final merchantCounts = ref.watch(weeklyMerchantCountsProvider);

    return weeklyTxns.when(
      data: (txns) {
        final expenses = txns.where((t) => t.amount < 0).toList();
        if (expenses.isEmpty) return const SizedBox.shrink();

        final totalSpent =
            expenses.fold<double>(0, (s, t) => s + t.amount.abs());
        final catTotals = <TransactionCategory, double>{};
        for (final t in expenses) {
          final cat = TransactionCategory.values.firstWhere(
            (c) => c.name == t.category,
            orElse: () => TransactionCategory.other,
          );
          catTotals[cat] = (catTotals[cat] ?? 0) + t.amount.abs();
        }
        final sortedCats = catTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final counts = merchantCounts.valueOrNull ?? {};
        final insight = generateWeeklyInsight(
          sortedCats: sortedCats,
          totalSpent: totalSpent,
          merchantCounts: counts,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: SpendlerSpacing.screenH + 4),
          child: Text(insight, style: SpendlerTextStyles.insightBody),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ─── With Friends Card ───────────────────────────────

class _FriendsCardSection extends ConsumerWidget {
  const _FriendsCardSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(totalFriendBalanceProvider);
    final contactsAsync = ref.watch(friendContactsProvider);

    return balanceAsync.when(
      data: (balance) {
        if (balance.totalReceivable == 0 && balance.totalPayable == 0) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            SpendlerSpacing.screenH, 0, SpendlerSpacing.screenH, SpendlerSpacing.xl,
          ),
          child: Container(
            padding: const EdgeInsets.all(SpendlerSpacing.cardPadding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E1E), SpendlerColors.surface],
              ),
              borderRadius: BorderRadius.circular(SpendlerRadii.card),
              boxShadow: SpendlerShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('WITH FRIENDS', style: SpendlerTextStyles.sectionLabel),
                    GestureDetector(
                      onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
                      child: const Text(
                        'See all →',
                        style: TextStyle(color: SpendlerColors.yellow, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SpendlerSpacing.md),
                if (balance.totalReceivable > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '↓ \$${balance.totalReceivable.toStringAsFixed(0)} to collect',
                      style: const TextStyle(color: SpendlerColors.income, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                if (balance.totalPayable > 0)
                  Text(
                    '�� \$${balance.totalPayable.toStringAsFixed(0)} to pay back',
                    style: const TextStyle(color: SpendlerColors.amber, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                contactsAsync.when(
                  data: (contacts) {
                    if (contacts.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: SpendlerSpacing.md),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: contacts.take(4).map((c) {
                            Color chipColor;
                            try {
                              chipColor = Color(int.parse(c.avatarColour.replaceFirst('#', '0xFF')));
                            } on FormatException {
                              chipColor = SpendlerColors.textTertiary;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: SpendlerSpacing.sm),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: SpendlerColors.surface,
                                  borderRadius: BorderRadius.circular(SpendlerRadii.pill),
                                  border: Border.all(color: SpendlerColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: chipColor,
                                      child: Text(
                                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(c.name, style: const TextStyle(color: SpendlerColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

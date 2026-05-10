import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/core/enums.dart';
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
          const SizedBox(height: AppSpacing.xxl),
          const FadeSlideIn(delay: Duration(milliseconds: 80), child: _WeeklyHeroSection()),
          const SizedBox(height: AppSpacing.xxl),
          const FadeSlideIn(delay: Duration(milliseconds: 160), child: _DailyBreakdownSection()),
          const SizedBox(height: AppSpacing.xxl),
          const FadeSlideIn(delay: Duration(milliseconds: 240), child: _CategoryBreakdownSection()),
          const SizedBox(height: AppSpacing.xxl),
          const FadeSlideIn(delay: Duration(milliseconds: 320), child: _ActionNeededSection()),
          const FadeSlideIn(delay: Duration(milliseconds: 360), child: _FriendsCardSection()),
          FadeSlideIn(
            delay: const Duration(milliseconds: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const SubscriptionsPage()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.xl,
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.autorenew, color: AppColors.black, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Subscriptions',
                        style: AppTextStyles.bodyM.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: AppColors.black, size: 20),
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
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const ReportPage()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.xl,
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Text(
                    'View monthly report \u2192',
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.black,
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
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const PennyPage()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.08),
                    borderRadius: AppRadius.xl,
                    border: Border.all(
                      color: AppColors.black.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'P',
                            style: TextStyle(
                              color: AppColors.offWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ask Penny a question \u2192',
                        style: AppTextStyles.bodyM.copyWith(
                          color: AppColors.black,
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
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
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
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.xl,
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Text(
                    'Your weekly rhythm is ready \u2192',
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.black,
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
        AppSpacing.lg,
        MediaQuery.paddingOf(context).top + AppSpacing.xl,
        AppSpacing.lg,
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
                      color: AppColors.gray500,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Greeting with user's name
          Text(
            _greeting(userName.valueOrNull),
            style: AppTextStyles.headingL,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Today's pulse
          todaySpent.when(
            data: (spent) {
              if (spent == 0) {
                return Text(
                  'Nothing spent today. A clean start.',
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
                );
              }
              final catName = todayTopCat.valueOrNull;
              final catSuffix = catName != null ? ' Mostly $catName.' : '';
              return Text(
                '\$${spent.toStringAsFixed(0)} spent today.$catSuffix',
                style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
              );
            },
            loading: () => Text(
              '...',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label + week nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('THIS WEEK', style: AppTextStyles.labelM.copyWith(color: AppColors.gray400)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => ref.read(selectedWeekProvider.notifier).state =
                        weekStart.subtract(const Duration(days: 7)),
                    child: const Icon(Icons.chevron_left,
                        color: AppColors.gray500, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  GestureDetector(
                    onTap: () {
                      final next = weekStart.add(const Duration(days: 7));
                      if (next.isBefore(DateTime.now())) {
                        ref.read(selectedWeekProvider.notifier).state = next;
                      }
                    },
                    child: const Icon(Icons.chevron_right,
                        color: AppColors.gray500, size: 22),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Hero amount
          weeklyTxns.when(
            data: (txns) {
              final spent = txns
                  .where((t) => t.amount < 0)
                  .fold<double>(0, (s, t) => s + t.amount.abs());
              return AnimatedAmount(
                value: spent,
                prefix: '\$',
                style: AppTextStyles.displayXL,
                duration: AppDurations.slow,
                curve: Curves.elasticOut,
              );
            },
            loading: () => const AnimatedAmount(
                value: 0, prefix: '\$', style: AppTextStyles.displayXL),
            error: (_, _) => const Text('Error',
                style: TextStyle(color: AppColors.red)),
          ),
          const SizedBox(height: AppSpacing.xs),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text('DAILY BREAKDOWN', style: AppTextStyles.labelM.copyWith(color: AppColors.gray400)),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.xl,
              boxShadow: AppShadows.sm,
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
                        CircularProgressIndicator(color: AppColors.black)),
              ),
              error: (_, _) => const SizedBox(
                height: 200,
                child: Center(
                    child: Text('Error',
                        style: TextStyle(color: AppColors.gray500))),
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

  static const Map<TransactionCategory, Color> _categoryHue = {
    TransactionCategory.foodAndDrink: Color(0xFFFF8A4C),
    TransactionCategory.transport: Color(0xFF4A8FE7),
    TransactionCategory.shopping: Color(0xFFB19CD9),
    TransactionCategory.billsAndUtilities: Color(0xFFF59E0B),
    TransactionCategory.healthAndWellness: Color(0xFF22C55E),
    TransactionCategory.entertainment: Color(0xFFE91E63),
    TransactionCategory.streaming: Color(0xFFEC407A),
    TransactionCategory.gymFitness: Color(0xFF4CAF50),
    TransactionCategory.productivityTools: Color(0xFF9575CD),
    TransactionCategory.personalCare: Color(0xFFF8BBD0),
    TransactionCategory.education: Color(0xFF5C6BC0),
    TransactionCategory.travel: Color(0xFF14B8A6),
    TransactionCategory.other: Color(0xFF6E6E73),
  };

  static Color _categoryColor(TransactionCategory cat) =>
      _categoryHue[cat] ?? const Color(0xFF6E6E73);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantCounts = ref.watch(weeklyMerchantCountsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WHERE IT WENT', style: AppTextStyles.labelM.copyWith(color: AppColors.gray400)),
          const SizedBox(height: AppSpacing.md),
          ref.watch(weeklyCategoryTotalsProvider).when(
            data: (sorted) {
              if (sorted.isEmpty) {
                return Text(
                  'No spending yet this week.',
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
                );
              }

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
                  final catColor = _categoryColor(cat);

                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(
                          cat.iconFill,
                          size: 22,
                          color: isDominant
                              ? catColor
                              : AppColors.gray500,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      cat.label,
                                      style: TextStyle(
                                        color: isDominant
                                            ? AppColors.black
                                            : AppColors.gray500,
                                        fontSize: 15,
                                        fontWeight: isDominant
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '\$${amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isDominant
                                          ? AppColors.black
                                          : AppColors.gray500,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: AppColors.gray200,
                                  valueColor: AlwaysStoppedAnimation(
                                    isDominant
                                        ? catColor
                                        : AppColors.gray500,
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
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ACTION NEEDED', style: AppTextStyles.labelM.copyWith(color: AppColors.gray400)),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${list.length} transaction${list.length > 1 ? 's' : ''} need a quick look.',
                style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
              ),
              const SizedBox(height: AppSpacing.md),
              if (list.length >= 2)
                NeoPOPButton(
                  label: 'Confirm All (${list.length})',
                  onTap: () async {
                    await HapticFeedback.mediumImpact();
                    await confirmAllTransactions(ref.read(repositoryProvider));
                  },
                ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: GestureDetector(
                  onTap: () =>
                      ref.read(selectedTabProvider.notifier).state = 1,
                  child: Text(
                    'Review individually →',
                    style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
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
    final merchantCounts = ref.watch(weeklyMerchantCountsProvider);

    final sortedCatsAsync = ref.watch(weeklyCategoryTotalsProvider);
    final totalSpentAsync = ref.watch(weeklyTotalSpentProvider);

    return sortedCatsAsync.when(
      data: (sortedCats) {
        if (sortedCats.isEmpty) return const SizedBox.shrink();

        final totalSpent = totalSpentAsync.valueOrNull ?? 0.0;
        final counts = merchantCounts.valueOrNull ?? {};
        final insight = generateWeeklyInsight(
          sortedCats: sortedCats,
          totalSpent: totalSpent,
          merchantCounts: counts,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg),
          child: Text(insight, style: AppTextStyles.bodyM),
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
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.xl,
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('WITH FRIENDS', style: AppTextStyles.labelM.copyWith(color: AppColors.gray400)),
                    GestureDetector(
                      onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
                      child: Text(
                        'See all →',
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (balance.totalReceivable > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '↓ \$${balance.totalReceivable.toStringAsFixed(0)} to collect',
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (balance.totalPayable > 0)
                  Text(
                    '↑ \$${balance.totalPayable.toStringAsFixed(0)} to pay back',
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                contactsAsync.when(
                  data: (contacts) {
                    if (contacts.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: contacts.take(4).map((c) {
                            Color chipColor;
                            try {
                              chipColor = Color(int.parse(c.avatarColour.replaceFirst('#', '0xFF')));
                            } on FormatException {
                              chipColor = AppColors.gray500;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.xs),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: AppRadius.full,
                                  border: Border.all(color: AppColors.gray200),
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
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 100),
                                      child: Text(
                                        c.name,
                                        style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
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

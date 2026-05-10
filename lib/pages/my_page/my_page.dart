import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/animations.dart';
import 'package:finance_buddy_app/widgets/common/animated_amount.dart';
import 'package:finance_buddy_app/widgets/common/contextual_pill.dart';
import 'package:finance_buddy_app/widgets/common/health_ring.dart';
import 'package:finance_buddy_app/services/insight/insight_generator.dart';
import 'package:finance_buddy_app/pages/digest/sunday_digest_page.dart';
import 'package:finance_buddy_app/pages/analytics/analytics_page.dart';
import 'package:finance_buddy_app/pages/settings/settings_page.dart';

class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // Profile header with parallax
        SliverAppBar(
          expandedHeight: 260,
          floating: false,
          pinned: false,
          backgroundColor: SpendlerColors.scaffold,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _ProfileHeader(),
          ),
        ),
        // Cards
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: SpendlerSpacing.screenH),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _WeeklyPulseCard(),
              const SizedBox(height: SpendlerSpacing.cardGap),
              _MonthlyPaceCard(),
              const SizedBox(height: SpendlerSpacing.cardGap),
              _MiniCardsRow(),
              const SizedBox(height: SpendlerSpacing.cardGap),
              _AlertCard(),
              const SizedBox(height: SpendlerSpacing.cardGap),
              _PeopleSummaryCard(),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Profile Header ─────────────────────────────────────

class _ProfileHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final target = ref.watch(spendingTargetProvider);
    final cumulative = ref.watch(thisMonthCumulativeProvider);

    final name = userName.valueOrNull ?? '';
    final targetValue = target.valueOrNull;
    final spentSoFar = cumulative.valueOrNull?.isNotEmpty == true
        ? cumulative.valueOrNull!.last
        : 0.0;

    double? progress;
    if (targetValue != null && targetValue > 0) {
      progress = (1 - (spentSoFar / targetValue)).clamp(0.0, 1.0);
    }

    return Container(
      color: SpendlerColors.scaffold,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top + SpendlerSpacing.md),
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: SpendlerColors.primary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: SpendlerSpacing.sm),
          // Name
          Text(
            name.isNotEmpty ? name : 'Hey there',
            style: SpendlerTextStyles.greeting,
          ),
          const SizedBox(height: SpendlerSpacing.md),
          // Health Ring
          HealthRing(progress: progress ?? 0.0, size: 120),
          const SizedBox(height: SpendlerSpacing.sm),
          // Status text
          if (progress != null)
            Text(
              '${(progress * 100).toStringAsFixed(0)}% of target remaining',
              style: const TextStyle(
                color: SpendlerColors.textSecondary,
                fontSize: 13,
              ),
            )
          else
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
              ),
              child: const Text(
                'Set a monthly target \u2192',
                style: TextStyle(
                  color: SpendlerColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Weekly Pulse Card ──────────────────────────────────

class _WeeklyPulseCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyTxns = ref.watch(weeklyTransactionsProvider);
    final delta = ref.watch(weekOverWeekDeltaProvider);
    final merchantCounts = ref.watch(weeklyMerchantCountsProvider);

    return FadeSlideIn(
      delay: Duration.zero,
      child: PressableCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const SundayDigestPage()),
        ),
        child: Container(
          width: double.infinity,
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
              const Text('WEEKLY PULSE', style: SpendlerTextStyles.sectionLabel),
              const SizedBox(height: SpendlerSpacing.md),
              // Hero amount + delta pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  weeklyTxns.when(
                    data: (txns) {
                      final spent = txns
                          .where((t) => t.amount < 0)
                          .fold<double>(0, (s, t) => s + t.amount.abs());
                      return AnimatedAmount(
                        value: spent,
                        prefix: '\u20b9',
                        style: SpendlerTextStyles.heroAmount.copyWith(fontSize: 36),
                        duration: SpendlerMotion.number,
                        curve: SpendlerMotion.numberCurve,
                      );
                    },
                    loading: () => const AnimatedAmount(
                      value: 0,
                      prefix: '\u20b9',
                      style: SpendlerTextStyles.heroAmount,
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: SpendlerSpacing.sm),
                  delta.when(
                    data: (pct) {
                      if (pct == 0) return const SizedBox.shrink();
                      final sign = pct > 0 ? '\u2191' : '\u2193';
                      final label =
                          '$sign${pct.abs().toStringAsFixed(0)}% vs last week';
                      return ContextualPill(
                        text: label,
                        type:
                            pct > 0 ? DeltaType.negative : DeltaType.positive,
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: SpendlerSpacing.md),
              // One-line insight
              ref.watch(weeklyCategoryTotalsProvider).when(
                data: (sortedCats) {
                  if (sortedCats.isEmpty) return const SizedBox.shrink();
                  final totalSpent = ref.watch(weeklyTotalSpentProvider).valueOrNull ?? 0.0;
                  final counts = merchantCounts.valueOrNull ?? {};
                  final insight = generateWeeklyInsight(
                    sortedCats: sortedCats,
                    totalSpent: totalSpent,
                    merchantCounts: counts,
                  );
                  return Text(
                    insight,
                    style: const TextStyle(
                      color: SpendlerColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: SpendlerSpacing.md),
              // See full report
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'See full report \u2192',
                  style: TextStyle(
                    color: SpendlerColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

// ─── Monthly Pace Card ──────────────────────────────────

class _MonthlyPaceCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(spendingTargetProvider);
    final cumulative = ref.watch(thisMonthCumulativeProvider);

    final targetValue = target.valueOrNull;
    final spentSoFar = cumulative.valueOrNull?.isNotEmpty == true
        ? cumulative.valueOrNull!.last
        : 0.0;

    return FadeSlideIn(
      delay: const Duration(milliseconds: 80),
      child: PressableCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const AnalyticsPage()),
        ),
        child: Container(
          width: double.infinity,
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
              const Text('MONTHLY PACE', style: SpendlerTextStyles.sectionLabel),
              const SizedBox(height: SpendlerSpacing.md),
              if (targetValue != null && targetValue > 0) ...[
                // Spent / Target
                Text(
                  '\u20b9${spentSoFar.toStringAsFixed(0)} / \u20b9${targetValue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: SpendlerColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: SpendlerSpacing.cardGap),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(SpendlerRadii.progressBar),
                  child: LinearProgressIndicator(
                    value: (spentSoFar / targetValue).clamp(0.0, 1.0),
                    backgroundColor: SpendlerColors.border,
                    valueColor:
                        const AlwaysStoppedAnimation(SpendlerColors.primary),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: SpendlerSpacing.sm),
                // Projection text
                ref.watch(monthEndProjectionProvider).when(
                  data: (projection) {
                    if (projection == null) return const SizedBox.shrink();
                    return Text(
                      'At this rate, \u20b9${projection.projected.toStringAsFixed(0)} by month end',
                      style: const TextStyle(
                        color: SpendlerColors.textSecondary,
                        fontSize: 13,
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ] else ...[
                const Text(
                  'Set a monthly target in Settings',
                  style: TextStyle(
                    color: SpendlerColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mini Cards Row ─────────────────────────────────────

class _MiniCardsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final dayAvgAsync = ref.watch(dayOfWeekAveragesProvider);
    final target = ref.watch(spendingTargetProvider);

    return FadeSlideIn(
      delay: const Duration(milliseconds: 160),
      child: Row(
        children: [
          // Left card: Streak
          Expanded(
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
                  const Text('STREAK', style: SpendlerTextStyles.sectionLabel),
                  const SizedBox(height: SpendlerSpacing.sm),
                  streakAsync.when(
                    data: (streak) {
                      final hasTarget = target.valueOrNull != null;
                      if (streak == 0 && !hasTarget) {
                        return const Text(
                          '\u2014',
                          style: TextStyle(
                            color: SpendlerColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }
                      return Text(
                        '$streak',
                        style: const TextStyle(
                          color: SpendlerColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                    loading: () => const Text(
                      '...',
                      style: TextStyle(
                        color: SpendlerColors.textTertiary,
                        fontSize: 28,
                      ),
                    ),
                    error: (_, _) => const Text(
                      '\u2014',
                      style: TextStyle(
                        color: SpendlerColors.textTertiary,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'weeks under target',
                    style: TextStyle(
                      color: SpendlerColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: SpendlerSpacing.cardGap),
          // Right card: Pattern
          Expanded(
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
                  const Text('TOP PATTERN', style: SpendlerTextStyles.sectionLabel),
                  const SizedBox(height: SpendlerSpacing.sm),
                  dayAvgAsync.when(
                    data: (averages) {
                      if (averages.isEmpty) {
                        return const Text(
                          '\u2014',
                          style: TextStyle(
                            color: SpendlerColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }
                      final maxIndex = averages.indexOf(
                        averages.reduce((a, b) => a > b ? a : b),
                      );
                      const days = [
                        'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                      ];
                      final dayName = days[maxIndex];
                      final avgAmount = averages[maxIndex];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayName,
                            style: const TextStyle(
                              color: SpendlerColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'avg \u20b9${avgAmount.toStringAsFixed(0)}/week',
                            style: const TextStyle(
                              color: SpendlerColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Text(
                      '...',
                      style: TextStyle(
                        color: SpendlerColors.textTertiary,
                        fontSize: 20,
                      ),
                    ),
                    error: (_, _) => const Text(
                      '\u2014',
                      style: TextStyle(
                        color: SpendlerColors.textTertiary,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Alert Card ─────────────────────────────────────────

class _AlertCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(weeklyAlertsProvider);

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();
        return FadeSlideIn(
          delay: const Duration(milliseconds: 240),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpendlerSpacing.cardPadding),
            decoration: BoxDecoration(
              color: SpendlerColors.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(SpendlerRadii.card),
              border: Border.all(
                color: SpendlerColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.warning(),
                      color: SpendlerColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text('ALERT', style: SpendlerTextStyles.sectionLabel),
                  ],
                ),
                const SizedBox(height: SpendlerSpacing.sm),
                ...alerts.take(2).map(
                      (alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          alert,
                          style: const TextStyle(
                            color: SpendlerColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
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

// ─── People Summary Card ────────────────────────────────

class _PeopleSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(totalFriendBalanceProvider);

    return balanceAsync.when(
      data: (balance) {
        if (balance.totalReceivable == 0 && balance.totalPayable == 0) {
          return const SizedBox.shrink();
        }
        return FadeSlideIn(
          delay: const Duration(milliseconds: 320),
          child: PressableCard(
            onTap: () =>
                ref.read(selectedTabProvider.notifier).state = 3,
            child: Container(
              width: double.infinity,
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
                  const Text('PEOPLE', style: SpendlerTextStyles.sectionLabel),
                  const SizedBox(height: SpendlerSpacing.md),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (balance.totalReceivable > 0)
                        Text(
                          '\u2193\u20b9${balance.totalReceivable.toStringAsFixed(0)} to collect',
                          style: const TextStyle(
                            color: SpendlerColors.income,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (balance.totalReceivable > 0 &&
                          balance.totalPayable > 0)
                        const Text(
                          '\u00b7',
                          style: TextStyle(
                            color: SpendlerColors.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                      if (balance.totalPayable > 0)
                        Text(
                          '\u2191\u20b9${balance.totalPayable.toStringAsFixed(0)} to pay',
                          style: const TextStyle(
                            color: SpendlerColors.warning,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: SpendlerSpacing.sm),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'See all \u2192',
                      style: TextStyle(
                        color: SpendlerColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

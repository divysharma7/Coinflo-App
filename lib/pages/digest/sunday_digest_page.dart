import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/animated_amount.dart';
import 'package:finance_buddy_app/widgets/common/neo_pop_button.dart';
import 'package:finance_buddy_app/services/insight/insight_generator.dart';
import 'package:finance_buddy_app/widgets/posters/weekly_summary_poster.dart';
import 'package:finance_buddy_app/services/poster/poster_service.dart';
import 'package:finance_buddy_app/services/poster/poster_share.dart';

class SundayDigestPage extends ConsumerStatefulWidget {
  const SundayDigestPage({super.key});

  @override
  ConsumerState<SundayDigestPage> createState() => _SundayDigestPageState();
}

class _SundayDigestPageState extends ConsumerState<SundayDigestPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = ref.watch(selectedWeekProvider);

    return Scaffold(
      backgroundColor: SpendlerColors.scaffold,
      body: SafeArea(
        child: ref.watch(weeklyCategoryTotalsProvider).when(
          data: (sortedCats) {
            final totalSpent = ref.watch(weeklyTotalSpentProvider).valueOrNull ?? 0.0;

            // Weekly insight (shared generator)
            final insight = generateWeeklyInsight(
              sortedCats: sortedCats,
              totalSpent: totalSpent,
              merchantCounts: const {},
            );

            return Column(
              children: [
                // Dot indicators
                Padding(
                  padding: const EdgeInsets.all(SpendlerSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      return AnimatedContainer(
                        duration: SpendlerMotion.transition,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? SpendlerColors.primary
                              : SpendlerColors.textTertiary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                // Card stack
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _Card1TheNumber(
                        totalSpent: totalSpent,
                        weekStart: weekStart,
                      ),
                      _Card2ThePattern(
                        sortedCats: sortedCats,
                        totalSpent: totalSpent,
                      ),
                      _Card3TheInsight(insight: insight),
                      _Card4ThePoster(
                        weekStart: weekStart,
                        totalSpent: totalSpent,
                        catTotals: {
                          for (final e in sortedCats) e.key.name: e.value,
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: SpendlerColors.primary),
          ),
          error: (_, _) => const Center(
            child: Text('Error', style: TextStyle(color: SpendlerColors.expense)),
          ),
        ),
      ),
    );
  }

}

// ─── Card 1: The Number ──────────────────────────────

class _Card1TheNumber extends StatelessWidget {
  const _Card1TheNumber({required this.totalSpent, required this.weekStart});
  final double totalSpent;
  final DateTime weekStart;

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final range = '${weekStart.day}/${weekStart.month} — ${weekEnd.day}/${weekEnd.month}';

    return Padding(
      padding: const EdgeInsets.all(SpendlerSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('THIS WEEK', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: 4),
          Text(range, style: const TextStyle(color: SpendlerColors.textTertiary, fontSize: 14)),
          const SizedBox(height: SpendlerSpacing.lg),
          AnimatedAmount(
            value: totalSpent,
            prefix: '\$',
            style: SpendlerTextStyles.heroAmount,
            duration: SpendlerMotion.dramatic,
            curve: SpendlerMotion.numberCurve,
          ),
          const SizedBox(height: SpendlerSpacing.md),
          const Text(
            'Swipe to see more →',
            style: TextStyle(color: SpendlerColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Card 2: The Pattern ─────────────────────────────

class _Card2ThePattern extends StatefulWidget {
  const _Card2ThePattern({required this.sortedCats, required this.totalSpent});
  final List<MapEntry<TransactionCategory, double>> sortedCats;
  final double totalSpent;

  @override
  State<_Card2ThePattern> createState() => _Card2State();
}

class _Card2State extends State<_Card2ThePattern>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SpendlerSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('WHERE IT WENT', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.lg),
          ...widget.sortedCats.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value.key;
            final amount = entry.value.value;
            final pct = widget.totalSpent > 0 ? amount / widget.totalSpent : 0.0;
            final isDominant = i == 0;
            final catColor = SpendlerColors.categoryColor(cat);

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.3, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _ctrl,
                curve: Interval(
                  (i * 0.04).clamp(0.0, 0.8),
                  ((i * 0.04) + 0.5).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              )),
              child: Padding(
                padding: const EdgeInsets.only(bottom: SpendlerSpacing.cardGap),
                child: Row(
                  children: [
                    Icon(cat.iconFill, size: 20, color: isDominant ? catColor : SpendlerColors.textTertiary),
                    const SizedBox(width: SpendlerSpacing.cardGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.label,
                            style: TextStyle(
                              color: isDominant ? SpendlerColors.textPrimary : SpendlerColors.textSecondary,
                              fontSize: 15,
                              fontWeight: isDominant ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: SpendlerColors.border,
                              valueColor: AlwaysStoppedAnimation(
                                isDominant ? catColor : SpendlerColors.textTertiary,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: SpendlerSpacing.cardGap),
                    Text(
                      '\$${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isDominant ? SpendlerColors.textPrimary : SpendlerColors.textTertiary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Card 3: The Insight ─────────────────────────────

class _Card3TheInsight extends StatefulWidget {
  const _Card3TheInsight({required this.insight});
  final String insight;

  @override
  State<_Card3TheInsight> createState() => _Card3State();
}

class _Card3State extends State<_Card3TheInsight> {
  final List<bool> _visible = [];

  @override
  void initState() {
    super.initState();
    final words = widget.insight.split(' ');
    _visible.addAll(List.filled(words.length, false));
    _revealWords();
  }

  Future<void> _revealWords() async {
    for (int i = 0; i < _visible.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (mounted) setState(() => _visible[i] = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.insight.split(' ');

    return Padding(
      padding: const EdgeInsets.all(SpendlerSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('YOUR WEEK IN WORDS', style: SpendlerTextStyles.sectionLabel),
          const SizedBox(height: SpendlerSpacing.xl),
          Wrap(
            spacing: 5,
            runSpacing: 6,
            children: words.asMap().entries.map((entry) {
              final i = entry.key;
              final word = entry.value;
              // Handle newlines in template
              if (word.contains('\n')) {
                final parts = word.split('\n');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: parts.map((p) {
                    return AnimatedOpacity(
                      opacity: i < _visible.length && _visible[i] ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        p,
                        style: const TextStyle(
                          color: SpendlerColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }
              return AnimatedOpacity(
                opacity: i < _visible.length && _visible[i] ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Text(
                  word,
                  style: const TextStyle(
                    color: SpendlerColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Card 4: The Poster ──────────────────────────────

class _Card4ThePoster extends ConsumerWidget {
  const _Card4ThePoster({
    required this.weekStart,
    required this.totalSpent,
    required this.catTotals,
  });

  final DateTime weekStart;
  final double totalSpent;
  final Map<String, double> catTotals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(SpendlerSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: WeeklySummaryPoster(
              weekStart: weekStart,
              totalSpent: totalSpent,
              categoryTotals: catTotals,
              dailyTotals: const [],
            ),
          ),
          const SizedBox(height: SpendlerSpacing.lg),
          NeoPOPButton(
            label: 'Share This Week',
            onTap: () async {
              await HapticFeedback.mediumImpact();
              if (!context.mounted) return;

              final poster = WeeklySummaryPoster(
                weekStart: weekStart,
                totalSpent: totalSpent,
                categoryTotals: catTotals,
                dailyTotals: const [],
              );
              final bytes = await PosterService.renderToPng(context, poster);
              if (bytes != null) {
                await PosterShare.share(bytes);
              }
            },
          ),
        ],
      ),
    );
  }
}

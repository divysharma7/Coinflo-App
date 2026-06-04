import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/header_section.dart';
import 'widgets/budget_progress_bar.dart';
import 'widgets/quick_stats_row.dart';
import 'widgets/recent_transactions_section.dart';

/// Home tab — a focused dashboard matching the CoinFlo Hi-Fi frame:
/// greeting header → dark budget hero → quick-stat tiles → recent activity.
/// Deeper detail (charts, category breakdown, goals) lives on the Report and
/// Plan tabs, so Home stays a glanceable summary.
///
/// NOTE: the sliver children are intentionally NOT wrapped in `flutter_animate`
/// (`.animate().fadeIn().slideY()`). Animating a `SliverToBoxAdapter`'s box
/// child with a delayed transform desyncs its paint offset from its layout
/// offset, causing later slivers (stats/recent) to paint at the viewport top
/// and overlap the header. Each section animates its own contents internally
/// instead, which is sliver-safe.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: HeaderSection()),
        SliverToBoxAdapter(child: BudgetProgressBar()),
        SliverToBoxAdapter(child: QuickStatsRow()),
        SliverToBoxAdapter(child: RecentTransactionsSection()),
        // Bottom breathing room for the FAB / bottom nav.
        SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

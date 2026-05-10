import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/pages/home/home_page.dart';
import 'package:finance_buddy_app/pages/analytics/analytics_page.dart';
import 'package:finance_buddy_app/pages/people/people_page.dart';
import 'package:finance_buddy_app/pages/my_page/my_page.dart';
import 'package:finance_buddy_app/pages/plan/plan_page.dart';
import 'package:finance_buddy_app/pages/add/quick_add_sheet.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

/// Shared navigation destination data used by both NavigationBar and NavigationRail.
class _Destination {
  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

final _destinations = [
  _Destination(icon: PhosphorIcons.house(), selectedIcon: PhosphorIconsFill.house, label: 'Home'),
  _Destination(icon: PhosphorIcons.money(), selectedIcon: PhosphorIconsFill.money, label: 'Transactions'),
  _Destination(icon: PhosphorIcons.usersThree(), selectedIcon: PhosphorIconsFill.usersThree, label: 'People'),
  _Destination(icon: PhosphorIcons.chartPieSlice(), selectedIcon: PhosphorIconsFill.chartPieSlice, label: 'Plan'),
  _Destination(icon: PhosphorIcons.user(), selectedIcon: PhosphorIconsFill.user, label: 'Me'),
];

class ShellPage extends ConsumerWidget {
  const ShellPage({super.key});

  // Pages indexed 0–5; index 2 is a FAB placeholder (kept for provider compat).
  static const _pages = [
    HomePage(),
    AnalyticsPage(),
    SizedBox.shrink(),
    PeoplePage(),
    PlanPage(),
    MyPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 600;

    return Scaffold(
      body: useRail
          ? Row(
              children: [
                NavigationRail(
                  backgroundColor: SpendlerColors.surface,
                  selectedIndex: selectedTab > 2 ? selectedTab - 1 : selectedTab,
                  onDestinationSelected: (i) {
                    final actualIndex = i >= 2 ? i + 1 : i;
                    ref.read(selectedTabProvider.notifier).state = actualIndex;
                  },
                  labelType: NavigationRailLabelType.all,
                  leading: FloatingActionButton(
                    onPressed: () => _onFabPressed(context, ref),
                    child: const Icon(Icons.add),
                  ),
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon, color: SpendlerColors.textTertiary),
                        selectedIcon: Icon(d.selectedIcon, color: SpendlerColors.primary),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: SpendlerColors.border),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: IndexedStack(
                        index: selectedTab,
                        children: _pages,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : IndexedStack(
              index: selectedTab,
              children: _pages,
            ),
      floatingActionButton: useRail
          ? null
          : SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                onPressed: () => _onFabPressed(context, ref),
                backgroundColor: SpendlerColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                child: const PhosphorIcon(PhosphorIconsBold.plus, size: 28),
              ),
            ),
      floatingActionButtonLocation:
          useRail ? null : FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: selectedTab > 2 ? selectedTab - 1 : selectedTab,
              onDestinationSelected: (i) {
                final actualIndex = i >= 2 ? i + 1 : i;
                ref.read(selectedTabProvider.notifier).state = actualIndex;
              },
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
    );
  }

  void _onFabPressed(BuildContext context, WidgetRef ref) {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) => const QuickAddSheet(),
    );
  }
}

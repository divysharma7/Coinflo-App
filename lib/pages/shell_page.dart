import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/pages/home/home_page.dart';
import 'package:finance_buddy_app/pages/analytics/analytics_page.dart';
import 'package:finance_buddy_app/pages/settings/settings_page.dart';
import 'package:finance_buddy_app/pages/add/quick_add_sheet.dart';
import 'package:finance_buddy_app/widgets/common/paisa_bottom_sheet.dart';

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
  _Destination(icon: PhosphorIcons.chartBar(), selectedIcon: PhosphorIconsFill.chartBar, label: 'Report'),
  _Destination(icon: PhosphorIcons.mapTrifold(), selectedIcon: PhosphorIconsFill.mapTrifold, label: 'Plan'),
  _Destination(icon: PhosphorIcons.gear(), selectedIcon: PhosphorIconsFill.gear, label: 'Settings'),
];

/// Placeholder for the Plan tab until a dedicated page is built.
class _PlanPlaceholder extends StatelessWidget {
  const _PlanPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(PhosphorIcons.mapTrifold(), size: 48, color: SpendlerColors.textTertiary),
          const SizedBox(height: SpendlerSpacing.md),
          Text('Budget plans coming soon', style: SpendlerTextStyles.emptyState),
        ],
      ),
    );
  }
}

class ShellPage extends ConsumerWidget {
  const ShellPage({super.key});

  // Pages indexed 0–4; index 2 is a FAB placeholder (kept for provider compat).
  static const _pages = [
    HomePage(),
    AnalyticsPage(),
    SizedBox.shrink(),
    _PlanPlaceholder(),
    SettingsPage(),
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
                  child: IndexedStack(
                    index: selectedTab,
                    children: _pages,
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
                elevation: 4,
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

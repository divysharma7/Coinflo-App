import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/pages/home/home_page.dart';
import 'package:finance_buddy_app/pages/transactions/transactions_page.dart';
import 'package:finance_buddy_app/pages/family/family_entry_sheet.dart';
import 'package:finance_buddy_app/pages/people/people_page.dart';
import 'package:finance_buddy_app/pages/people/friend_creation_sheet.dart';
import 'package:finance_buddy_app/pages/my_page/my_page.dart';
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
  _Destination(icon: PhosphorIcons.user(), selectedIcon: PhosphorIconsFill.user, label: 'Me'),
];

class ShellPage extends ConsumerWidget {
  const ShellPage({super.key});

  // Pages indexed 0–4; index 2 is a FAB placeholder (kept for provider compat).
  static const _pages = [
    HomePage(),
    TransactionsPage(),
    SizedBox.shrink(),
    PeoplePage(),
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
                  backgroundColor: SpendlerColors.scaffold,
                  selectedIndex: selectedTab > 2 ? selectedTab - 1 : selectedTab,
                  onDestinationSelected: (i) {
                    final actualIndex = i >= 2 ? i + 1 : i;
                    ref.read(selectedTabProvider.notifier).state = actualIndex;
                  },
                  labelType: NavigationRailLabelType.all,
                  leading: FloatingActionButton(
                    onPressed: () => _onFabPressed(context, ref, selectedTab),
                    child: const Icon(Icons.add),
                  ),
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon, color: SpendlerColors.textTertiary),
                        selectedIcon: Icon(d.selectedIcon, color: SpendlerColors.accentYellow),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: SpendlerColors.surfaceSecondary),
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
                onPressed: () => _onFabPressed(context, ref, selectedTab),
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

  void _onFabPressed(BuildContext context, WidgetRef ref, int selectedTab) {
    if (selectedTab == 3) {
      // People tab — show chooser with two tiles
      showSpendlerSheet<void>(
        context: context,
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PeopleActionTile(
              icon: PhosphorIcons.usersFour(),
              label: 'Add family entry',
              accentColor: SpendlerColors.gold,
              onTap: () {
                Navigator.pop(context);
                showSpendlerSheet<void>(
                  context: context,
                  builder: (_) => const FamilyEntrySheet(),
                );
              },
            ),
            const SizedBox(height: SpendlerSpacing.cardGap),
            _PeopleActionTile(
              icon: PhosphorIcons.userPlus(),
              label: 'Add a friend',
              accentColor: SpendlerColors.accentYellow,
              onTap: () {
                Navigator.pop(context);
                showSpendlerSheet<void>(
                  context: context,
                  builder: (_) => const FriendCreationSheet(),
                );
              },
            ),
          ],
        ),
      );
    } else {
      showSpendlerSheet<void>(
        context: context,
        builder: (_) => const QuickAddSheet(),
      );
    }
  }
}

/// A tappable tile used in the People tab FAB chooser.
class _PeopleActionTile extends StatelessWidget {
  const _PeopleActionTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpendlerSpacing.md,
          vertical: SpendlerSpacing.cardPadding,
        ),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(SpendlerRadii.card),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            PhosphorIcon(icon, size: 24, color: accentColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            PhosphorIcon(
              PhosphorIcons.caretRight(),
              size: 18,
              color: accentColor.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

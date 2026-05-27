import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/pages/home/home_page.dart';
import 'package:finance_buddy_app/pages/report/report_page.dart';
import 'package:finance_buddy_app/pages/plan/plan_page.dart';
import 'package:finance_buddy_app/pages/settings/settings_page.dart';
import 'package:finance_buddy_app/pages/add/quick_add_sheet.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

class ShellPage extends ConsumerWidget {
  const ShellPage({super.key});

  static const _pages = [
    HomePage(),     // 0
    ReportPage(),   // 1
    PlanPage(),     // 2
    SettingsPage(), // 3
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    // Clamp to valid range for 4-tab layout
    final safeIndex = selectedTab.clamp(0, 3);

    // Tabs 0 (Home) and 2 (Plan) have dark headers → light (white) status bar icons.
    // Tabs 1 (Report) and 3 (Settings) have light backgrounds → dark status bar icons.
    final isDarkHeader = safeIndex == 0 || safeIndex == 2;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkHeader ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: IndexedStack(
          index: safeIndex,
          children: _pages,
        ),
        floatingActionButton: SizedBox(
          width: 56,
          height: 56,
          child: FloatingActionButton(
            onPressed: () => _onFabPressed(context),
            backgroundColor: AppColors.black,
            foregroundColor: AppColors.white,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 28),
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AppBottomTabBar(
          currentIndex: safeIndex,
          onTap: (i) =>
              ref.read(selectedTabProvider.notifier).state = i,
        ),
      ),
    );
  }

  void _onFabPressed(BuildContext context) {
    showSpendlerSheet<void>(
      context: context,
      builder: (_) => const QuickAddSheet(),
    );
  }
}

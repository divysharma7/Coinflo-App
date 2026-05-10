import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/pages/splash/splash_page.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/currency_selection_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/add_accounts_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/monthly_budget_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/category_budgets_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/categories_overview_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/track_income_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/smart_rules_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/savings_goals_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/recurring_payments_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/stay_on_track_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/completion_screen.dart';

class SpendlerApp extends StatelessWidget {
  const SpendlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return ProviderScope(
      child: MaterialApp(
        title: 'Spendler',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        theme: ThemeData.light(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: AppColors.offWhite,
          colorScheme: const ColorScheme.light(
            surface: AppColors.white,
            primary: AppColors.black,
            onPrimary: AppColors.white,
            error: AppColors.red,
            onSurface: AppColors.black,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.offWhite,
            foregroundColor: AppColors.black,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
            ),
            dragHandleColor: AppColors.gray300,
            dragHandleSize: Size(36, 4),
            showDragHandle: true,
          ),
          dividerTheme: const DividerThemeData(
            color: AppColors.gray200,
            thickness: 1,
            space: 0,
          ),
        ),
        darkTheme: ThemeData.light(useMaterial3: true),
        home: const SplashPage(),
        routes: {
          '/onboarding/step1': (_) => const CurrencySelectionScreen(),
          '/onboarding/step2': (_) => const AddAccountsScreen(),
          '/onboarding/step3': (_) => const MonthlyBudgetScreen(),
          '/onboarding/step4': (_) => const CategoryBudgetsScreen(),
          '/onboarding/step5': (_) => const CategoriesOverviewScreen(),
          '/onboarding/step6': (_) => const TrackIncomeScreen(),
          '/onboarding/step7': (_) => const SmartRulesScreen(),
          '/onboarding/step8': (_) => const SavingsGoalsScreen(),
          '/onboarding/step9': (_) => const RecurringPaymentsScreen(),
          '/onboarding/step10': (_) => const StayOnTrackScreen(),
          '/onboarding/complete': (_) => const CompletionScreen(),
        },
      ),
    );
  }
}

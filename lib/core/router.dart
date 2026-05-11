import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import 'package:finance_buddy_app/pages/auth/sign_in_screen.dart';
import 'package:finance_buddy_app/pages/shell_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // ─── Splash ───────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),

      // ─── Onboarding flow ─────────────────────────────
      GoRoute(
        path: '/onboarding/step1',
        builder: (context, state) => const CurrencySelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/step2',
        builder: (context, state) => const AddAccountsScreen(),
      ),
      GoRoute(
        path: '/onboarding/step3',
        builder: (context, state) => const MonthlyBudgetScreen(),
      ),
      GoRoute(
        path: '/onboarding/step4',
        builder: (context, state) => const CategoryBudgetsScreen(),
      ),
      GoRoute(
        path: '/onboarding/step5',
        builder: (context, state) => const CategoriesOverviewScreen(),
      ),
      GoRoute(
        path: '/onboarding/step6',
        builder: (context, state) => const TrackIncomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/step7',
        builder: (context, state) => const SmartRulesScreen(),
      ),
      GoRoute(
        path: '/onboarding/step8',
        builder: (context, state) => const SavingsGoalsScreen(),
      ),
      GoRoute(
        path: '/onboarding/step9',
        builder: (context, state) => const RecurringPaymentsScreen(),
      ),
      GoRoute(
        path: '/onboarding/step10',
        builder: (context, state) => const StayOnTrackScreen(),
      ),
      GoRoute(
        path: '/onboarding/complete',
        builder: (context, state) => const CompletionScreen(),
      ),

      // ─── Auth ──────────────────────────────────────────
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),

      // ─── Main app ────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (context, state) => const ShellPage(),
      ),
    ],
  );
});

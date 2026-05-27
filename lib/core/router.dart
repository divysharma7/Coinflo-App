import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/services/auth/auth_service.dart';
import 'package:finance_buddy_app/pages/splash/splash_page.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/add_accounts_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/monthly_budget_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/category_budgets_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/categories_overview_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/track_income_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/savings_goals_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/recurring_payments_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/stay_on_track_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/completion_screen.dart';
import 'package:finance_buddy_app/pages/auth/sign_in_screen.dart';
import 'package:finance_buddy_app/pages/shell_page.dart';
import 'package:finance_buddy_app/pages/report/category_transactions_page.dart';
import 'package:finance_buddy_app/pages/settings/excel_import_page.dart';
import 'package:finance_buddy_app/pages/saraswati/saraswati_page.dart';
import 'package:finance_buddy_app/pages/people/people_page.dart';
import 'package:finance_buddy_app/pages/people/person_detail_page.dart';
import 'package:finance_buddy_app/pages/groups/groups_page.dart';
import 'package:finance_buddy_app/pages/groups/group_detail_page.dart';
import 'package:finance_buddy_app/pages/subscriptions/subscriptions_page.dart';
import 'package:finance_buddy_app/pages/transactions/transaction_detail_page.dart';
import 'package:finance_buddy_app/pages/home/daily_view_page.dart';
import 'package:finance_buddy_app/pages/transactions/attachment_viewer_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final path = state.matchedLocation;

      // Allow splash, onboarding, and sign-in without auth
      if (path == '/splash' ||
          path.startsWith('/onboarding') ||
          path == '/sign-in') {
        return null;
      }

      // Check if user is authenticated
      final authService = AuthService();
      final isReturning = await authService.isReturningUser();
      if (!isReturning) return '/sign-in';

      // Check if onboarding is completed
      final prefs = await SharedPreferences.getInstance();
      final onboarded = prefs.getBool('onboarding_completed') ?? false;
      if (!onboarded) return '/onboarding/step2';

      return null;
    },
    routes: [
      // ─── Splash ───────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),

      // ─── Onboarding flow ─────────────────────────────
      // step1 (currency selection) removed — locked to INR for v1
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
        builder: (context, state) => const SavingsGoalsScreen(),
      ),
      GoRoute(
        path: '/onboarding/step8',
        builder: (context, state) => const RecurringPaymentsScreen(),
      ),
      GoRoute(
        path: '/onboarding/step9',
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

      // ─── Report drill-down ────────────────────────────
      GoRoute(
        path: '/report/category',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CategoryTransactionsPage(
            categoryName: extra['category'] as String,
            month: extra['month'] as DateTime,
          );
        },
      ),

      // ─── Settings sub-pages ───────────────────────────
      GoRoute(
        path: '/settings/saraswati',
        builder: (context, state) => const SaraswatiPage(),
      ),
      GoRoute(
        path: '/settings/people',
        builder: (context, state) => const PeoplePage(),
      ),
      GoRoute(
        path: '/people/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PersonDetailPage(personId: id);
        },
      ),
      GoRoute(
        path: '/settings/subscriptions',
        builder: (context, state) => const SubscriptionsPage(),
      ),
      GoRoute(
        path: '/settings/excel-import',
        builder: (context, state) => const ExcelImportPage(),
      ),

      // ─── Transaction pages ─────────────────────────────
      GoRoute(
        path: '/transaction/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final extra = state.extra;
          final editMode = extra is Map<String, dynamic> &&
              extra['startInEditMode'] == true;
          return TransactionDetailPage(
            transactionId: id,
            startInEditMode: editMode,
          );
        },
      ),
      GoRoute(
        path: '/daily-view',
        builder: (context, state) {
          final date = state.extra as DateTime;
          return DailyViewPage(date: date);
        },
      ),
      GoRoute(
        path: '/attachment-viewer',
        builder: (context, state) {
          final filePath = state.extra as String;
          return AttachmentViewerPage(filePath: filePath);
        },
      ),

      // ─── Groups ─────────────────────────────────────
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupsPage(),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return GroupDetailPage(groupId: id);
        },
      ),

      // ─── Main app ────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (context, state) => const ShellPage(),
      ),
    ],
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/services/auth/auth_service.dart';
import 'package:finance_buddy_app/pages/splash/splash_page.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/welcome_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/currency_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/add_accounts_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/categories_overview_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/monthly_budget_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/category_budgets_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/savings_goals_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/stay_on_track_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/recap_screen.dart';
import 'package:finance_buddy_app/pages/onboarding_v2/completion_screen.dart';
import 'package:finance_buddy_app/pages/auth/sign_in_screen.dart';
import 'package:finance_buddy_app/pages/auth/hydration_loading_page.dart';
import 'package:finance_buddy_app/pages/shell_page.dart';
import 'package:finance_buddy_app/pages/report/category_transactions_page.dart';
import 'package:finance_buddy_app/pages/settings/excel_import_page.dart';
import 'package:finance_buddy_app/pages/saraswati/saraswati_page.dart';
import 'package:finance_buddy_app/pages/people/people_page.dart';
import 'package:finance_buddy_app/pages/people/person_detail_page.dart';
import 'package:finance_buddy_app/pages/groups/groups_page.dart';
import 'package:finance_buddy_app/pages/groups/group_detail_page.dart';
import 'package:finance_buddy_app/pages/subscriptions/subscriptions_page.dart';
import 'package:finance_buddy_app/pages/accounts/accounts_page.dart';
import 'package:finance_buddy_app/pages/notifications/notifications_page.dart';
import 'package:finance_buddy_app/pages/transactions/transaction_detail_page.dart';
import 'package:finance_buddy_app/pages/transactions/transactions_page.dart';
import 'package:finance_buddy_app/pages/home/daily_view_page.dart';
import 'package:finance_buddy_app/pages/transactions/attachment_viewer_page.dart';
import 'package:finance_buddy_app/pages/errors/route_error_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) => const RouteErrorPage(),
    redirect: (context, state) async {
      final path = state.matchedLocation;

      // Allow splash, onboarding, sign-in, and the post-sign-in hydration
      // screen without the onboarded/auth gate.
      if (path == '/splash' ||
          path.startsWith('/onboarding') ||
          path == '/sign-in' ||
          path == '/hydration') {
        return null;
      }

      // Local-first gate: a completed onboarding (via account creation OR the
      // "Maybe later" skip) is enough to use the app — no account required.
      final prefs = await SharedPreferences.getInstance();
      final onboarded = prefs.getBool('onboarding_completed') ?? false;
      if (onboarded) return null;

      // Returning users (with a stored auth token) can proceed as well.
      final authService = AuthService();
      if (await authService.isReturningUser()) return null;

      // Otherwise, start at the welcome screen.
      return '/onboarding/welcome';
    },
    routes: [
      // ─── Splash ───────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),

      // ─── Onboarding flow (re-sequenced) ──────────────
      // Welcome → Currency → Accounts → Categories → Budget(opt) →
      // Goals(opt) → Reminders → Recap → Create account(opt)
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/currency',
        builder: (context, state) => const CurrencyScreen(),
      ),
      GoRoute(
        path: '/onboarding/accounts',
        builder: (context, state) => const AddAccountsScreen(),
      ),
      GoRoute(
        path: '/onboarding/categories',
        builder: (context, state) => const CategoriesOverviewScreen(),
      ),
      GoRoute(
        path: '/onboarding/budget',
        builder: (context, state) => const MonthlyBudgetScreen(),
      ),
      // Optional sub-page reached from the Budget screen (pops back).
      GoRoute(
        path: '/onboarding/budget/categories',
        builder: (context, state) => const CategoryBudgetsScreen(),
      ),
      GoRoute(
        path: '/onboarding/goals',
        builder: (context, state) => const SavingsGoalsScreen(),
      ),
      GoRoute(
        path: '/onboarding/reminders',
        builder: (context, state) => const StayOnTrackScreen(),
      ),
      GoRoute(
        path: '/onboarding/recap',
        builder: (context, state) => const RecapScreen(),
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
      GoRoute(
        path: '/hydration',
        builder: (context, state) {
          final uid = state.extra as String? ?? '';
          return HydrationLoadingPage(uid: uid);
        },
      ),

      // ─── Report drill-down ────────────────────────────
      GoRoute(
        path: '/report/category',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final categoryName = extra?['category'] as String?;
          final month = extra?['month'] as DateTime?;
          if (extra == null || categoryName == null || month == null) {
            return const RouteErrorPage(message: 'Page not found');
          }
          return CategoryTransactionsPage(
            categoryName: categoryName,
            month: month,
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
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const RouteErrorPage(message: 'Page not found');
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
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountsPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      // ─── Transaction pages ─────────────────────────────
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionsPage(),
      ),
      GoRoute(
        path: '/transaction/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const RouteErrorPage(message: 'Page not found');
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
          // Fall back to today when extra is missing (e.g. process-death
          // restoration, where GoRouter restores the path but not `extra`).
          final date = state.extra as DateTime? ?? DateTime.now();
          return DailyViewPage(date: date);
        },
      ),
      GoRoute(
        path: '/attachment-viewer',
        builder: (context, state) {
          final filePath = state.extra as String?;
          if (filePath == null || filePath.isEmpty) {
            return const RouteErrorPage(message: 'Attachment not found');
          }
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
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const RouteErrorPage(message: 'Page not found');
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

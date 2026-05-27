import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/pages/report/report_page.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/data/db.dart';

/// Minimal mock repository that returns empty data for report queries.
class MockRepository implements BaseRepository {
  @override
  Future<List<SpendlerTransaction>> getTransactionsForMonth(
      DateTime month) async {
    return [];
  }

  @override
  Future<Map<String, double>> getCategoryTotalsForMonth(
      DateTime month) async {
    return {};
  }

  @override
  Future<List<double>> getWeeklySpendingTrend(int weekCount) async {
    return List.filled(weekCount, 0);
  }

  @override
  Future<List<double>> getCumulativeSpendingForMonth(DateTime month) async {
    return [];
  }

  @override
  Future<Map<String, List<double>>> getMonthlyComparison() async {
    return {};
  }

  @override
  Future<int> getStreakWeeksUnderTarget(double target) async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      '${invocation.memberName} not mocked');
}

void main() {
  late MockRepository mockRepo;

  setUp(() {
    mockRepo = MockRepository();
  });

  Widget buildWidget() {
    return ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(mockRepo),
        selectedCurrencyProvider.overrideWith((_) async => 'inr'),
        monthlyBudgetProvider.overrideWith((_) async => null),
      ],
      child: const MaterialApp(
        home: ReportPage(),
      ),
    );
  }

  group('ReportPage', () {
    testWidgets('renders Report header title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Report'), findsOneWidget);
    });

    testWidgets('renders scope selector with Week, Month, Year',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);
    });

    testWidgets('renders period navigation arrows', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders month label in period navigator', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      final expectedLabel = '${months[now.month - 1]} ${now.year}';
      expect(find.text(expectedLabel), findsOneWidget);
    });
  });
}

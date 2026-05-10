import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/pages/report/report_page.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
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
      ],
      child: const MaterialApp(
        home: ReportPage(),
      ),
    );
  }

  group('ReportPage', () {
    testWidgets('renders Monthly Report header title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('Monthly Report'), findsOneWidget);
    });

    testWidgets('renders scope selector with Week, Month, Year',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);
    });

    testWidgets('renders period navigation with left and right arrows',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders month label in period navigator', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Default scope is month, so should show current month
      final now = DateTime.now();
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      final expectedLabel = '${months[now.month - 1]} ${now.year}';
      expect(find.text(expectedLabel), findsOneWidget);
    });

    testWidgets('shows summary cards (Income, Expenses, Net) when data loads',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Net'), findsOneWidget);
    });

    testWidgets('shows empty state when no data', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('No data for this month.'), findsOneWidget);
    });

    testWidgets('back arrow icon exists for navigation', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('summary cards show \$0 amounts when no transactions',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // With no transactions, all amounts should be $0
      expect(find.text('\$0'), findsNWidgets(3));
    });
  });
}

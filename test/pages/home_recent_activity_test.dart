import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/local/local_repository.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/pages/home/widgets/recent_transactions_section.dart';

/// Ground-truth triage for "transactions don't show on Home".
void main() {
  late SpendlerDatabase db;

  Future<void> seed() async {
    final now = DateTime.now();
    await db.into(db.spendlerTransactions).insert(
          SpendlerTransactionsCompanion.insert(
            amount: -420,
            category: 'foodAndDrink',
            merchant: const drift.Value('Swiggy'),
            happenedAt: drift.Value(now),
            status: const drift.Value('confirmed'),
          ),
        );
    await db.into(db.spendlerTransactions).insert(
          SpendlerTransactionsCompanion.insert(
            amount: 85000,
            category: 'income',
            merchant: const drift.Value('Acme Corp'),
            happenedAt: drift.Value(now),
            status: const drift.Value('confirmed'),
          ),
        );
    await db.into(db.spendlerTransactions).insert(
          SpendlerTransactionsCompanion.insert(
            amount: -1899,
            category: 'shopping',
            merchant: const drift.Value('Amazon'),
            happenedAt: drift.Value(DateTime(now.year, now.month - 1, 15)),
            status: const drift.Value('confirmed'),
          ),
        );
  }

  setUp(() async {
    db = SpendlerDatabase.forTesting(NativeDatabase.memory());
    await seed();
  });
  tearDown(() async => db.close());

  // DATA LAYER: does the exact stream Recent Activity uses return rows?
  test('repo.watchAll() emits the 3 seeded transactions', () async {
    final repo = LocalRepository(db);
    final rows = await repo.watchAll().first.timeout(const Duration(seconds: 5));
    expect(rows.length, 3);
    expect(rows.map((t) => t.merchant), containsAll(['Swiggy', 'Acme Corp', 'Amazon']));
  });

  // RENDER LAYER: does the widget paint rows without throwing? Uses pump (not
  // pumpAndSettle) so the infinite loading spinner can't hang the test.
  testWidgets('RecentTransactionsSection renders rows', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: RecentTransactionsSection()),
          ),
        ),
      ),
    );
    // Let the Drift stream deliver its first event (a few frames, no settle).
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final ex = tester.takeException();
    expect(ex, isNull, reason: 'Widget threw during build: $ex');
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Swiggy'), findsOneWidget);
    expect(find.text('Amazon'), findsOneWidget);
  });
}

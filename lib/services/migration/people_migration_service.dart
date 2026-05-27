import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';

/// Migrates legacy Friends/Family data to the unified People & Debts model.
class PeopleMigrationService {
  final SpendlerDatabase db;
  PeopleMigrationService(this.db);

  Future<void> migrate() async {
    await db.transaction(() async {
      await _migrateFriendContacts();
      await _migrateFriendSplits();
    });
  }

  Future<void> _migrateFriendContacts() async {
    final contacts = await db.select(db.friendContacts).get();
    for (final c in contacts) {
      final existing = await (db.select(db.persons)
            ..where((p) => p.name.equals(c.name))
            ..limit(1))
          .getSingleOrNull();
      if (existing != null) continue;

      await db.into(db.persons).insert(PersonsCompanion(
        name: Value(c.name),
        tag: const Value('friend'),
        avatarColor: Value(c.avatarColour),
        note: Value(c.note),
      ));
    }
  }

  Future<void> _migrateFriendSplits() async {
    final splits = await db.select(db.friendSplits).get();
    if (splits.isEmpty) return;

    final contacts = await db.select(db.friendContacts).get();
    final persons = await db.select(db.persons).get();
    final nameToPersonId = <String, int>{};
    for (final p in persons) {
      nameToPersonId[p.name] = p.id;
    }
    final friendIdToPersonId = <int, int>{};
    for (final c in contacts) {
      final pid = nameToPersonId[c.name];
      if (pid != null) friendIdToPersonId[c.id] = pid;
    }

    for (final s in splits) {
      final personId = friendIdToPersonId[s.friendContactId];
      if (personId == null) continue;

      var txnId = s.transactionId;

      if (txnId == 0) {
        txnId = await db.into(db.spendlerTransactions).insert(
          SpendlerTransactionsCompanion(
            amount: Value(-s.amount),
            category: const Value('other'),
            txnType: const Value('expense'),
            source: const Value('migration'),
            status: const Value('confirmed'),
            note: const Value('Migrated from legacy split'),
            happenedAt: Value(s.createdAt),
          ),
        );
      }

      if (s.direction == 'they_owe_me') {
        await db.into(db.transactionSplits).insert(
          TransactionSplitsCompanion(
            transactionId: Value(txnId),
            personId: Value(personId),
            shareAmount: Value(s.amount),
          ),
        );
      } else {
        await db.into(db.transactionSplits).insert(
          TransactionSplitsCompanion(
            transactionId: Value(txnId),
            personId: const Value.absent(),
            shareAmount: Value(s.amount),
          ),
        );
      }
    }
  }
}

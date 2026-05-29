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
      await _migrateFamilyEntries();
      await _createFamilyGroupIfNeeded();
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

      // Create synthetic transaction if orphaned (id=0 or missing)
      final txnExists = txnId > 0
          ? await (db.select(db.spendlerTransactions)
                ..where((t) => t.id.equals(txnId)))
              .getSingleOrNull()
          : null;

      if (txnId == 0 || txnExists == null) {
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

  Future<void> _migrateFamilyEntries() async {
    final entries = await db.select(db.familyEntries).get();
    if (entries.isEmpty) return;

    // Ensure each fromPerson exists in Persons table with tag='family'
    final existingPersons = await db.select(db.persons).get();
    final existingNames = existingPersons.map((p) => p.name).toSet();

    for (final e in entries) {
      if (!existingNames.contains(e.fromPerson)) {
        await db.into(db.persons).insert(PersonsCompanion(
          name: Value(e.fromPerson),
          tag: const Value('family'),
          avatarColor: const Value('6B7280'),
          note: const Value('Migrated from family entries'),
        ));
        existingNames.add(e.fromPerson);
      }
    }

    // Convert entries to transactions
    for (final e in entries) {
      final txnType = e.type == 'inflow' ? 'income' : 'transfer';
      final category = e.type == 'inflow' ? 'income' : 'transfer';
      await db.into(db.spendlerTransactions).insert(
        SpendlerTransactionsCompanion(
          amount: Value(e.amount),
          category: Value(category),
          txnType: Value(txnType),
          source: const Value('migration'),
          status: const Value('confirmed'),
          note: Value(e.note ?? 'From ${e.fromPerson}'),
          happenedAt: Value(e.happenedAt),
          incomeSource: e.type == 'inflow'
              ? const Value('gift')
              : Value(e.investmentType),
        ),
      );
    }
  }

  Future<void> _createFamilyGroupIfNeeded() async {
    final familyPersons = await (db.select(db.persons)
          ..where((p) => p.tag.equals('family')))
        .get();

    if (familyPersons.length < 2) return;

    // Check if a "Family" group already exists
    final existing = await (db.select(db.groups)
          ..where((g) => g.name.equals('Family'))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return;

    final groupId = await db.into(db.groups).insert(GroupsCompanion(
      name: const Value('Family'),
      description: const Value('Auto-created from legacy family entries'),
    ));

    for (final p in familyPersons) {
      await db.into(db.groupMembers).insert(GroupMembersCompanion(
        groupId: Value(groupId),
        personId: Value(p.id),
      ));
    }
  }
}

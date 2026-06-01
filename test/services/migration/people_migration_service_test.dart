import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/services/migration/people_migration_service.dart';

/// In-memory database for testing the people-data migration.
SpendlerDatabase _openTestDb() {
  return SpendlerDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  group('PeopleMigrationService', () {
    late SpendlerDatabase db;
    late PeopleMigrationService service;

    setUp(() {
      db = _openTestDb();
      service = PeopleMigrationService(db);
    });

    tearDown(() async {
      await db.close();
    });

    // ── (1) FriendContacts → Persons ────────────────────────────────
    group('FriendContacts → Persons', () {
      test('preserves name, avatar colour, and note with friend tag',
          () async {
        await db.into(db.friendContacts).insert(
              FriendContactsCompanion.insert(
                name: 'Alice',
                avatarColour: 'FF5733',
                note: const Value('college roommate'),
              ),
            );

        await service.migrate();

        final persons = await db.select(db.persons).get();
        expect(persons, hasLength(1));

        final alice = persons.single;
        expect(alice.name, 'Alice');
        expect(alice.avatarColor, 'FF5733'); // avatarColour → avatarColor
        expect(alice.note, 'college roommate');
        expect(alice.tag, 'friend');
      });

      test('migrates multiple contacts into distinct persons', () async {
        await db.into(db.friendContacts).insert(
              FriendContactsCompanion.insert(
                name: 'Bob',
                avatarColour: '00FF00',
              ),
            );
        await db.into(db.friendContacts).insert(
              FriendContactsCompanion.insert(
                name: 'Carol',
                avatarColour: '0000FF',
              ),
            );

        await service.migrate();

        final names =
            (await db.select(db.persons).get()).map((p) => p.name).toSet();
        expect(names, {'Bob', 'Carol'});
      });

      test('does not duplicate a contact whose name already exists as a person',
          () async {
        // Pre-existing person with the same name as the legacy contact.
        await db.into(db.persons).insert(
              PersonsCompanion.insert(
                name: 'Dave',
                avatarColor: 'AAAAAA',
                tag: const Value('colleague'),
              ),
            );
        await db.into(db.friendContacts).insert(
              FriendContactsCompanion.insert(
                name: 'Dave',
                avatarColour: 'BBBBBB',
              ),
            );

        await service.migrate();

        final daves = await (db.select(db.persons)
              ..where((p) => p.name.equals('Dave')))
            .get();
        expect(daves, hasLength(1));
        // Existing person is left untouched (no overwrite).
        expect(daves.single.tag, 'colleague');
        expect(daves.single.avatarColor, 'AAAAAA');
      });
    });

    // ── (2) FriendSplits → TransactionSplits ────────────────────────
    group('FriendSplits → TransactionSplits', () {
      test('creates split with correct shareAmount and personId linkage '
          'for they_owe_me', () async {
        await db.into(db.friendContacts).insert(
              FriendContactsCompanion.insert(
                name: 'Eve',
                avatarColour: '123456',
              ),
            );
        final txnId = await db.into(db.spendlerTransactions).insert(
              SpendlerTransactionsCompanion.insert(
                amount: -400.0,
                category: 'foodAndDrink',
              ),
            );
        await db.into(db.friendSplits).insert(
              FriendSplitsCompanion.insert(
                transactionId: txnId,
                friendContactId: 1, // Eve is the only contact → id 1
                amount: 200.0,
                direction: 'they_owe_me',
              ),
            );

        await service.migrate();

        final eve = (await db.select(db.persons).get()).single;
        final splits = await db.select(db.transactionSplits).get();
        expect(splits, hasLength(1));

        final split = splits.single;
        expect(split.shareAmount, 200.0);
        expect(split.personId, eve.id); // linked to the migrated person
        expect(split.transactionId, txnId); // reuses the existing transaction
      });

      test('they_owe_me reuses existing transaction without creating a new one',
          () async {
        await db.into(db.friendContacts).insert(
              FriendContactsCompanion.insert(
                name: 'Frank',
                avatarColour: 'ABCDEF',
              ),
            );
        final txnId = await db.into(db.spendlerTransactions).insert(
              SpendlerTransactionsCompanion.insert(
                amount: -150.0,
                category: 'shopping',
              ),
            );
        await db.into(db.friendSplits).insert(
              FriendSplitsCompanion.insert(
                transactionId: txnId,
                friendContactId: 1,
                amount: 75.0,
                direction: 'they_owe_me',
              ),
            );

        await service.migrate();

        // Only the originally-seeded transaction should remain — no synthetic
        // transaction created because the referenced txn exists.
        final txns = await db.select(db.spendlerTransactions).get();
        expect(txns, hasLength(1));
        expect(txns.single.id, txnId);
      });

      test('i_owe_them split leaves personId null (user own share)', () async {
        await db.into(db.friendContacts).insert(
              FriendContactsCompanion.insert(
                name: 'Grace',
                avatarColour: '654321',
              ),
            );
        final txnId = await db.into(db.spendlerTransactions).insert(
              SpendlerTransactionsCompanion.insert(
                amount: -300.0,
                category: 'transport',
              ),
            );
        await db.into(db.friendSplits).insert(
              FriendSplitsCompanion.insert(
                transactionId: txnId,
                friendContactId: 1,
                amount: 120.0,
                direction: 'i_owe_them',
              ),
            );

        await service.migrate();

        final split = (await db.select(db.transactionSplits).get()).single;
        expect(split.shareAmount, 120.0);
        expect(split.personId, isNull); // Value.absent() → null
      });
    });

    // ── (3) Orphan detection ────────────────────────────────────────
    group('orphan detection', () {
      test('split whose contact is missing is skipped, not crashing', () async {
        // FriendSplit references a contact that does not exist.
        await db.into(db.friendSplits).insert(
              FriendSplitsCompanion.insert(
                transactionId: 1,
                friendContactId: 999, // no such contact
                amount: 50.0,
                direction: 'they_owe_me',
              ),
            );

        await service.migrate(); // must not throw

        final splits = await db.select(db.transactionSplits).get();
        expect(splits, isEmpty); // orphaned contact → split skipped
      });

      test('split whose transaction is missing gets a synthetic transaction',
          () async {
        await db.into(db.friendContacts).insert(
              FriendContactsCompanion.insert(
                name: 'Heidi',
                avatarColour: 'FEDCBA',
              ),
            );
        // transactionId points at a non-existent transaction row.
        await db.into(db.friendSplits).insert(
              FriendSplitsCompanion.insert(
                transactionId: 12345, // missing transaction
                friendContactId: 1,
                amount: 90.0,
                direction: 'they_owe_me',
              ),
            );

        await service.migrate(); // must not throw

        // A synthetic migration transaction must have been created.
        final txns = await db.select(db.spendlerTransactions).get();
        expect(txns, hasLength(1));
        final synthetic = txns.single;
        expect(synthetic.source, 'migration');
        expect(synthetic.amount, -90.0); // negative => expense
        expect(synthetic.txnType, 'expense');

        final split = (await db.select(db.transactionSplits).get()).single;
        expect(split.transactionId, synthetic.id);
        expect(split.shareAmount, 90.0);
      });

      test('split with transactionId 0 gets a synthetic transaction', () async {
        await db.into(db.friendContacts).insert(
              FriendContactsCompanion.insert(
                name: 'Ivan',
                avatarColour: '111111',
              ),
            );
        await db.into(db.friendSplits).insert(
              FriendSplitsCompanion.insert(
                transactionId: 0, // sentinel for "no transaction"
                friendContactId: 1,
                amount: 60.0,
                direction: 'they_owe_me',
              ),
            );

        await service.migrate();

        final txns = await db.select(db.spendlerTransactions).get();
        expect(txns, hasLength(1));
        expect(txns.single.source, 'migration');

        final split = (await db.select(db.transactionSplits).get()).single;
        expect(split.transactionId, txns.single.id);
      });
    });

    // ── (4) FamilyEntries → Transactions ────────────────────────────
    group('FamilyEntries → Transactions', () {
      test('inflow entry becomes an income transaction with gift source',
          () async {
        await db.into(db.familyEntries).insert(
              FamilyEntriesCompanion.insert(
                type: 'inflow',
                amount: 5000.0,
                fromPerson: 'Mom',
                note: const Value('birthday gift'),
              ),
            );

        await service.migrate();

        final txns = await (db.select(db.spendlerTransactions)
              ..where((t) => t.source.equals('migration')))
            .get();
        expect(txns, hasLength(1));

        final txn = txns.single;
        expect(txn.amount, 5000.0);
        expect(txn.category, 'income');
        expect(txn.txnType, 'income');
        expect(txn.incomeSource, 'gift');
        expect(txn.note, 'birthday gift');
        expect(txn.status, 'confirmed');
      });

      test('investment entry becomes a transfer transaction with investment '
          'type as income source', () async {
        await db.into(db.familyEntries).insert(
              FamilyEntriesCompanion.insert(
                type: 'investment',
                amount: 10000.0,
                fromPerson: 'Dad',
                investmentType: const Value('MF'),
              ),
            );

        await service.migrate();

        final txns = await (db.select(db.spendlerTransactions)
              ..where((t) => t.source.equals('migration')))
            .get();
        expect(txns, hasLength(1));

        final txn = txns.single;
        expect(txn.amount, 10000.0);
        expect(txn.category, 'transfer');
        expect(txn.txnType, 'transfer');
        expect(txn.incomeSource, 'MF'); // investmentType carried over
      });

      test('creates a family-tagged person for each distinct fromPerson',
          () async {
        await db.into(db.familyEntries).insert(
              FamilyEntriesCompanion.insert(
                type: 'inflow',
                amount: 1000.0,
                fromPerson: 'Mom',
              ),
            );
        await db.into(db.familyEntries).insert(
              FamilyEntriesCompanion.insert(
                type: 'inflow',
                amount: 2000.0,
                fromPerson: 'Mom', // duplicate name → single person
              ),
            );
        await db.into(db.familyEntries).insert(
              FamilyEntriesCompanion.insert(
                type: 'investment',
                amount: 3000.0,
                fromPerson: 'Dad',
              ),
            );

        await service.migrate();

        final family = await (db.select(db.persons)
              ..where((p) => p.tag.equals('family')))
            .get();
        final names = family.map((p) => p.name).toSet();
        expect(names, {'Mom', 'Dad'}); // de-duplicated by name
        expect(family.every((p) => p.tag == 'family'), isTrue);
      });
    });

    // ── (5) Auto-creation of the "Family" group + members ───────────
    group('Family group auto-creation', () {
      test('creates a Family group with all family persons as members '
          'when at least two exist', () async {
        await db.into(db.familyEntries).insert(
              FamilyEntriesCompanion.insert(
                type: 'inflow',
                amount: 1000.0,
                fromPerson: 'Mom',
              ),
            );
        await db.into(db.familyEntries).insert(
              FamilyEntriesCompanion.insert(
                type: 'investment',
                amount: 2000.0,
                fromPerson: 'Dad',
              ),
            );

        await service.migrate();

        final groups = await (db.select(db.groups)
              ..where((g) => g.name.equals('Family')))
            .get();
        expect(groups, hasLength(1));

        final members = await (db.select(db.groupMembers)
              ..where((m) => m.groupId.equals(groups.single.id)))
            .get();
        final familyPersons = await (db.select(db.persons)
              ..where((p) => p.tag.equals('family')))
            .get();
        expect(members, hasLength(familyPersons.length));
        expect(members, hasLength(2));

        final memberPersonIds = members.map((m) => m.personId).toSet();
        final familyPersonIds = familyPersons.map((p) => p.id).toSet();
        expect(memberPersonIds, familyPersonIds);
      });

      test('does not create a Family group when fewer than two family persons',
          () async {
        await db.into(db.familyEntries).insert(
              FamilyEntriesCompanion.insert(
                type: 'inflow',
                amount: 1000.0,
                fromPerson: 'Mom', // only one family person
              ),
            );

        await service.migrate();

        final groups = await (db.select(db.groups)
              ..where((g) => g.name.equals('Family')))
            .get();
        expect(groups, isEmpty);
        expect(await db.select(db.groupMembers).get(), isEmpty);
      });
    });

    // ── (6) Idempotency / no double-migration ───────────────────────
    group('idempotency', () {
      test('running migration twice does not duplicate persons or groups',
          () async {
        await db.into(db.friendContacts).insert(
              FriendContactsCompanion.insert(
                name: 'Judy',
                avatarColour: 'C0FFEE',
              ),
            );
        await db.into(db.familyEntries).insert(
              FamilyEntriesCompanion.insert(
                type: 'inflow',
                amount: 1000.0,
                fromPerson: 'Mom',
              ),
            );
        await db.into(db.familyEntries).insert(
              FamilyEntriesCompanion.insert(
                type: 'investment',
                amount: 2000.0,
                fromPerson: 'Dad',
              ),
            );

        await service.migrate();

        final personsAfterFirst =
            (await db.select(db.persons).get()).map((p) => p.name).toList()
              ..sort();
        final groupsAfterFirst = await db.select(db.groups).get();

        // Second run must not create duplicate persons or a second group.
        await service.migrate();

        final personsAfterSecond =
            (await db.select(db.persons).get()).map((p) => p.name).toList()
              ..sort();
        final groupsAfterSecond = await (db.select(db.groups)
              ..where((g) => g.name.equals('Family')))
            .get();

        expect(personsAfterSecond, personsAfterFirst); // no duplicate persons
        expect(groupsAfterFirst, hasLength(1));
        expect(groupsAfterSecond, hasLength(1)); // single Family group
      });
    });

    // ── (7) Empty legacy tables ─────────────────────────────────────
    group('empty legacy tables', () {
      test('migrates cleanly with no legacy data', () async {
        await service.migrate(); // must not throw

        expect(await db.select(db.persons).get(), isEmpty);
        expect(await db.select(db.transactionSplits).get(), isEmpty);
        expect(await db.select(db.groups).get(), isEmpty);
        expect(await db.select(db.groupMembers).get(), isEmpty);
        expect(await db.select(db.spendlerTransactions).get(), isEmpty);
      });
    });
  });
}

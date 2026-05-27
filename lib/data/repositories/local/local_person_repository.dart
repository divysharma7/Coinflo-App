import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/person_repository.dart';

class LocalPersonRepository implements PersonRepository {
  final SpendlerDatabase db;

  LocalPersonRepository(this.db);

  @override
  Stream<List<Person>> watchAllPersons() {
    return (db.select(db.persons)
          ..where((p) => p.archivedAt.isNull())
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  @override
  Stream<List<Person>> watchByTag(String tag) {
    return (db.select(db.persons)
          ..where((p) => p.tag.equals(tag))
          ..where((p) => p.archivedAt.isNull())
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  @override
  Future<Person?> getPersonById(int id) {
    return (db.select(db.persons)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<int> createPerson(PersonsCompanion entry) {
    return db.into(db.persons).insert(entry);
  }

  @override
  Future<void> updatePerson(int id, PersonsCompanion entry) {
    return (db.update(db.persons)..where((p) => p.id.equals(id))).write(entry);
  }

  @override
  Future<void> deletePerson(int id) {
    return (db.delete(db.persons)..where((p) => p.id.equals(id))).go();
  }

  @override
  Future<double> getPersonBalance(int personId) async {
    final result = await db.customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN ts.person_id = ?1 AND t.payer_person_id IS NULL THEN ts.share_amount ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN ts.person_id IS NULL AND t.payer_person_id = ?1 THEN ts.share_amount ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN t.txn_type = 'settlement' AND t.counterparty_person_id = ?1 AND t.settlement_direction = 'paid_to' THEN t.amount ELSE 0 END), 0)
        + COALESCE(SUM(CASE WHEN t.txn_type = 'settlement' AND t.counterparty_person_id = ?1 AND t.settlement_direction = 'received_from' THEN t.amount ELSE 0 END), 0)
      AS balance
      FROM transaction_splits ts
      INNER JOIN spendler_transactions t ON t.id = ts.transaction_id
      WHERE ts.person_id = ?1 OR ts.person_id IS NULL
      ''',
      variables: [Variable.withInt(personId)],
      readsFrom: {db.transactionSplits, db.spendlerTransactions},
    ).get();
    if (result.isEmpty) return 0;
    return result.first.read<double>('balance');
  }

  @override
  Stream<double> watchPersonBalance(int personId) {
    return db.customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN ts.person_id = ?1 AND t.payer_person_id IS NULL THEN ts.share_amount ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN ts.person_id IS NULL AND t.payer_person_id = ?1 THEN ts.share_amount ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN t.txn_type = 'settlement' AND t.counterparty_person_id = ?1 AND t.settlement_direction = 'paid_to' THEN t.amount ELSE 0 END), 0)
        + COALESCE(SUM(CASE WHEN t.txn_type = 'settlement' AND t.counterparty_person_id = ?1 AND t.settlement_direction = 'received_from' THEN t.amount ELSE 0 END), 0)
      AS balance
      FROM transaction_splits ts
      INNER JOIN spendler_transactions t ON t.id = ts.transaction_id
      WHERE ts.person_id = ?1 OR ts.person_id IS NULL
      ''',
      variables: [Variable.withInt(personId)],
      readsFrom: {db.transactionSplits, db.spendlerTransactions},
    ).watch().map((rows) {
      if (rows.isEmpty) return 0.0;
      return rows.first.read<double>('balance');
    });
  }
}

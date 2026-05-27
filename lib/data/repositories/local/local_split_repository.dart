import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/split_repository.dart';

class LocalSplitRepository implements SplitRepository {
  final SpendlerDatabase db;

  LocalSplitRepository(this.db);

  @override
  Future<void> createSplits(int txnId, List<SplitEntry> splits) async {
    await db.batch((batch) {
      for (final s in splits) {
        batch.insert(
          db.transactionSplits,
          TransactionSplitsCompanion.insert(
            transactionId: txnId,
            personId: Value(s.personId),
            shareAmount: s.shareAmount,
          ),
        );
      }
    });
  }

  @override
  Stream<List<TransactionSplit>> watchSplitsForTransaction(int txnId) {
    return (db.select(db.transactionSplits)
          ..where((s) => s.transactionId.equals(txnId))
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .watch();
  }

  @override
  Future<double> getBalanceForPerson(int personId) async {
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
  Stream<double> watchBalanceForPerson(int personId) {
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

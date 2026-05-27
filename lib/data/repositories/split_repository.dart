import 'package:finance_buddy_app/data/db.dart';

class SplitEntry {
  final int? personId; // null = user's own share
  final double shareAmount;
  const SplitEntry({required this.personId, required this.shareAmount});
}

abstract class SplitRepository {
  Future<void> createSplits(int txnId, List<SplitEntry> splits);
  Stream<List<TransactionSplit>> watchSplitsForTransaction(int txnId);
  Future<double> getBalanceForPerson(int personId);
  Stream<double> watchBalanceForPerson(int personId);
}

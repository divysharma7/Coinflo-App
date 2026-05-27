import 'package:finance_buddy_app/data/db.dart';

class FriendBalance {
  final double theyOweMe;
  final double iOweThem;
  const FriendBalance({required this.theyOweMe, required this.iOweThem});
}

class TotalFriendBalance {
  final double totalReceivable;
  final double totalPayable;
  const TotalFriendBalance(
      {required this.totalReceivable, required this.totalPayable});
}

abstract class FriendSplitRepository {
  Stream<List<FriendContact>> watchAllContacts();
  Future<FriendContact?> getContact(int id);
  Future<int> createContact(FriendContactsCompanion entry);
  Future<FriendBalance> getBalance(int friendContactId);
  Stream<TotalFriendBalance> watchTotalBalance();
  Stream<List<FriendSplit>> watchPendingSplitsForFriend(int friendContactId);
  Stream<List<FriendSplit>> watchSettledSplits();
  Future<void> markSettled(int friendSplitId, String method);
  Future<void> markPartialPayment(int friendSplitId, double amountPaid, String method);
  Future<void> markWrittenOff(int friendSplitId);
  Future<int> createSplit(FriendSplitsCompanion entry);
}

import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/friend_split_repository.dart';

class LocalFriendSplitRepository implements FriendSplitRepository {
  final SpendlerDatabase db;

  LocalFriendSplitRepository(this.db);

  @override
  Stream<List<FriendContact>> watchAllContacts() {
    return (db.select(db.friendContacts)
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .watch();
  }

  @override
  Future<FriendContact?> getContact(int id) {
    return (db.select(db.friendContacts)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<int> createContact(FriendContactsCompanion entry) {
    return db.into(db.friendContacts).insert(entry);
  }

  @override
  Future<FriendBalance> getBalance(int friendContactId) async {
    final splits = await (db.select(db.friendSplits)
          ..where((s) => s.friendContactId.equals(friendContactId))
          ..where((s) => s.isSettled.equals(false))
          ..where((s) => s.isWrittenOff.equals(false)))
        .get();

    double theyOweMe = 0;
    double iOweThem = 0;
    for (final s in splits) {
      if (s.direction == 'they_owe_me') {
        theyOweMe += s.amount;
      } else {
        iOweThem += s.amount;
      }
    }
    return FriendBalance(theyOweMe: theyOweMe, iOweThem: iOweThem);
  }

  @override
  Stream<TotalFriendBalance> watchTotalBalance() {
    final query = db.select(db.friendSplits)
      ..where((s) => s.isSettled.equals(false))
      ..where((s) => s.isWrittenOff.equals(false));

    return query.watch().map((splits) {
      double totalReceivable = 0;
      double totalPayable = 0;
      for (final s in splits) {
        if (s.direction == 'they_owe_me') {
          totalReceivable += s.amount;
        } else {
          totalPayable += s.amount;
        }
      }
      return TotalFriendBalance(
        totalReceivable: totalReceivable,
        totalPayable: totalPayable,
      );
    });
  }

  @override
  Stream<List<FriendSplit>> watchPendingSplitsForFriend(int friendContactId) {
    return (db.select(db.friendSplits)
          ..where((s) => s.friendContactId.equals(friendContactId))
          ..where((s) => s.isSettled.equals(false))
          ..where((s) => s.isWrittenOff.equals(false))
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .watch();
  }

  @override
  Stream<List<FriendSplit>> watchSettledSplits() {
    return (db.select(db.friendSplits)
          ..where((s) =>
              s.isSettled.equals(true) | s.isWrittenOff.equals(true))
          ..orderBy([(s) => OrderingTerm.desc(s.settledAt)]))
        .watch();
  }

  @override
  Future<void> markSettled(int friendSplitId, String method) {
    return (db.update(db.friendSplits)
          ..where((s) => s.id.equals(friendSplitId)))
        .write(FriendSplitsCompanion(
      isSettled: const Value(true),
      settledAt: Value(DateTime.now()),
      settlementMethod: Value(method),
    ));
  }

  @override
  Future<void> markWrittenOff(int friendSplitId) {
    return (db.update(db.friendSplits)
          ..where((s) => s.id.equals(friendSplitId)))
        .write(FriendSplitsCompanion(
      isWrittenOff: const Value(true),
      settledAt: Value(DateTime.now()),
      settlementMethod: const Value('written_off'),
    ));
  }

  @override
  Future<int> createSplit(FriendSplitsCompanion entry) {
    return db.into(db.friendSplits).insert(entry);
  }
}

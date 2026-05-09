import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/data/repositories/friend_split_repository.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';

final friendContactsProvider = StreamProvider<List<FriendContact>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchAllContacts();
});

final totalFriendBalanceProvider =
    StreamProvider<TotalFriendBalance>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchTotalBalance();
});

final friendPendingSplitsProvider =
    StreamProvider.family<List<FriendSplit>, int>((ref, friendId) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchPendingSplitsForFriend(friendId);
});

final settledSplitsProvider = StreamProvider<List<FriendSplit>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchSettledSplits();
});

// ─── Mutation helpers ───────────────────────────────

/// Create a standalone split (not linked to a transaction).
Future<void> insertSplit(
  BaseRepository repo, {
  required int friendContactId,
  required double amount,
  required String direction,
}) async {
  await repo.createSplit(FriendSplitsCompanion.insert(
    transactionId: 0,
    friendContactId: friendContactId,
    amount: amount,
    direction: direction,
  ));
}

/// Mark a single split as settled.
Future<void> settleSplit(BaseRepository repo, int splitId) async {
  await repo.markSettled(splitId, 'manual');
}

/// Settle multiple splits.
Future<void> settleSplits(BaseRepository repo, Iterable<int> splitIds) async {
  for (final id in splitIds) {
    await repo.markSettled(id, 'manual');
  }
}

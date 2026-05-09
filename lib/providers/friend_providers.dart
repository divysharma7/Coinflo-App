import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/data/db.dart';
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

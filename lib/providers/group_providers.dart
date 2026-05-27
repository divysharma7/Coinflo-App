import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';

final allGroupsProvider = StreamProvider<List<Group>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchAllGroups();
});

final groupMembersProvider =
    StreamProvider.family<List<GroupMember>, int>((ref, groupId) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchGroupMembers(groupId);
});

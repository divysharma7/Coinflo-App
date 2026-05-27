import 'package:finance_buddy_app/data/db.dart';

abstract class GroupRepository {
  Stream<List<Group>> watchAllGroups();
  Future<Group?> getGroupById(int id);
  Future<int> createGroup(GroupsCompanion entry);
  Future<void> addGroupMember(int groupId, int personId);
  Future<void> removeGroupMember(int groupId, int personId);
  Stream<List<GroupMember>> watchGroupMembers(int groupId);
  Future<void> archiveGroup(int groupId);
}

import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/group_repository.dart';

class LocalGroupRepository implements GroupRepository {
  final SpendlerDatabase db;

  LocalGroupRepository(this.db);

  @override
  Stream<List<Group>> watchAllGroups() {
    return (db.select(db.groups)
          ..where((g) => g.archivedAt.isNull())
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
        .watch();
  }

  @override
  Future<Group?> getGroupById(int id) {
    return (db.select(db.groups)..where((g) => g.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<int> createGroup(GroupsCompanion entry) {
    return db.into(db.groups).insert(entry);
  }

  @override
  Future<void> addGroupMember(int groupId, int personId) {
    return db.into(db.groupMembers).insert(GroupMembersCompanion.insert(
      groupId: groupId,
      personId: personId,
    ));
  }

  @override
  Future<void> removeGroupMember(int groupId, int personId) {
    return (db.delete(db.groupMembers)
          ..where(
              (m) => m.groupId.equals(groupId) & m.personId.equals(personId)))
        .go();
  }

  @override
  Stream<List<GroupMember>> watchGroupMembers(int groupId) {
    return (db.select(db.groupMembers)
          ..where((m) => m.groupId.equals(groupId))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .watch();
  }

  @override
  Future<void> archiveGroup(int groupId) {
    return (db.update(db.groups)..where((g) => g.id.equals(groupId)))
        .write(GroupsCompanion(archivedAt: Value(DateTime.now())));
  }
}

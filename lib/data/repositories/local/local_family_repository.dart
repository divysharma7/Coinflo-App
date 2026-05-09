import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/family_repository.dart';

class LocalFamilyRepository implements FamilyRepository {
  final SpendlerDatabase db;

  LocalFamilyRepository(this.db);

  @override
  Stream<List<FamilyEntry>> watchAllFamilyEntries() {
    return (db.select(db.familyEntries)
          ..orderBy([(e) => OrderingTerm.desc(e.happenedAt)]))
        .watch();
  }

  @override
  Stream<List<FamilyEntry>> watchFamilyByType(String type) {
    return (db.select(db.familyEntries)
          ..where((e) => e.type.equals(type))
          ..orderBy([(e) => OrderingTerm.desc(e.happenedAt)]))
        .watch();
  }

  @override
  Future<double> getTotalWealth() async {
    final entries = await db.select(db.familyEntries).get();
    return entries.fold<double>(0, (sum, e) => sum + e.amount);
  }

  @override
  Future<int> insertEntry(FamilyEntriesCompanion entry) {
    return db.into(db.familyEntries).insert(entry);
  }

  @override
  Future<void> updateEntry(int id, FamilyEntriesCompanion entry) {
    return (db.update(db.familyEntries)..where((e) => e.id.equals(id)))
        .write(entry);
  }

  @override
  Future<void> deleteEntry(int id) {
    return (db.delete(db.familyEntries)..where((e) => e.id.equals(id))).go();
  }
}

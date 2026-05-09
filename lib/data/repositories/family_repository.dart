import 'package:finance_buddy_app/data/db.dart';

abstract class FamilyRepository {
  Stream<List<FamilyEntry>> watchAllFamilyEntries();
  Stream<List<FamilyEntry>> watchFamilyByType(String type);
  Future<double> getTotalWealth();
  Future<int> insertEntry(FamilyEntriesCompanion entry);
  Future<void> updateEntry(int id, FamilyEntriesCompanion entry);
  Future<void> deleteEntry(int id);
}

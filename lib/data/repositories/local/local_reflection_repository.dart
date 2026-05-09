import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/reflection_repository.dart';

class LocalReflectionRepository implements ReflectionRepository {
  final PaisaDatabase db;

  LocalReflectionRepository(this.db);

  @override
  Future<WeeklyReflection?> getForWeek(DateTime weekStart) {
    return (db.select(db.weeklyReflections)
          ..where((r) => r.weekStartDate.equals(weekStart)))
        .getSingleOrNull();
  }

  @override
  Future<int> insertReflection(WeeklyReflectionsCompanion entry) {
    return db.into(db.weeklyReflections).insert(entry);
  }

  @override
  Future<void> markOpened(int id) {
    return (db.update(db.weeklyReflections)..where((r) => r.id.equals(id)))
        .write(WeeklyReflectionsCompanion(openedAt: Value(DateTime.now())));
  }
}

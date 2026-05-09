import 'package:finance_buddy_app/data/db.dart';

abstract class ReflectionRepository {
  Future<WeeklyReflection?> getForWeek(DateTime weekStart);
  Future<int> insertReflection(WeeklyReflectionsCompanion entry);
  Future<void> markOpened(int id);
}

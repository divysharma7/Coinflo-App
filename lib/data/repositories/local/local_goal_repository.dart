import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/goal_repository.dart';

class LocalGoalRepository implements GoalRepository {
  final SpendlerDatabase db;

  LocalGoalRepository(this.db);

  @override
  Stream<List<SavingsGoal>> watchAllGoals() {
    return (db.select(db.savingsGoals)
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
        .watch();
  }

  @override
  Future<SavingsGoal?> getGoal(int id) {
    return (db.select(db.savingsGoals)..where((g) => g.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<int> insertGoal(SavingsGoalsCompanion entry) {
    return db.into(db.savingsGoals).insert(entry);
  }

  @override
  Future<void> updateGoal(int id, SavingsGoalsCompanion entry) {
    return (db.update(db.savingsGoals)..where((g) => g.id.equals(id)))
        .write(entry);
  }

  @override
  Future<void> addMoney(int id, double amount) async {
    final goal = await getGoal(id);
    if (goal == null) return;
    final newAmount = (goal.currentAmount + amount).clamp(0.0, goal.targetAmount);
    await (db.update(db.savingsGoals)..where((g) => g.id.equals(id)))
        .write(SavingsGoalsCompanion(currentAmount: Value(newAmount)));
  }

  @override
  Future<void> deleteGoal(int id) {
    return (db.delete(db.savingsGoals)..where((g) => g.id.equals(id))).go();
  }
}

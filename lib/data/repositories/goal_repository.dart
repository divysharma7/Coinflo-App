import 'package:finance_buddy_app/data/db.dart';

abstract class GoalRepository {
  Stream<List<SavingsGoal>> watchAllGoals();
  Future<SavingsGoal?> getGoal(int id);
  Future<int> insertGoal(SavingsGoalsCompanion entry);
  Future<void> updateGoal(int id, SavingsGoalsCompanion entry);
  Future<void> addMoney(int id, double amount);
  Future<void> deleteGoal(int id);
}

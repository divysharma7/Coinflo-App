import 'package:finance_buddy_app/data/db.dart';

abstract class BudgetRepository {
  Stream<List<CategoryBudget>> watchAllBudgets();
  Future<CategoryBudget?> getBudgetForCategory(String category);
  Future<int> insertBudget(CategoryBudgetsCompanion entry);
  Future<void> updateBudget(int id, CategoryBudgetsCompanion entry);
  Future<void> deleteBudget(int id);
}

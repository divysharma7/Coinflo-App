import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/budget_repository.dart';

class LocalBudgetRepository implements BudgetRepository {
  final SpendlerDatabase db;

  LocalBudgetRepository(this.db);

  @override
  Stream<List<CategoryBudget>> watchAllBudgets() {
    return (db.select(db.categoryBudgets)
          ..orderBy([(b) => OrderingTerm.asc(b.category)]))
        .watch();
  }

  @override
  Future<CategoryBudget?> getBudgetForCategory(String category) {
    return (db.select(db.categoryBudgets)
          ..where((b) => b.category.equals(category)))
        .getSingleOrNull();
  }

  @override
  Future<int> insertBudget(CategoryBudgetsCompanion entry) {
    return db.into(db.categoryBudgets).insert(entry);
  }

  @override
  Future<void> updateBudget(int id, CategoryBudgetsCompanion entry) {
    return (db.update(db.categoryBudgets)..where((b) => b.id.equals(id)))
        .write(entry);
  }

  @override
  Future<void> deleteBudget(int id) {
    return (db.delete(db.categoryBudgets)..where((b) => b.id.equals(id))).go();
  }
}

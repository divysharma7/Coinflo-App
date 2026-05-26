import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';

// ─── Budget providers ────────────────────────────────

final budgetsProvider = StreamProvider<List<CategoryBudget>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchAllBudgets();
});

/// Current-month spending per category, keyed by category name.
final monthlyCategorySpendingProvider =
    FutureProvider<Map<String, double>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final now = DateTime.now();
  return repo.getCategoryTotalsForMonth(now);
});

/// Aggregated budget status (total limit vs total spent).
class BudgetStatus {
  final double totalLimit;
  final double totalSpent;
  double get remaining => totalLimit - totalSpent;
  bool get isOverBudget => totalSpent > totalLimit;
  const BudgetStatus({required this.totalLimit, required this.totalSpent});
}

final budgetStatusProvider = Provider<AsyncValue<BudgetStatus>>((ref) {
  final budgets = ref.watch(budgetsProvider);
  final spending = ref.watch(monthlyCategorySpendingProvider);

  return budgets.whenData((budgetList) {
    final spendingMap = spending.valueOrNull ?? {};
    double totalLimit = 0;
    double totalSpent = 0;
    for (final b in budgetList) {
      totalLimit += b.monthlyLimit;
      totalSpent += spendingMap[b.category] ?? 0;
    }
    return BudgetStatus(totalLimit: totalLimit, totalSpent: totalSpent);
  });
});

// ─── Goal providers ──────────────────────────────────

final goalsProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchAllGoals();
});

// ─── Mutation helpers ────────────────────────────────

Future<void> upsertBudget(
  BaseRepository repo, {
  required String category,
  required double monthlyLimit,
}) async {
  final existing = await repo.getBudgetForCategory(category);
  if (existing != null) {
    await repo.updateBudget(
      existing.id,
      CategoryBudgetsCompanion(monthlyLimit: Value(monthlyLimit)),
    );
  } else {
    await repo.insertBudget(CategoryBudgetsCompanion(
      category: Value(category),
      monthlyLimit: Value(monthlyLimit),
    ));
  }
}

Future<void> deleteBudget(BaseRepository repo, int id) async {
  await repo.deleteBudget(id);
}

Future<void> insertGoal(
  BaseRepository repo, {
  required String name,
  required double targetAmount,
  required String iconName,
}) async {
  await repo.insertGoal(SavingsGoalsCompanion(
    name: Value(name),
    targetAmount: Value(targetAmount),
    iconName: Value(iconName),
  ));
}

Future<void> updateGoal(
  BaseRepository repo, {
  required int id,
  required String name,
  required double targetAmount,
  required String iconName,
}) async {
  await repo.updateGoal(
    id,
    SavingsGoalsCompanion(
      name: Value(name),
      targetAmount: Value(targetAmount),
      iconName: Value(iconName),
    ),
  );
}

Future<void> deleteGoal(BaseRepository repo, int id) async {
  await repo.deleteGoal(id);
}

Future<void> addMoneyToGoal(BaseRepository repo, int goalId, double amount) async {
  await repo.addMoney(goalId, amount);
}

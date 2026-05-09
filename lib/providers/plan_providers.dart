import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/data/db.dart';
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

// ─── Goal providers ──────────────────────────────────

final goalsProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchAllGoals();
});

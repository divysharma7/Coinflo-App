import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/providers/navigation_providers.dart';

final weeklyTransactionsProvider = StreamProvider.autoDispose<List<SpendlerTransaction>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final weekStart = ref.watch(selectedWeekProvider);
  return repo.watchTransactionsForWeek(weekStart);
});

final unconfirmedQueueProvider = StreamProvider.autoDispose<List<SpendlerTransaction>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchUnconfirmed();
});

final allTransactionsProvider = StreamProvider.autoDispose<List<SpendlerTransaction>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchAll();
});

final singleTransactionProvider = FutureProvider.autoDispose.family<SpendlerTransaction?, int>((ref, id) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getById(id);
});

final categoryFilterProvider = StateProvider<TransactionCategory?>((ref) => null);

// Multi-dimensional filter state
enum DirectionFilter { all, sent, received }
enum AmountFilter { all, upto200, range200to500, range500to2000, above2000 }
enum DateFilter { all, last30, last90 }

class TransactionFilters {
  final DirectionFilter direction;
  final AmountFilter amount;
  final DateFilter date;
  final TransactionCategory? category;

  const TransactionFilters({
    this.direction = DirectionFilter.all,
    this.amount = AmountFilter.all,
    this.date = DateFilter.all,
    this.category,
  });

  bool get hasAnyFilter =>
      direction != DirectionFilter.all ||
      amount != AmountFilter.all ||
      date != DateFilter.all ||
      category != null;

  TransactionFilters copyWith({
    DirectionFilter? direction,
    AmountFilter? amount,
    DateFilter? date,
    TransactionCategory? category,
    bool clearCategory = false,
  }) {
    return TransactionFilters(
      direction: direction ?? this.direction,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: clearCategory ? null : (category ?? this.category),
    );
  }

  static const empty = TransactionFilters();
}

final transactionFiltersProvider =
    StateProvider<TransactionFilters>((ref) => TransactionFilters.empty);

final filteredTransactionsProvider = Provider<AsyncValue<List<SpendlerTransaction>>>((ref) {
  final filters = ref.watch(transactionFiltersProvider);
  final allTxns = ref.watch(allTransactionsProvider);

  if (!filters.hasAnyFilter) return allTxns;

  final now = DateTime.now();

  return allTxns.whenData((txns) {
    return txns.where((t) {
      // Direction filter
      if (filters.direction == DirectionFilter.sent && t.amount >= 0) return false;
      if (filters.direction == DirectionFilter.received && t.amount < 0) return false;

      // Amount filter
      final absAmt = t.amount.abs();
      switch (filters.amount) {
        case AmountFilter.upto200:
          if (absAmt > 200) return false;
        case AmountFilter.range200to500:
          if (absAmt <= 200 || absAmt > 500) return false;
        case AmountFilter.range500to2000:
          if (absAmt <= 500 || absAmt > 2000) return false;
        case AmountFilter.above2000:
          if (absAmt <= 2000) return false;
        case AmountFilter.all:
          break;
      }

      // Date filter
      final daysDiff = now.difference(t.happenedAt).inDays;
      if (filters.date == DateFilter.last30 && daysDiff > 30) return false;
      if (filters.date == DateFilter.last90 && daysDiff > 90) return false;

      // Category filter
      if (filters.category != null && t.category != filters.category!.name) return false;

      return true;
    }).toList();
  });
});

final dailyTransactionsProvider =
    FutureProvider.family<List<SpendlerTransaction>, DateTime>((ref, day) {
  final repo = ref.watch(repositoryProvider);
  return repo.getTransactionsForDay(day);
});

final todaySpendingProvider = FutureProvider.autoDispose<double>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.getTodaySpending();
});

final todayTopCategoryProvider = FutureProvider.autoDispose<String?>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.getTodayTopCategory();
});

final weekOverWeekDeltaProvider = FutureProvider.autoDispose<double>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.getWeekOverWeekDelta();
});

final weeklyMerchantCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final weekStart = ref.watch(selectedWeekProvider);
  return repo.getTopMerchantCountsForWeek(weekStart);
});

// ─── Helpers ────────────────────────────────────────

/// Returns the user's effective expense for a transaction.
/// For split transactions, returns splitMyShare; otherwise returns full amount.
double _userExpense(SpendlerTransaction t) {
  if (t.isSplit && t.splitMyShare != null) return t.splitMyShare!;
  return t.amount.abs();
}

bool _isUserExpense(SpendlerTransaction t) =>
    t.amount < 0 && t.category != 'settlement';

// ─── Computed providers ─────────────────────────────

/// Sorted category totals from weekly transactions.
/// Uses user's share for split transactions. Excludes settlements.
final weeklyCategoryTotalsProvider =
    Provider.autoDispose<AsyncValue<List<MapEntry<TransactionCategory, double>>>>((ref) {
  final weeklyTxns = ref.watch(weeklyTransactionsProvider);
  return weeklyTxns.whenData((txns) {
    final totals = <TransactionCategory, double>{};
    for (final t in txns) {
      if (_isUserExpense(t)) {
        final cat = TransactionCategory.values.firstWhere(
          (c) => c.name == t.category,
          orElse: () => TransactionCategory.other,
        );
        totals[cat] = (totals[cat] ?? 0) + _userExpense(t);
      }
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted;
  });
});

/// Total weekly expenses (absolute value). Uses user's share for splits.
final weeklyTotalSpentProvider =
    Provider.autoDispose<AsyncValue<double>>((ref) {
  final weeklyTxns = ref.watch(weeklyTransactionsProvider);
  return weeklyTxns.whenData((txns) =>
      txns.where(_isUserExpense).fold<double>(0, (s, t) => s + _userExpense(t)));
});

// ─── Home screen providers ────────────────────────────

/// All transactions for the selected month (home page).
final monthlyTransactionsForHomeProvider =
    FutureProvider.autoDispose<List<SpendlerTransaction>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final month = ref.watch(selectedMonthProvider);
  return repo.getTransactionsForMonth(month);
});

/// Current all-time balance (sum of all amounts).
final currentBalanceProvider = Provider.autoDispose<AsyncValue<double>>((ref) {
  return ref.watch(allTransactionsProvider).whenData(
        (txns) => txns.fold<double>(0, (sum, t) => sum + t.amount),
      );
});

/// Monthly income (sum of positive amounts) for selected month.
final monthlyIncomeProvider = Provider.autoDispose<AsyncValue<double>>((ref) {
  return ref.watch(monthlyTransactionsForHomeProvider).whenData(
        (txns) => txns
            .where((t) => t.amount > 0)
            .fold<double>(0, (s, t) => s + t.amount),
      );
});

/// Monthly expense for selected month. Uses user's share for splits.
final monthlyExpenseProvider = Provider.autoDispose<AsyncValue<double>>((ref) {
  return ref.watch(monthlyTransactionsForHomeProvider).whenData(
        (txns) => txns
            .where(_isUserExpense)
            .fold<double>(0, (s, t) => s + _userExpense(t)),
      );
});

/// Last month's total expense for comparison. Uses user's share for splits.
final lastMonthExpenseProvider = FutureProvider.autoDispose<double>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final month = ref.watch(selectedMonthProvider);
  final prev = DateTime(month.year, month.month - 1);
  final txns = await repo.getTransactionsForMonth(prev);
  return txns
      .where(_isUserExpense)
      .fold<double>(0, (s, t) => s + _userExpense(t));
});

/// Top 3 spending categories for the selected month. Uses user's share.
final topCategoriesProvider =
    Provider.autoDispose<AsyncValue<List<MapEntry<String, double>>>>((ref) {
  return ref.watch(monthlyTransactionsForHomeProvider).whenData((txns) {
    final totals = <String, double>{};
    for (final t in txns) {
      if (_isUserExpense(t)) {
        totals[t.category] = (totals[t.category] ?? 0) + _userExpense(t);
      }
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).toList();
  });
});

// ─── Mutation helpers ───────────────────────────────

/// Insert a manually entered transaction.
Future<void> insertManualTransaction(
  BaseRepository repo, {
  required double amount,
  required String category,
  String? note,
}) async {
  await repo.insertTransaction(SpendlerTransactionsCompanion.insert(
    amount: amount,
    category: category,
    note: Value(note),
    source: const Value('manual'),
    status: const Value('confirmed'),
  ));
}

/// Confirm all unconfirmed transactions.
Future<void> confirmAllTransactions(BaseRepository repo) async {
  await repo.confirmAllUnconfirmed();
}

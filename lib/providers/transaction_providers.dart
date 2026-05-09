import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
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
  final all = await repo.watchAll().first;
  return all.where((t) => t.id == id).firstOrNull;
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

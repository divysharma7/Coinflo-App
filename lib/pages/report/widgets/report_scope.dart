import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/providers/providers.dart';

// ---------------------------------------------------------------------------
// Page-local providers
// ---------------------------------------------------------------------------

final reportMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

enum ReportScope { week, month, year }

final reportScopeProvider =
    StateProvider<ReportScope>((ref) => ReportScope.week);

final monthCategoryTotalsProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final month = ref.watch(reportMonthProvider);
  return repo.getCategoryTotalsForMonth(month);
});

final prevMonthCategoryTotalsProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final month = ref.watch(reportMonthProvider);
  final prev = DateTime(month.year, month.month - 1);
  return repo.getCategoryTotalsForMonth(prev);
});

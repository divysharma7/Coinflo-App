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

// Backed by Drift `watch()` so the Report tab's category aggregates refresh
// automatically after any add/edit/delete — including writes made from a push
// route (e.g. TxnDetail) outside the Report branch. (ISSUE 11)
final monthCategoryTotalsProvider =
    StreamProvider.autoDispose<Map<String, double>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final month = ref.watch(reportMonthProvider);
  return repo.watchCategoryTotalsForMonth(month);
});

final prevMonthCategoryTotalsProvider =
    StreamProvider.autoDispose<Map<String, double>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final month = ref.watch(reportMonthProvider);
  final prev = DateTime(month.year, month.month - 1);
  return repo.watchCategoryTotalsForMonth(prev);
});

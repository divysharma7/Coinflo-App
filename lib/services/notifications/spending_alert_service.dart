import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/services/notifications/notification_service.dart';

class SpendingAlertService {
  SpendingAlertService._();
  static final SpendingAlertService instance = SpendingAlertService._();

  /// Check all category budgets and fire a local notification for any
  /// category where current-month spending exceeds 80% of the limit.
  ///
  /// Designed to be called fire-and-forget after inserting a transaction.
  Future<void> checkBudgetAlerts(
    BaseRepository repo,
    NotificationService notifService,
  ) async {
    try {
      // Fetch budgets as a one-shot list from the stream.
      final budgets = await repo.watchAllBudgets().first;
      if (budgets.isEmpty) return;

      final now = DateTime.now();
      final spending = await repo.getCategoryTotalsForMonth(now);

      for (final budget in budgets) {
        final spent = spending[budget.category] ?? 0;
        if (budget.monthlyLimit <= 0) continue;

        final pct = spent / budget.monthlyLimit;
        if (pct >= 0.80) {
          final displayPct = (pct * 100).round();
          // Use a stable id per category so we don't spam repeated alerts.
          final notifId = 'budget_${budget.category}'.hashCode;
          await notifService.show(
            notifId,
            'Budget alert',
            '${_prettyCategoryName(budget.category)} spending is at $displayPct% of your budget',
          );
        }
      }
    } on Exception catch (_) {
      // Swallow errors — this is a best-effort background check.
    }
  }

  /// Convert camelCase enum name to a readable label (e.g. "foodAndDrink" → "Food and drink").
  String _prettyCategoryName(String raw) {
    if (raw.isEmpty) return raw;
    final spaced = raw.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => ' ${m.group(0)!.toLowerCase()}',
    );
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

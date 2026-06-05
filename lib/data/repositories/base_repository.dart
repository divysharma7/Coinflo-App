import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/budget_repository.dart';
import 'package:finance_buddy_app/data/repositories/goal_repository.dart';
import 'package:finance_buddy_app/data/repositories/group_repository.dart';
import 'package:finance_buddy_app/data/repositories/metrics_repository.dart';
import 'package:finance_buddy_app/data/repositories/notification_repository.dart';
import 'package:finance_buddy_app/data/repositories/person_repository.dart';
import 'package:finance_buddy_app/data/repositories/reflection_repository.dart';
import 'package:finance_buddy_app/data/repositories/split_repository.dart';
import 'package:finance_buddy_app/data/repositories/subscription_repository.dart';
import 'package:finance_buddy_app/data/repositories/transaction_repository.dart';

abstract class BaseRepository
    implements
        TransactionRepository,
        ReflectionRepository,
        MetricsRepository,
        NotificationRepository,
        SubscriptionRepository,
        BudgetRepository,
        GoalRepository,
        PersonRepository,
        GroupRepository,
        SplitRepository {
  /// Delete all user data across every table.
  Future<void> clearAll();

  /// Insert a transaction and its splits atomically in a single db.transaction.
  /// Also calls markSplit with the supplied counts/amounts when the list is
  /// non-empty (i.e. this is a split expense, not a plain insert+splits pair).
  Future<int> insertTransactionWithSplits(
    SpendlerTransactionsCompanion entry,
    List<SplitEntry> splits, {
    required int splitCount,
    required double splitMyShare,
    required double splitPendingAmount,
  });

  /// Insert a transaction together with its splits atomically. Use this
  /// variant when no markSplit metadata is needed (e.g. settlement / debt
  /// expense paths that only create splits, not split-metadata columns).
  Future<int> insertTransactionAndSplits(
    SpendlerTransactionsCompanion entry,
    List<SplitEntry> splits,
  );

  /// Wipe every row from every local table.
  Future<void> wipeAllData();
}

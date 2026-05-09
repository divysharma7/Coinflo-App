import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/data/repositories/friend_split_repository.dart';
import 'package:finance_buddy_app/data/repositories/transaction_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_family_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_friend_split_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_metrics_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_notification_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_reflection_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_subscription_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_transaction_repository.dart';

class LocalRepository extends BaseRepository {
  final PaisaDatabase db;

  late final LocalTransactionRepository _txnRepo;
  late final LocalFamilyRepository _familyRepo;
  late final LocalReflectionRepository _reflectionRepo;
  late final LocalMetricsRepository _metricsRepo;
  late final LocalNotificationRepository _notifRepo;
  late final LocalFriendSplitRepository _friendSplitRepo;
  late final LocalSubscriptionRepository _subscriptionRepo;

  LocalRepository(this.db) {
    _txnRepo = LocalTransactionRepository(db);
    _familyRepo = LocalFamilyRepository(db);
    _reflectionRepo = LocalReflectionRepository(db);
    _metricsRepo = LocalMetricsRepository(db);
    _notifRepo = LocalNotificationRepository(db);
    _friendSplitRepo = LocalFriendSplitRepository(db);
    _subscriptionRepo = LocalSubscriptionRepository(db);
  }

  // ─── Transaction delegates ──────────────────────────

  @override
  Stream<List<PaisaTransaction>> watchTransactionsForWeek(DateTime weekStart) =>
      _txnRepo.watchTransactionsForWeek(weekStart);

  @override
  Stream<List<PaisaTransaction>> watchUnconfirmed() => _txnRepo.watchUnconfirmed();

  @override
  Stream<List<PaisaTransaction>> watchAll() => _txnRepo.watchAll();

  @override
  Future<List<PaisaTransaction>> getTransactionsForDay(DateTime day) =>
      _txnRepo.getTransactionsForDay(day);

  @override
  Future<List<PaisaTransaction>> getTransactionsForMonth(DateTime month) =>
      _txnRepo.getTransactionsForMonth(month);

  @override
  Future<int> getUnconfirmedCount() => _txnRepo.getUnconfirmedCount();

  @override
  Future<int> insertTransaction(PaisaTransactionsCompanion entry) =>
      _txnRepo.insertTransaction(entry);

  @override
  Future<void> confirmTransaction(int id) => _txnRepo.confirmTransaction(id);

  @override
  Future<void> updateTransaction(int id, PaisaTransactionsCompanion entry) =>
      _txnRepo.updateTransaction(id, entry);

  @override
  Future<void> deleteTransaction(int id) => _txnRepo.deleteTransaction(id);

  @override
  Future<void> markSplit(int id, int splitCount, double myShare, double pendingAmount) =>
      _txnRepo.markSplit(id, splitCount, myShare, pendingAmount);

  @override
  Future<void> settleSplit(int id) => _txnRepo.settleSplit(id);

  @override
  Future<List<PaisaTransaction>> getUnsettledSplits() => _txnRepo.getUnsettledSplits();

  @override
  Future<Map<String, double>> getCategoryTotalsForMonth(DateTime month) =>
      _txnRepo.getCategoryTotalsForMonth(month);

  @override
  Future<List<double>> getWeeklySpendingTrend(int weekCount) =>
      _txnRepo.getWeeklySpendingTrend(weekCount);

  @override
  Future<double> getTotalSpentForWeek(DateTime weekStart) =>
      _txnRepo.getTotalSpentForWeek(weekStart);

  @override
  Future<void> confirmAllUnconfirmed() => _txnRepo.confirmAllUnconfirmed();

  @override
  Future<Map<String, List<double>>> getHeatmapData() => _txnRepo.getHeatmapData();

  @override
  Future<double> getTodaySpending() => _txnRepo.getTodaySpending();

  @override
  Future<String?> getTodayTopCategory() => _txnRepo.getTodayTopCategory();

  @override
  Future<double> getWeekOverWeekDelta() => _txnRepo.getWeekOverWeekDelta();

  @override
  Future<Map<String, int>> getTopMerchantCountsForWeek(DateTime weekStart) =>
      _txnRepo.getTopMerchantCountsForWeek(weekStart);

  @override
  Future<List<double>> getCumulativeSpendingForMonth(DateTime month) =>
      _txnRepo.getCumulativeSpendingForMonth(month);

  @override
  Future<List<double>> getDayOfWeekAverages(int weekCount) =>
      _txnRepo.getDayOfWeekAverages(weekCount);

  @override
  Future<List<MerchantStat>> getTopMerchants(int limit) =>
      _txnRepo.getTopMerchants(limit);

  @override
  Future<Map<String, List<double>>> getMonthlyComparison() =>
      _txnRepo.getMonthlyComparison();

  @override
  Future<int> getStreakWeeksUnderTarget(double target) =>
      _txnRepo.getStreakWeeksUnderTarget(target);

  @override
  Future<List<String>> getWeeklyAlerts({double singleTxnThreshold = 2000}) =>
      _txnRepo.getWeeklyAlerts(singleTxnThreshold: singleTxnThreshold);

  // ─��─ Family delegates ───────────────────────────────

  @override
  Stream<List<FamilyEntry>> watchAllFamilyEntries() => _familyRepo.watchAllFamilyEntries();

  @override
  Stream<List<FamilyEntry>> watchFamilyByType(String type) => _familyRepo.watchFamilyByType(type);

  @override
  Future<double> getTotalWealth() => _familyRepo.getTotalWealth();

  @override
  Future<int> insertEntry(FamilyEntriesCompanion entry) => _familyRepo.insertEntry(entry);

  @override
  Future<void> updateEntry(int id, FamilyEntriesCompanion entry) =>
      _familyRepo.updateEntry(id, entry);

  @override
  Future<void> deleteEntry(int id) => _familyRepo.deleteEntry(id);

  // ─── Reflection delegates ─────────���─────────────────

  @override
  Future<WeeklyReflection?> getForWeek(DateTime weekStart) =>
      _reflectionRepo.getForWeek(weekStart);

  @override
  Future<int> insertReflection(WeeklyReflectionsCompanion entry) =>
      _reflectionRepo.insertReflection(entry);

  @override
  Future<void> markOpened(int id) => _reflectionRepo.markOpened(id);

  // ─── Metrics delegates ──────────────────────────────

  @override
  Future<void> recordMetric(String metricType, {String? metadata}) =>
      _metricsRepo.recordMetric(metricType, metadata: metadata);

  @override
  Future<int> getAppOpensThisWeek() => _metricsRepo.getAppOpensThisWeek();

  @override
  Future<int> getRetrospectionSessionsThisWeek() =>
      _metricsRepo.getRetrospectionSessionsThisWeek();

  // ─── Notification delegates ─────────────────────────

  @override
  Stream<List<AppNotification>> watchUnread() => _notifRepo.watchUnread();

  @override
  Stream<List<AppNotification>> watchRecent(int days) =>
      _notifRepo.watchRecent(days);

  @override
  Future<int> insertNotification(AppNotificationsCompanion entry) =>
      _notifRepo.insertNotification(entry);

  @override
  Future<void> markAllRead() => _notifRepo.markAllRead();

  @override
  Future<void> markRead(int id) => _notifRepo.markRead(id);

  @override
  Future<void> purgeOlderThan(int days) => _notifRepo.purgeOlderThan(days);

  @override
  Future<int> getUnreadCount() => _notifRepo.getUnreadCount();

  // ─── Friend split delegates ─────────────────────────

  @override
  Stream<List<FriendContact>> watchAllContacts() =>
      _friendSplitRepo.watchAllContacts();

  @override
  Future<FriendContact?> getContact(int id) =>
      _friendSplitRepo.getContact(id);

  @override
  Future<int> createContact(FriendContactsCompanion entry) =>
      _friendSplitRepo.createContact(entry);

  @override
  Future<FriendBalance> getBalance(int friendContactId) =>
      _friendSplitRepo.getBalance(friendContactId);

  @override
  Stream<TotalFriendBalance> watchTotalBalance() =>
      _friendSplitRepo.watchTotalBalance();

  @override
  Stream<List<FriendSplit>> watchPendingSplitsForFriend(int friendContactId) =>
      _friendSplitRepo.watchPendingSplitsForFriend(friendContactId);

  @override
  Stream<List<FriendSplit>> watchSettledSplits() =>
      _friendSplitRepo.watchSettledSplits();

  @override
  Future<void> markSettled(int friendSplitId, String method) =>
      _friendSplitRepo.markSettled(friendSplitId, method);

  @override
  Future<void> markWrittenOff(int friendSplitId) =>
      _friendSplitRepo.markWrittenOff(friendSplitId);

  @override
  Future<int> createSplit(FriendSplitsCompanion entry) =>
      _friendSplitRepo.createSplit(entry);

  // ─── Subscription delegates ────────────────────────────

  @override
  Stream<List<Subscription>> watchAllSubscriptions() =>
      _subscriptionRepo.watchAllSubscriptions();

  @override
  Stream<List<Subscription>> watchActiveSubscriptions() =>
      _subscriptionRepo.watchActiveSubscriptions();

  @override
  Future<Subscription?> getSubscriptionById(int id) =>
      _subscriptionRepo.getSubscriptionById(id);

  @override
  Future<int> insertSubscription(SubscriptionsCompanion entry) =>
      _subscriptionRepo.insertSubscription(entry);

  @override
  Future<void> updateSubscription(int id, SubscriptionsCompanion entry) =>
      _subscriptionRepo.updateSubscription(id, entry);

  @override
  Future<void> toggleSubscriptionActive(int id, bool isActive) =>
      _subscriptionRepo.toggleSubscriptionActive(id, isActive);

  @override
  Future<void> deleteSubscription(int id) =>
      _subscriptionRepo.deleteSubscription(id);

  @override
  Future<double> getSubscriptionMonthlyTotal() =>
      _subscriptionRepo.getSubscriptionMonthlyTotal();
}

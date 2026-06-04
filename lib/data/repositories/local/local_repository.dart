import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/data/repositories/split_repository.dart';
import 'package:finance_buddy_app/data/repositories/transaction_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_budget_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_goal_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_group_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_metrics_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_notification_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_person_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_reflection_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_split_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_subscription_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_transaction_repository.dart';

class LocalRepository extends BaseRepository {
  final SpendlerDatabase db;

  late final LocalTransactionRepository _txnRepo;
  late final LocalReflectionRepository _reflectionRepo;
  late final LocalMetricsRepository _metricsRepo;
  late final LocalNotificationRepository _notifRepo;
  late final LocalSubscriptionRepository _subscriptionRepo;
  late final LocalBudgetRepository _budgetRepo;
  late final LocalGoalRepository _goalRepo;
  late final LocalPersonRepository _personRepo;
  late final LocalGroupRepository _groupRepo;
  late final LocalSplitRepository _splitRepo;

  LocalRepository(this.db) {
    _txnRepo = LocalTransactionRepository(db);
    _reflectionRepo = LocalReflectionRepository(db);
    _metricsRepo = LocalMetricsRepository(db);
    _notifRepo = LocalNotificationRepository(db);
    _subscriptionRepo = LocalSubscriptionRepository(db);
    _budgetRepo = LocalBudgetRepository(db);
    _goalRepo = LocalGoalRepository(db);
    _personRepo = LocalPersonRepository(db);
    _groupRepo = LocalGroupRepository(db);
    _splitRepo = LocalSplitRepository(db);
  }

  // ─── Transaction delegates ──────────────────────────

  @override
  Stream<List<SpendlerTransaction>> watchTransactionsForWeek(DateTime weekStart) =>
      _txnRepo.watchTransactionsForWeek(weekStart);

  @override
  Stream<List<SpendlerTransaction>> watchUnconfirmed() => _txnRepo.watchUnconfirmed();

  @override
  Stream<List<SpendlerTransaction>> watchAll() => _txnRepo.watchAll();

  @override
  Future<SpendlerTransaction?> getById(int id) => _txnRepo.getById(id);

  @override
  Future<List<SpendlerTransaction>> getTransactionsForDay(DateTime day) =>
      _txnRepo.getTransactionsForDay(day);

  @override
  Future<List<SpendlerTransaction>> getTransactionsForMonth(DateTime month) =>
      _txnRepo.getTransactionsForMonth(month);

  @override
  Stream<List<SpendlerTransaction>> watchTransactionsForMonth(DateTime month) =>
      _txnRepo.watchTransactionsForMonth(month);

  @override
  Future<int> getUnconfirmedCount() => _txnRepo.getUnconfirmedCount();

  @override
  Future<int> insertTransaction(SpendlerTransactionsCompanion entry) =>
      _txnRepo.insertTransaction(entry);

  @override
  Future<void> confirmTransaction(int id) => _txnRepo.confirmTransaction(id);

  @override
  Future<void> updateTransaction(int id, SpendlerTransactionsCompanion entry) =>
      _txnRepo.updateTransaction(id, entry);

  @override
  Future<void> deleteTransaction(int id) => _txnRepo.deleteTransaction(id);

  @override
  Future<void> markSplit(int id, int splitCount, double myShare, double pendingAmount) =>
      _txnRepo.markSplit(id, splitCount, myShare, pendingAmount);

  @override
  Future<void> settleSplit(int id) => _txnRepo.settleSplit(id);

  @override
  Future<List<SpendlerTransaction>> getUnsettledSplits() => _txnRepo.getUnsettledSplits();

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

  // ─── Reflection delegates ─────────────────────────────

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

  // ─── Budget delegates ──────────────────────────────

  @override
  Stream<List<CategoryBudget>> watchAllBudgets() =>
      _budgetRepo.watchAllBudgets();

  @override
  Future<CategoryBudget?> getBudgetForCategory(String category) =>
      _budgetRepo.getBudgetForCategory(category);

  @override
  Future<int> insertBudget(CategoryBudgetsCompanion entry) =>
      _budgetRepo.insertBudget(entry);

  @override
  Future<void> updateBudget(int id, CategoryBudgetsCompanion entry) =>
      _budgetRepo.updateBudget(id, entry);

  @override
  Future<void> deleteBudget(int id) => _budgetRepo.deleteBudget(id);

  // ─── Goal delegates ────────────────────────────────

  @override
  Stream<List<SavingsGoal>> watchAllGoals() => _goalRepo.watchAllGoals();

  @override
  Future<SavingsGoal?> getGoal(int id) => _goalRepo.getGoal(id);

  @override
  Future<int> insertGoal(SavingsGoalsCompanion entry) =>
      _goalRepo.insertGoal(entry);

  @override
  Future<void> updateGoal(int id, SavingsGoalsCompanion entry) =>
      _goalRepo.updateGoal(id, entry);

  @override
  Future<void> addMoney(int id, double amount) =>
      _goalRepo.addMoney(id, amount);

  @override
  Future<void> deleteGoal(int id) => _goalRepo.deleteGoal(id);

  // ─── Person delegates ──────────────────────────────

  @override
  Stream<List<Person>> watchAllPersons() => _personRepo.watchAllPersons();

  @override
  Stream<List<Person>> watchByTag(String tag) => _personRepo.watchByTag(tag);

  @override
  Future<Person?> getPersonById(int id) => _personRepo.getPersonById(id);

  @override
  Future<int> createPerson(PersonsCompanion entry) => _personRepo.createPerson(entry);

  @override
  Future<void> updatePerson(int id, PersonsCompanion entry) =>
      _personRepo.updatePerson(id, entry);

  @override
  Future<void> deletePerson(int id) => _personRepo.deletePerson(id);

  @override
  Future<double> getPersonBalance(int personId) =>
      _personRepo.getPersonBalance(personId);

  @override
  Stream<double> watchPersonBalance(int personId) =>
      _personRepo.watchPersonBalance(personId);

  // ─── Group delegates ──────────────────────────────

  @override
  Stream<List<Group>> watchAllGroups() => _groupRepo.watchAllGroups();

  @override
  Future<Group?> getGroupById(int id) => _groupRepo.getGroupById(id);

  @override
  Future<int> createGroup(GroupsCompanion entry) => _groupRepo.createGroup(entry);

  @override
  Future<void> addGroupMember(int groupId, int personId) =>
      _groupRepo.addGroupMember(groupId, personId);

  @override
  Future<void> removeGroupMember(int groupId, int personId) =>
      _groupRepo.removeGroupMember(groupId, personId);

  @override
  Stream<List<GroupMember>> watchGroupMembers(int groupId) =>
      _groupRepo.watchGroupMembers(groupId);

  @override
  Future<void> archiveGroup(int groupId) => _groupRepo.archiveGroup(groupId);

  // ─── Split delegates ──────────────────────────────

  @override
  Future<void> createSplits(int txnId, List<SplitEntry> splits) =>
      _splitRepo.createSplits(txnId, splits);

  @override
  Stream<List<TransactionSplit>> watchSplitsForTransaction(int txnId) =>
      _splitRepo.watchSplitsForTransaction(txnId);

  @override
  Future<double> getBalanceForPerson(int personId) =>
      _splitRepo.getBalanceForPerson(personId);

  @override
  Stream<double> watchBalanceForPerson(int personId) =>
      _splitRepo.watchBalanceForPerson(personId);

  @override
  Stream<List<SpendlerTransaction>> watchTransactionsForPerson(int personId) =>
      _splitRepo.watchTransactionsForPerson(personId);

  // ─── Cross-cutting ────────────────────────────────

  @override
  Future<void> clearAll() async {
    await db.customStatement('DELETE FROM spendler_transactions');
    await db.customStatement('DELETE FROM family_entries');
    await db.customStatement('DELETE FROM weekly_reflections');
    await db.customStatement('DELETE FROM app_metrics');
    await db.customStatement('DELETE FROM app_notifications');
    await db.customStatement('DELETE FROM friend_splits');
    await db.customStatement('DELETE FROM friend_contacts');
    await db.customStatement('DELETE FROM category_budgets');
    await db.customStatement('DELETE FROM savings_goals');
    await db.customStatement('DELETE FROM subscriptions');
    await db.customStatement('DELETE FROM transaction_splits');
    await db.customStatement('DELETE FROM group_members');
    await db.customStatement('DELETE FROM groups');
    await db.customStatement('DELETE FROM persons');
  }
}

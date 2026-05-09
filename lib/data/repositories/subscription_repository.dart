import 'package:finance_buddy_app/data/db.dart';

abstract class SubscriptionRepository {
  Stream<List<Subscription>> watchAllSubscriptions();
  Stream<List<Subscription>> watchActiveSubscriptions();
  Future<Subscription?> getSubscriptionById(int id);
  Future<int> insertSubscription(SubscriptionsCompanion entry);
  Future<void> updateSubscription(int id, SubscriptionsCompanion entry);
  Future<void> toggleSubscriptionActive(int id, bool isActive);
  Future<void> deleteSubscription(int id);
  Future<double> getSubscriptionMonthlyTotal();
}

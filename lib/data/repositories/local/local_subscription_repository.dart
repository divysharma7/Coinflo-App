import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/subscription_repository.dart';

class LocalSubscriptionRepository implements SubscriptionRepository {
  final PaisaDatabase db;

  LocalSubscriptionRepository(this.db);

  @override
  Stream<List<Subscription>> watchAllSubscriptions() {
    return (db.select(db.subscriptions)
          ..orderBy([(s) => OrderingTerm.asc(s.nextBillingDate)]))
        .watch();
  }

  @override
  Stream<List<Subscription>> watchActiveSubscriptions() {
    return (db.select(db.subscriptions)
          ..where((s) => s.isActive.equals(true))
          ..orderBy([(s) => OrderingTerm.asc(s.nextBillingDate)]))
        .watch();
  }

  @override
  Future<Subscription?> getSubscriptionById(int id) {
    return (db.select(db.subscriptions)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<int> insertSubscription(SubscriptionsCompanion entry) {
    return db.into(db.subscriptions).insert(entry);
  }

  @override
  Future<void> updateSubscription(int id, SubscriptionsCompanion entry) {
    return (db.update(db.subscriptions)..where((s) => s.id.equals(id)))
        .write(entry);
  }

  @override
  Future<void> toggleSubscriptionActive(int id, bool isActive) {
    return (db.update(db.subscriptions)..where((s) => s.id.equals(id)))
        .write(SubscriptionsCompanion(isActive: Value(isActive)));
  }

  @override
  Future<void> deleteSubscription(int id) {
    return (db.delete(db.subscriptions)..where((s) => s.id.equals(id))).go();
  }

  @override
  Future<double> getSubscriptionMonthlyTotal() async {
    final subs = await (db.select(db.subscriptions)
          ..where((s) => s.isActive.equals(true)))
        .get();

    return subs.fold<double>(0, (sum, s) {
      switch (s.billingCycle) {
        case 'weekly':
          return sum + s.amount * 4.33; // avg weeks per month
        case 'yearly':
          return sum + s.amount / 12;
        case 'monthly':
        default:
          return sum + s.amount;
      }
    });
  }
}

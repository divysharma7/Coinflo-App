import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';

final allSubscriptionsProvider = StreamProvider<List<Subscription>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchAllSubscriptions();
});

final activeSubscriptionsProvider = StreamProvider<List<Subscription>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchActiveSubscriptions();
});

final subscriptionMonthlyTotalProvider = FutureProvider<double>((ref) {
  // Re-evaluate when the subscription list changes.
  ref.watch(allSubscriptionsProvider);
  final repo = ref.watch(repositoryProvider);
  return repo.getSubscriptionMonthlyTotal();
});

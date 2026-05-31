import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';

final allPersonsProvider = StreamProvider<List<Person>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchAllPersons();
});

final personsByTagProvider =
    StreamProvider.family<List<Person>, String>((ref, tag) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchByTag(tag);
});

final personBalanceProvider =
    StreamProvider.family<double, int>((ref, personId) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchPersonBalance(personId);
});

final personTransactionsProvider =
    StreamProvider.family<List<SpendlerTransaction>, int>((ref, personId) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchTransactionsForPerson(personId);
});

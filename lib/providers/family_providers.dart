import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';

final familyEntriesProvider = StreamProvider<List<FamilyEntry>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchAllFamilyEntries();
});

final familyInflowsProvider = StreamProvider<List<FamilyEntry>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchFamilyByType('inflow');
});

final familyOutflowsProvider = StreamProvider<List<FamilyEntry>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchFamilyByType('outflow');
});

final familyInvestmentsProvider = StreamProvider<List<FamilyEntry>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchFamilyByType('investment');
});

final totalFamilyWealthProvider = FutureProvider<double>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.getTotalWealth();
});

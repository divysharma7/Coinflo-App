import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
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

// ─── Mutation helpers ───────────────────────────────

/// Insert a family entry (inflow, outflow, or investment).
Future<void> insertFamilyEntry(
  BaseRepository repo, {
  required String type,
  required double amount,
  required String fromPerson,
  String? note,
  String? investmentType,
}) async {
  await repo.insertEntry(FamilyEntriesCompanion.insert(
    type: type,
    amount: amount,
    fromPerson: fromPerson,
    note: Value(note),
    investmentType: Value(investmentType),
  ));
}

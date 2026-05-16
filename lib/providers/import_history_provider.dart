import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/import_provider.dart';

/// Watches all import batches, ordered by most recent first.
/// NOT autoDispose — used in Settings, persists across navigation.
final importHistoryProvider = StreamProvider<List<ImportBatch>>((ref) {
  final repo = ref.watch(importRepositoryProvider);
  return repo.watchImportBatches();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/data/repositories/local/local_repository.dart';

final databaseProvider = Provider<SpendlerDatabase>((ref) {
  final db = SpendlerDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final repositoryProvider = Provider<BaseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalRepository(db);
});

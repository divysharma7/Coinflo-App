import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';

/// Persists the Saraswati chat conversation so it survives app restarts.
///
/// Follows the same direct-`SpendlerDatabase` pattern as the other Saraswati
/// repositories (intent cache, entry cache, personal defaults) rather than
/// going through `BaseRepository`. Messages older than [_ttl] are purged on
/// load so history never grows unbounded. (ISSUE 10)
class SaraswatiHistoryRepository {
  SaraswatiHistoryRepository(this._db);

  final SpendlerDatabase _db;

  static const _ttl = Duration(days: 7);

  /// Purge expired messages, then return the remaining history oldest-first.
  Future<List<SaraswatiMessageRow>> loadRecent() async {
    final cutoff = DateTime.now().subtract(_ttl);
    await (_db.delete(_db.saraswatiMessages)
          ..where((m) => m.createdAt.isSmallerThanValue(cutoff)))
        .go();
    return (_db.select(_db.saraswatiMessages)
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .get();
  }

  /// Replace the stored conversation with [messages] atomically. Cheap because
  /// chat histories are short and bounded by the 7-day TTL.
  Future<void> replaceAll(
    List<({String content, bool isUser, DateTime createdAt})> messages,
  ) async {
    await _db.transaction(() async {
      await _db.delete(_db.saraswatiMessages).go();
      for (final m in messages) {
        await _db.into(_db.saraswatiMessages).insert(
              SaraswatiMessagesCompanion.insert(
                content: m.content,
                isUser: m.isUser,
                createdAt: Value(m.createdAt),
              ),
            );
      }
    });
  }

  Future<void> clear() async {
    await _db.delete(_db.saraswatiMessages).go();
  }
}

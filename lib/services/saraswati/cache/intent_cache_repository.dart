import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/services/saraswati/intent/saraswati_intent.dart';

/// DDL for the intent cache table. Called from the v12 migration.
const kCreateIntentCacheTable = '''
CREATE TABLE IF NOT EXISTS saraswati_intent_cache (
  normalized_query TEXT PRIMARY KEY,
  intent_json TEXT NOT NULL,
  hit_count INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  last_used_at INTEGER NOT NULL,
  confirmed_by_user INTEGER NOT NULL DEFAULT 0
)
''';

const kCreateIntentCacheIndex = '''
CREATE INDEX IF NOT EXISTS idx_saraswati_cache_last_used
  ON saraswati_intent_cache(last_used_at)
''';

/// On-device cache mapping normalized query strings to classified intents.
///
/// Cache keys are normalized query strings (lowercase, trimmed, collapsed
/// whitespace). Values are serialized [SaraswatiIntent] objects.
class IntentCacheRepository {
  IntentCacheRepository(this._db);

  final SpendlerDatabase _db;

  /// Look up a cached intent for [normalizedQuery].
  ///
  /// On hit: bumps `hit_count` and updates `last_used_at`.
  /// On miss: returns `null`.
  Future<SaraswatiIntent?> lookup(String normalizedQuery) async {
    final rows = await _db.customSelect(
      'SELECT intent_json FROM saraswati_intent_cache '
      'WHERE normalized_query = ?',
      variables: [Variable.withString(normalizedQuery)],
    ).get();

    if (rows.isEmpty) return null;

    // Bump stats — don't block the response.
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customStatement(
      'UPDATE saraswati_intent_cache '
      'SET hit_count = hit_count + 1, last_used_at = ? '
      'WHERE normalized_query = ?',
      [now, normalizedQuery],
    );

    final json = jsonDecode(rows.first.data['intent_json'] as String)
        as Map<String, dynamic>;
    return SaraswatiIntent.fromJson(json);
  }

  /// Insert or replace a cached intent mapping.
  Future<void> insert(String normalizedQuery, SaraswatiIntent intent) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final intentJson = jsonEncode(intent.toJson());

    await _db.customStatement(
      'INSERT OR REPLACE INTO saraswati_intent_cache '
      '(normalized_query, intent_json, hit_count, created_at, last_used_at, confirmed_by_user) '
      'VALUES (?, ?, 1, ?, ?, 0)',
      [normalizedQuery, intentJson, now, now],
    );
  }

  /// Mark a cached entry as confirmed by the user.
  Future<void> confirm(String normalizedQuery) async {
    await _db.customStatement(
      'UPDATE saraswati_intent_cache SET confirmed_by_user = 1 '
      'WHERE normalized_query = ?',
      [normalizedQuery],
    );
  }

  /// Delete a cached entry (triggered by user correction).
  Future<void> invalidate(String normalizedQuery) async {
    await _db.customStatement(
      'DELETE FROM saraswati_intent_cache WHERE normalized_query = ?',
      [normalizedQuery],
    );
  }

  /// Return recent user-confirmed queries for Stage 0 exact matching.
  Future<List<String>> recentConfirmedQueries({int limit = 20}) async {
    final rows = await _db.customSelect(
      'SELECT normalized_query FROM saraswati_intent_cache '
      'WHERE confirmed_by_user = 1 '
      'ORDER BY last_used_at DESC LIMIT ?',
      variables: [Variable.withInt(limit)],
    ).get();

    return rows.map((r) => r.data['normalized_query'] as String).toList();
  }
}

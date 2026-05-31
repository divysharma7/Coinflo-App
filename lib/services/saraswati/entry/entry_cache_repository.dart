import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/services/saraswati/entry/transaction_draft.dart';

/// DDL for the entry cache table. Called from the v13 migration.
const kCreateEntryCacheTable = '''
CREATE TABLE IF NOT EXISTS saraswati_entry_cache (
  normalized_input  TEXT     PRIMARY KEY,
  draft_json        TEXT     NOT NULL,
  hit_count         INTEGER  NOT NULL DEFAULT 1,
  created_at        INTEGER  NOT NULL,
  last_used_at      INTEGER  NOT NULL,
  confirmed_by_user INTEGER  NOT NULL DEFAULT 0
)
''';

const kCreateEntryCacheIndex = '''
CREATE INDEX IF NOT EXISTS idx_saraswati_entry_cache_last_used
  ON saraswati_entry_cache(last_used_at)
''';

/// On-device cache mapping normalized entry strings to extracted drafts.
///
/// Structurally identical to [IntentCacheRepository]. Cache keys are
/// normalized input strings. Values are serialized [TransactionDraft] objects.
class EntryCacheRepository {
  EntryCacheRepository(this._db);

  final SpendlerDatabase _db;

  /// Look up a cached draft for [normalizedInput].
  ///
  /// On hit: bumps `hit_count` and updates `last_used_at`.
  /// On hit: re-resolves date to today (cached "today" must mean current day).
  /// On miss: returns `null`.
  Future<TransactionDraft?> lookup(String normalizedInput) async {
    final rows = await _db.customSelect(
      'SELECT draft_json FROM saraswati_entry_cache '
      'WHERE normalized_input = ?',
      variables: [Variable.withString(normalizedInput)],
    ).get();

    if (rows.isEmpty) return null;

    // Bump stats — don't block the response.
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customStatement(
      'UPDATE saraswati_entry_cache '
      'SET hit_count = hit_count + 1, last_used_at = ? '
      'WHERE normalized_input = ?',
      [now, normalizedInput],
    );

    final json = jsonDecode(rows.first.data['draft_json'] as String)
        as Map<String, dynamic>;
    final draft = TransactionDraft.fromJson(json);

    // Re-resolve date to today — a cached entry's "today" must be current.
    return draft.copyWith(date: () => DateTime.now());
  }

  /// Insert or replace a cached draft mapping.
  Future<void> insert(
      String normalizedInput, TransactionDraft draft) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final draftJson = jsonEncode(draft.toJson());

    await _db.customStatement(
      'INSERT OR REPLACE INTO saraswati_entry_cache '
      '(normalized_input, draft_json, hit_count, created_at, last_used_at, confirmed_by_user) '
      'VALUES (?, ?, 1, ?, ?, 0)',
      [normalizedInput, draftJson, now, now],
    );
  }

  /// Mark a cached entry as confirmed by the user.
  Future<void> confirm(String normalizedInput) async {
    await _db.customStatement(
      'UPDATE saraswati_entry_cache SET confirmed_by_user = 1 '
      'WHERE normalized_input = ?',
      [normalizedInput],
    );
  }

  /// Delete a cached entry (triggered by user correction).
  Future<void> invalidate(String normalizedInput) async {
    await _db.customStatement(
      'DELETE FROM saraswati_entry_cache WHERE normalized_input = ?',
      [normalizedInput],
    );
  }
}

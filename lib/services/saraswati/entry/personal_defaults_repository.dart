import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';

/// DDL for the user defaults table. Called from the v13 migration.
const kCreateUserDefaultsTable = '''
CREATE TABLE IF NOT EXISTS saraswati_user_defaults (
  key         TEXT     PRIMARY KEY,
  value       TEXT     NOT NULL,
  hit_count   INTEGER  NOT NULL DEFAULT 1,
  updated_at  INTEGER  NOT NULL
)
''';

/// Stores personal patterns learned from confirmed transactions.
///
/// Keys follow the format `counterparty:<name>` or `category_for:<merchant>`.
/// Values are the learned default (e.g. `split_equal`, `household`).
class PersonalDefaultsRepository {
  PersonalDefaultsRepository(this._db);

  final SpendlerDatabase _db;

  /// Get the learned default for [key], or null if not learned.
  Future<String?> getDefault(String key) async {
    final rows = await _db.customSelect(
      'SELECT value FROM saraswati_user_defaults WHERE key = ?',
      variables: [Variable.withString(key)],
    ).get();

    if (rows.isEmpty) return null;
    return rows.first.data['value'] as String;
  }

  /// Insert or update a learned default, bumping hit_count.
  Future<void> updateDefault(String key, String value) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customStatement(
      'INSERT INTO saraswati_user_defaults (key, value, hit_count, updated_at) '
      'VALUES (?, ?, 1, ?) '
      'ON CONFLICT(key) DO UPDATE SET '
      'value = excluded.value, '
      'hit_count = hit_count + 1, '
      'updated_at = excluded.updated_at',
      [key, value, now],
    );
  }

  /// Get all learned defaults as a map.
  Future<Map<String, String>> getAllDefaults() async {
    final rows = await _db.customSelect(
      'SELECT key, value FROM saraswati_user_defaults ORDER BY hit_count DESC',
    ).get();

    return {
      for (final row in rows)
        row.data['key'] as String: row.data['value'] as String,
    };
  }
}

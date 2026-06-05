import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:intl/intl.dart';

// ─── Parsed row model ────────────────────────────────────

class ParsedRow {
  final DateTime date;
  final double amount;
  final String type; // 'expense' or 'income'
  final String category;
  final String? source;
  final String? note;
  final String? error;

  const ParsedRow({
    required this.date,
    required this.amount,
    required this.type,
    required this.category,
    this.source,
    this.note,
    this.error,
  });

  bool get isValid => error == null;

  /// Stable key for duplicate detection: day + absolute amount + description.
  String get dedupeKey {
    final day = DateTime(date.year, date.month, date.day);
    final desc = (note ?? '').trim().toLowerCase();
    return '${day.toIso8601String()}|${amount.abs().toStringAsFixed(2)}|$desc';
  }
}

// ─── Validation error for a row ──────────────────────────

class RowError {
  final int row;
  final String message;
  const RowError(this.row, this.message);
}

// ─── Raw sheet (pre-mapping) ─────────────────────────────

/// Tabular data read from a file before column mapping is applied.
class RawSheet {
  final List<String> headers;
  final List<List<String>> rows; // data rows, excluding the header
  const RawSheet({required this.headers, required this.rows});

  bool get isEmpty => headers.isEmpty || rows.isEmpty;
}

// ─── Column mapping ──────────────────────────────────────

/// Maps each logical field to a column index in the raw sheet.
/// `-1` means "not mapped" (only valid for the optional source/note fields).
class ColumnMapping {
  final int date;
  final int amount;
  final int type;
  final int category;
  final int source;
  final int note;

  const ColumnMapping({
    required this.date,
    required this.amount,
    required this.type,
    required this.category,
    this.source = -1,
    this.note = -1,
  });

  bool get isComplete =>
      date >= 0 && amount >= 0 && type >= 0 && category >= 0;

  ColumnMapping copyWith({
    int? date,
    int? amount,
    int? type,
    int? category,
    int? source,
    int? note,
  }) =>
      ColumnMapping(
        date: date ?? this.date,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        category: category ?? this.category,
        source: source ?? this.source,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'amount': amount,
        'type': type,
        'category': category,
        'source': source,
        'note': note,
      };

  factory ColumnMapping.fromJson(Map<String, dynamic> j) => ColumnMapping(
        date: (j['date'] as num?)?.toInt() ?? -1,
        amount: (j['amount'] as num?)?.toInt() ?? -1,
        type: (j['type'] as num?)?.toInt() ?? -1,
        category: (j['category'] as num?)?.toInt() ?? -1,
        source: (j['source'] as num?)?.toInt() ?? -1,
        note: (j['note'] as num?)?.toInt() ?? -1,
      );
}

// ─── Parse result ────────────────────────────────────────

class ExcelParseResult {
  final List<ParsedRow> rows;
  final List<RowError> errors;
  const ExcelParseResult({required this.rows, required this.errors});
}

// ─── Service ─────────────────────────────────────────────

class ExcelImportService {
  /// Max accepted file size (10 MB).
  static const int maxFileBytes = 10 * 1024 * 1024;

  static const Set<String> allowedExtensions = {'xlsx', 'csv'};

  /// Logical fields the wizard maps, in display order.
  static const List<({String key, String label, bool required})> fields = [
    (key: 'date', label: 'Date', required: true),
    (key: 'amount', label: 'Amount', required: true),
    (key: 'type', label: 'Type', required: true),
    (key: 'category', label: 'Category', required: true),
    (key: 'source', label: 'Source', required: false),
    (key: 'note', label: 'Note', required: false),
  ];

  // ─── Step 1/2: read raw rows ──────────────────────────

  /// Reads an .xlsx or .csv file into a [RawSheet] of stringified cells.
  RawSheet readRawSheet(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    final List<List<String>> table;
    if (ext == 'csv') {
      table = _readCsv(file);
    } else {
      table = _readXlsx(file);
    }
    if (table.isEmpty) return const RawSheet(headers: [], rows: []);
    final headers = table.first.map((c) => c.trim()).toList();
    final rows = table.skip(1).toList();
    return RawSheet(headers: headers, rows: rows);
  }

  List<List<String>> _readXlsx(File file) {
    try {
      final excel = Excel.decodeBytes(file.readAsBytesSync());
      if (excel.tables.isEmpty) return [];
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) return [];
      return sheet.rows
          .map((row) =>
              row.map((cell) => cell?.value?.toString().trim() ?? '').toList())
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<List<String>> _readCsv(File file) {
    final raw = const CsvToListConverter(shouldParseNumbers: false)
        .convert(file.readAsStringSync());
    return raw
        .map((row) => row.map((c) => c.toString().trim()).toList())
        .toList();
  }

  /// Best-effort mapping of detected headers to logical fields by name.
  ColumnMapping autoDetect(List<String> headers) {
    final lowered = headers.map((h) => h.toLowerCase().trim()).toList();
    int find(List<String> aliases) {
      for (final a in aliases) {
        final idx = lowered.indexOf(a);
        if (idx >= 0) return idx;
      }
      return -1;
    }

    return ColumnMapping(
      date: find(['date', 'when', 'transaction date']),
      amount: find(['amount', 'value', 'amt']),
      type: find(['type', 'kind', 'direction']),
      category: find(['category', 'cat']),
      source: find(['source', 'account']),
      note: find(['note', 'description', 'merchant', 'memo', 'notes']),
    );
  }

  // ─── Step 2/3: parse with a mapping ───────────────────

  /// Validates [sheet] rows using [mapping] and returns valid rows + errors.
  ExcelParseResult parseRows(RawSheet sheet, ColumnMapping mapping) {
    if (!mapping.isComplete) {
      return const ExcelParseResult(
        rows: [],
        errors: [RowError(0, 'Map Date, Amount, Type and Category first')],
      );
    }

    final rows = <ParsedRow>[];
    final errors = <RowError>[];

    for (var i = 0; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final allEmpty = row.every((c) => c.trim().isEmpty);
      if (allEmpty) continue;

      final rowNum = i + 2; // +1 for header, +1 for 1-indexing

      final dateCell = _cell(row, mapping.date);
      final date = _parseDate(dateCell);
      if (date == null) {
        errors.add(RowError(rowNum, 'Invalid date: "$dateCell"'));
        continue;
      }

      final amountCell = _cell(row, mapping.amount);
      final amount = double.tryParse(amountCell.replaceAll(',', ''));
      if (amount == null || amount <= 0) {
        errors.add(RowError(rowNum, 'Invalid amount: "$amountCell"'));
        continue;
      }

      final typeCell = _cell(row, mapping.type).toLowerCase();
      if (typeCell != 'expense' && typeCell != 'income') {
        errors.add(RowError(
            rowNum, 'Type must be "expense" or "income", got "$typeCell"'));
        continue;
      }

      final categoryCell = _cell(row, mapping.category);
      final resolvedCategory = _resolveCategory(categoryCell, typeCell);
      if (resolvedCategory == null) {
        errors.add(RowError(rowNum, 'Unknown category: "$categoryCell"'));
        continue;
      }

      final source = mapping.source >= 0 ? _cell(row, mapping.source) : null;
      final note = mapping.note >= 0 ? _cell(row, mapping.note) : null;

      rows.add(ParsedRow(
        date: date,
        amount: amount,
        type: typeCell,
        category: resolvedCategory,
        source: source != null && source.isNotEmpty ? source : null,
        note: note != null && note.isNotEmpty ? note : null,
      ));
    }

    return ExcelParseResult(rows: rows, errors: errors);
  }

  // ─── Step 3: duplicate detection ──────────────────────

  /// Returns the set of indices in [rows] that match an existing transaction
  /// (same day + absolute amount + description).
  Set<int> findDuplicateIndices(
    List<ParsedRow> rows,
    List<SpendlerTransaction> existing,
  ) {
    final existingKeys = <String>{
      for (final t in existing)
        () {
          final day = DateTime(
              t.happenedAt.year, t.happenedAt.month, t.happenedAt.day);
          final desc = (t.note ?? t.merchant ?? '').trim().toLowerCase();
          return '${day.toIso8601String()}|${t.amount.abs().toStringAsFixed(2)}|$desc';
        }(),
    };

    final dupes = <int>{};
    for (var i = 0; i < rows.length; i++) {
      if (existingKeys.contains(rows[i].dedupeKey)) dupes.add(i);
    }
    return dupes;
  }

  // ─── Step 4: atomic import ────────────────────────────

  /// Inserts all valid rows whose index is NOT in [skip], inside a single
  /// database transaction so the import is all-or-nothing. Returns the count.
  Future<int> bulkInsert(
    List<ParsedRow> rows,
    SpendlerDatabase db, {
    Set<int> skip = const {},
  }) async {
    var count = 0;
    await db.transaction(() async {
      for (var i = 0; i < rows.length; i++) {
        if (skip.contains(i)) continue;
        final row = rows[i];
        if (!row.isValid) continue;

        final isIncome = row.type == 'income';
        await db.into(db.spendlerTransactions).insert(
              SpendlerTransactionsCompanion.insert(
                amount: isIncome ? row.amount : -row.amount.abs(),
                category: isIncome ? 'income' : row.category,
                merchant: Value(row.note),
                note: Value(row.note),
                happenedAt: Value(row.date),
                source: const Value('excel'),
                status: const Value('confirmed'),
                incomeSource:
                    Value(isIncome ? (row.source ?? 'other') : null),
              ),
            );
        count++;
      }
    });
    return count;
  }

  // ─── Helpers ───────────────────────────────────────────

  String _cell(List<String> row, int idx) {
    if (idx < 0 || idx >= row.length) return '';
    return row[idx].trim();
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    for (final fmt in ['dd/MM/yyyy', 'yyyy-MM-dd', 'MM/dd/yyyy', 'dd-MM-yyyy']) {
      try {
        return DateFormat(fmt).parseStrict(value);
      } on FormatException catch (_) {
        // try next
      }
    }
    return DateTime.tryParse(value);
  }

  /// Maps a user-typed category string to a TransactionCategory enum name.
  String? _resolveCategory(String input, String type) {
    if (type == 'income') return 'income';
    final lower = input.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    for (final cat in TransactionCategory.groups) {
      final catLower = cat.label.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (catLower == lower) return cat.name;
      if (cat.name.toLowerCase() == lower) return cat.name;
    }
    return null;
  }
}

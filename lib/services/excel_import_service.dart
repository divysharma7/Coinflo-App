import 'dart:io';

import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
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
}

// ─── Validation error for a row ──────────────────────────

class RowError {
  final int row;
  final String message;
  const RowError(this.row, this.message);
}

// ─── Parse result ────────────────────────────────────────

class ExcelParseResult {
  final List<ParsedRow> rows;
  final List<RowError> errors;
  const ExcelParseResult({required this.rows, required this.errors});
}

// ─── Service ─────────────────────────────────────────────

class ExcelImportService {
  static const _requiredHeaders = ['date', 'amount', 'type', 'category'];

  /// Parses an xlsx file and returns valid rows + validation errors.
  ExcelParseResult parseFile(File file) {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null || sheet.rows.isEmpty) {
      return const ExcelParseResult(rows: [], errors: [RowError(0, 'Empty spreadsheet')]);
    }

    // Read header row
    final headerRow = sheet.rows.first;
    final headers = headerRow
        .map((Data? cell) => cell?.value?.toString().trim().toLowerCase() ?? '')
        .toList();

    // Validate required headers
    for (final h in _requiredHeaders) {
      if (!headers.contains(h)) {
        return ExcelParseResult(
          rows: [],
          errors: [RowError(0, 'Missing required column: $h')],
        );
      }
    }

    final dateIdx = headers.indexOf('date');
    final amountIdx = headers.indexOf('amount');
    final typeIdx = headers.indexOf('type');
    final categoryIdx = headers.indexOf('category');
    final sourceIdx = headers.indexOf('source');
    final noteIdx = headers.indexOf('note');

    final rows = <ParsedRow>[];
    final errors = <RowError>[];

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];

      // Skip entirely empty rows
      final allEmpty = row.every((Data? c) => c == null || c.value == null || c.value.toString().trim().isEmpty);
      if (allEmpty) continue;

      final rowNum = i + 1; // 1-indexed for user display

      // Parse date
      final dateCell = _cellString(row, dateIdx);
      final date = _parseDate(dateCell);
      if (date == null) {
        errors.add(RowError(rowNum, 'Invalid date: "$dateCell"'));
        continue;
      }

      // Parse amount
      final amountCell = _cellString(row, amountIdx);
      final amount = double.tryParse(amountCell.replaceAll(',', ''));
      if (amount == null || amount <= 0) {
        errors.add(RowError(rowNum, 'Invalid amount: "$amountCell"'));
        continue;
      }

      // Parse type
      final typeCell = _cellString(row, typeIdx).toLowerCase();
      if (typeCell != 'expense' && typeCell != 'income') {
        errors.add(RowError(rowNum, 'Type must be "expense" or "income", got "$typeCell"'));
        continue;
      }

      // Parse category
      final categoryCell = _cellString(row, categoryIdx);
      final resolvedCategory = _resolveCategory(categoryCell, typeCell);
      if (resolvedCategory == null) {
        errors.add(RowError(rowNum, 'Unknown category: "$categoryCell"'));
        continue;
      }

      final source = sourceIdx >= 0 ? _cellString(row, sourceIdx) : null;
      final note = noteIdx >= 0 ? _cellString(row, noteIdx) : null;

      rows.add(ParsedRow(
        date: date,
        amount: amount,
        type: typeCell,
        category: resolvedCategory,
        source: source?.isNotEmpty == true ? source : null,
        note: note?.isNotEmpty == true ? note : null,
      ));
    }

    return ExcelParseResult(rows: rows, errors: errors);
  }

  /// Inserts all valid rows into the database. Returns inserted count.
  Future<int> bulkInsert(List<ParsedRow> rows, BaseRepository repo) async {
    var count = 0;
    for (final row in rows) {
      if (!row.isValid) continue;

      final isIncome = row.type == 'income';
      final companion = SpendlerTransactionsCompanion.insert(
        amount: isIncome ? row.amount : -row.amount.abs(),
        category: isIncome ? 'income' : row.category,
        merchant: Value(row.note),
        note: Value(row.note),
        happenedAt: Value(row.date),
        source: const Value('excel'),
        status: const Value('confirmed'),
        incomeSource: Value(isIncome ? (row.source ?? 'other') : null),
      );
      await repo.insertTransaction(companion);
      count++;
    }
    return count;
  }

  // ─── Helpers ───────────────────────────────────────────

  String _cellString(List<Data?> row, int idx) {
    if (idx < 0 || idx >= row.length) return '';
    return row[idx]?.value?.toString().trim() ?? '';
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;

    // Try common formats
    for (final fmt in ['dd/MM/yyyy', 'yyyy-MM-dd', 'MM/dd/yyyy', 'dd-MM-yyyy']) {
      try {
        return DateFormat(fmt).parseStrict(value);
      } on FormatException catch (_) {
        // try next
      }
    }

    // Try Dart's built-in parser as fallback
    return DateTime.tryParse(value);
  }

  /// Maps a user-typed category string to a TransactionCategory enum name.
  String? _resolveCategory(String input, String type) {
    if (type == 'income') return 'income';

    final lower = input.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

    // Build a lookup: label (lowered, alphanumeric only) -> enum name
    for (final cat in TransactionCategory.groups) {
      final catLower = cat.label.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (catLower == lower) return cat.name;
      // Also match the raw enum name
      if (cat.name.toLowerCase() == lower) return cat.name;
    }

    return null;
  }
}

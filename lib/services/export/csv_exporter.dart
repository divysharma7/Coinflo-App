import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';

/// Generates a CSV string from a list of [SpendlerTransaction] objects and
/// shares it as a `.csv` file using the system share sheet.
class CsvExporter {
  CsvExporter._();

  static final _dateFmt = DateFormat('yyyy-MM-dd HH:mm');

  /// Build a CSV string with headers:
  /// Date, Merchant, Category, Amount, Note, Type
  static String generateCsv(List<SpendlerTransaction> transactions) {
    final buf = StringBuffer();
    buf.writeln('Date,Merchant,Category,Amount,Note,Type');

    for (final t in transactions) {
      final date = _dateFmt.format(t.happenedAt);
      final merchant = _escape(t.merchant ?? '');
      final cat = TransactionCategory.values
          .firstWhere(
            (c) => c.name == t.category,
            orElse: () => TransactionCategory.other,
          )
          .label;
      final amount = t.amount.abs().toStringAsFixed(2);
      final note = _escape(t.note ?? '');
      final type = t.amount < 0 ? 'Expense' : 'Income';

      buf.writeln('$date,$merchant,$cat,$amount,$note,$type');
    }

    return buf.toString();
  }

  /// Write the CSV to a temp file and open the system share sheet.
  static Future<void> exportAndShare(
    List<SpendlerTransaction> transactions,
    String monthLabel,
  ) async {
    final csv = generateCsv(transactions);
    final dir = await getTemporaryDirectory();
    final safeName = monthLabel.replaceAll(' ', '_').toLowerCase();
    final file = File('${dir.path}/coinflo_$safeName.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'CoinFlo Report - $monthLabel',
    );
  }

  /// Escape a field value for CSV: wrap in quotes if it contains commas,
  /// quotes, or newlines, doubling any internal quotes.
  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

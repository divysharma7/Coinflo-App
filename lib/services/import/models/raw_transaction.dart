import 'package:finance_buddy_app/core/enums.dart';

/// Raw transaction as parsed directly from a bank CSV row.
/// No normalization or categorization applied yet.
class RawTransaction {
  final DateTime date;
  final double amount;
  final String type; // 'debit' or 'credit'
  final String rawDescription;
  final BankType sourceBank;
  final String? referenceNumber;

  const RawTransaction({
    required this.date,
    required this.amount,
    required this.type,
    required this.rawDescription,
    required this.sourceBank,
    this.referenceNumber,
  });

  @override
  String toString() =>
      'RawTransaction($date, $type, $amount, "$rawDescription")';
}

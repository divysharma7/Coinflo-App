import 'package:finance_buddy_app/core/enums.dart';

/// Raw transaction description for normalization.
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

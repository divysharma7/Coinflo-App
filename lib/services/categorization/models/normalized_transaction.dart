import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/categorization/models/raw_transaction.dart';

/// Channel through which the transaction was made.
enum TransactionChannel { upi, pos, neft, imps, atm, other }

/// A transaction after normalization: cleaned description, extracted tokens,
/// channel detection. Ready for categorization.
class NormalizedTransaction {
  final DateTime date;
  final double amount;
  final String type; // 'debit' or 'credit'
  final String rawDescription;
  final String cleanedDescription;
  final String merchantToken;
  final TransactionChannel channel;
  final String rawHash;
  final BankType sourceBank;
  final String? referenceNumber;

  const NormalizedTransaction({
    required this.date,
    required this.amount,
    required this.type,
    required this.rawDescription,
    required this.cleanedDescription,
    required this.merchantToken,
    required this.channel,
    required this.rawHash,
    required this.sourceBank,
    this.referenceNumber,
  });

  /// Construct from a RawTransaction + normalizer outputs.
  factory NormalizedTransaction.fromRaw({
    required RawTransaction raw,
    required String cleanedDescription,
    required String merchantToken,
    required TransactionChannel channel,
    required String rawHash,
  }) {
    return NormalizedTransaction(
      date: raw.date,
      amount: raw.amount,
      type: raw.type,
      rawDescription: raw.rawDescription,
      cleanedDescription: cleanedDescription,
      merchantToken: merchantToken,
      channel: channel,
      rawHash: rawHash,
      sourceBank: raw.sourceBank,
      referenceNumber: raw.referenceNumber,
    );
  }

  @override
  String toString() =>
      'NormalizedTransaction($date, $channel, "$merchantToken", $amount)';
}

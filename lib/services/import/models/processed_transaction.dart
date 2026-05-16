import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/import/models/normalized_transaction.dart';

/// A fully processed transaction ready for DB insertion.
/// Contains categorization result + detection flags.
class ProcessedTransaction {
  final DateTime date;
  final double amount;
  final String type;
  final String rawDescription;
  final String cleanedDescription;
  final String merchantToken;
  final String channel;
  final String rawHash;
  final BankType sourceBank;
  final String? referenceNumber;

  // Categorization
  final String? category; // TransactionCategory enum name, null if uncategorized
  final CategorizationSource categorizationSource;
  final double categorizationConfidence;

  // Detection flags
  final bool isRecurring;
  final bool isAnomaly;

  // Dedup
  final bool isDuplicate;

  // DB-assigned ID (populated after persist phase, null during isolate processing)
  final int? dbId;

  const ProcessedTransaction({
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
    this.category,
    required this.categorizationSource,
    required this.categorizationConfidence,
    this.isRecurring = false,
    this.isAnomaly = false,
    this.isDuplicate = false,
    this.dbId,
  });

  ProcessedTransaction copyWith({
    String? category,
    CategorizationSource? categorizationSource,
    double? categorizationConfidence,
    bool? isRecurring,
    bool? isAnomaly,
    bool? isDuplicate,
    int? dbId,
  }) {
    return ProcessedTransaction(
      date: date,
      amount: amount,
      type: type,
      rawDescription: rawDescription,
      cleanedDescription: cleanedDescription,
      merchantToken: merchantToken,
      channel: channel,
      rawHash: rawHash,
      sourceBank: sourceBank,
      referenceNumber: referenceNumber,
      category: category ?? this.category,
      categorizationSource: categorizationSource ?? this.categorizationSource,
      categorizationConfidence:
          categorizationConfidence ?? this.categorizationConfidence,
      isRecurring: isRecurring ?? this.isRecurring,
      isAnomaly: isAnomaly ?? this.isAnomaly,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      dbId: dbId ?? this.dbId,
    );
  }

  /// Convert from a NormalizedTransaction + categorization result.
  factory ProcessedTransaction.fromNormalized({
    required NormalizedTransaction normalized,
    required String? category,
    required CategorizationSource source,
    required double confidence,
  }) {
    return ProcessedTransaction(
      date: normalized.date,
      amount: normalized.amount,
      type: normalized.type,
      rawDescription: normalized.rawDescription,
      cleanedDescription: normalized.cleanedDescription,
      merchantToken: normalized.merchantToken,
      channel: normalized.channel.name,
      rawHash: normalized.rawHash,
      sourceBank: normalized.sourceBank,
      referenceNumber: normalized.referenceNumber,
      category: category,
      categorizationSource: source,
      categorizationConfidence: confidence,
    );
  }
}

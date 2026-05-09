import 'package:drift/drift.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/base_repository.dart';
import 'package:finance_buddy_app/services/sms/sms_categorizer.dart';
import 'package:finance_buddy_app/services/sms/sms_parser.dart';

class SmsProcessor {
  final BaseRepository repository;

  SmsProcessor(this.repository);

  /// Process a raw SMS body. Returns true if a transaction was created.
  Future<bool> process(String smsBody) async {
    final parsed = SmsParser.parse(smsBody);
    if (parsed == null) return false;

    final category = SmsCategorizer.categorize(parsed);

    // Store as negative amount for debits
    final amount = parsed.isDebit ? -parsed.amount : parsed.amount;

    await repository.insertTransaction(PaisaTransactionsCompanion.insert(
      amount: amount,
      category: category.name,
      merchant: Value(parsed.merchant),
      happenedAt: Value(parsed.receivedAt),
      source: const Value('sms_auto'),
      status: const Value('unconfirmed'),
    ));

    // If it's a credit and we have unsettled splits, it might be a settlement
    if (!parsed.isDebit) {
      final unsettled = await repository.getUnsettledSplits();
      if (unsettled.isNotEmpty) {
        // Check if any pending amount roughly matches
        for (final split in unsettled) {
          if (split.splitPendingAmount != null &&
              (split.splitPendingAmount! - parsed.amount).abs() < 5) {
            // Close match — flag for user confirmation via notification
            // The notification service handles this separately
            break;
          }
        }
      }
    }

    return true;
  }
}

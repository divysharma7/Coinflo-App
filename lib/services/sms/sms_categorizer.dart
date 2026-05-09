import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/models/parsed_sms.dart';

class SmsCategorizer {
  static const _merchantRules = <String, TransactionCategory>{
    'uber': TransactionCategory.transport,
    'ola': TransactionCategory.transport,
    'rapido': TransactionCategory.transport,
    'metro': TransactionCategory.transport,
    'irctc': TransactionCategory.transport,
    'swiggy': TransactionCategory.food,
    'zomato': TransactionCategory.food,
    'blinkit': TransactionCategory.food,
    'zepto': TransactionCategory.food,
    'bigbasket': TransactionCategory.food,
    'instamart': TransactionCategory.food,
    'dominos': TransactionCategory.food,
    'mcdonald': TransactionCategory.food,
    'starbucks': TransactionCategory.food,
    'bookmyshow': TransactionCategory.entertainment,
    'pvr': TransactionCategory.entertainment,
    'inox': TransactionCategory.entertainment,
  };

  static TransactionCategory categorize(ParsedSms sms) {
    // Credit from someone → likely family
    if (!sms.isDebit) {
      return TransactionCategory.other;
    }

    // Merchant keyword matching
    if (sms.merchant != null) {
      final merchantLower = sms.merchant!.toLowerCase();
      for (final entry in _merchantRules.entries) {
        if (merchantLower.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    // Amount-based heuristics
    final day = sms.receivedAt.day;
    if (sms.amount >= 15000 && sms.amount <= 50000 && day <= 5) {
      return TransactionCategory.housing;
    }

    return TransactionCategory.other;
  }
}

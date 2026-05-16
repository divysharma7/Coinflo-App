import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/categorization/categorization_service.dart';
import 'package:finance_buddy_app/services/categorization/merchant_dictionary.dart';
import 'package:finance_buddy_app/services/import/models/normalized_transaction.dart';

void main() {
  late MerchantDictionary dictionary;

  setUp(() {
    dictionary = MerchantDictionary();
    dictionary.loadFromString('''[
      {"token": "swiggy", "category": "foodAndDrink", "confidence": 0.95},
      {"token": "zomato", "category": "foodAndDrink", "confidence": 0.93},
      {"token": "uber", "category": "transport", "confidence": 0.9},
      {"token": "netflix", "category": "entertainment", "confidence": 0.95}
    ]''');
  });

  NormalizedTransaction _makeTxn({
    String rawDescription = '',
    String cleanedDescription = '',
    String merchantToken = '',
    TransactionChannel channel = TransactionChannel.other,
  }) {
    return NormalizedTransaction(
      date: DateTime(2026, 1, 15),
      amount: 500.0,
      type: 'debit',
      rawDescription: rawDescription,
      cleanedDescription: cleanedDescription,
      merchantToken: merchantToken,
      channel: channel,
      rawHash: 'test-hash',
      sourceBank: BankType.hdfc,
    );
  }

  group('Stage ordering', () {
    test('Stage 0: SmartRules wins over everything', () {
      final service = CategorizationService(
        smartRules: [SmartRuleData(keyword: 'uber', category: 'shopping')],
        userMerchantMap: {
          'uber': const MerchantMappingData(
              category: 'transport', source: 'userCorrected', confidence: 1.0)
        },
        dictionary: dictionary,
      );

      final result = service.categorize(_makeTxn(
        rawDescription: 'UPI-UBER-uber@icici',
        merchantToken: 'uber',
      ));

      expect(result.category, 'shopping'); // SmartRule wins
      expect(result.source, CategorizationSource.smartRule);
      expect(result.confidence, 1.0);
    });

    test('Stage 1: User correction wins over dictionary', () {
      final service = CategorizationService(
        smartRules: [],
        userMerchantMap: {
          'swiggy': const MerchantMappingData(
              category: 'shopping', source: 'userCorrected', confidence: 1.0)
        },
        dictionary: dictionary,
      );

      final result = service.categorize(_makeTxn(
        rawDescription: 'UPI SWIGGY',
        merchantToken: 'swiggy',
      ));

      expect(result.category, 'shopping'); // User correction, not dictionary's foodAndDrink
      expect(result.source, CategorizationSource.user);
    });

    test('Stage 2: Dictionary used when no user correction', () {
      final service = CategorizationService(
        smartRules: [],
        userMerchantMap: {},
        dictionary: dictionary,
      );

      final result = service.categorize(_makeTxn(
        rawDescription: 'POS SWIGGY',
        merchantToken: 'swiggy',
      ));

      expect(result.category, 'foodAndDrink');
      expect(result.source, CategorizationSource.dictionary);
    });

    test('Stage 3: UPI parsing used for UPI channel', () {
      final service = CategorizationService(
        smartRules: [],
        userMerchantMap: {},
        dictionary: dictionary, // Has swiggy
      );

      final result = service.categorize(_makeTxn(
        rawDescription: 'UPI-swiggy@axisbank',
        merchantToken: 'unknownmerchant', // token doesn't match dictionary
        channel: TransactionChannel.upi,
      ));

      // UPI parser looks up the VPA prefix 'swiggy' in dictionary
      expect(result.category, 'foodAndDrink');
      expect(result.source, CategorizationSource.upi);
    });

    test('Stage 4: Rule engine used as fallback', () {
      final service = CategorizationService(
        smartRules: [],
        userMerchantMap: {},
        dictionary: dictionary,
      );

      final result = service.categorize(_makeTxn(
        rawDescription: 'BESCOM ELECTRICITY BILL',
        cleanedDescription: 'bescom electricity bill',
        merchantToken: 'bescom', // Not in dictionary
      ));

      expect(result.category, 'billsAndUtilities');
      expect(result.source, CategorizationSource.rule);
    });

    test('Stage 5: Returns uncategorized when nothing matches', () {
      final service = CategorizationService(
        smartRules: [],
        userMerchantMap: {},
        dictionary: dictionary,
      );

      final result = service.categorize(_makeTxn(
        rawDescription: 'random unknown transaction',
        cleanedDescription: 'random unknown transaction',
        merchantToken: 'randomxyz',
      ));

      expect(result.category, isNull);
      expect(result.source, CategorizationSource.uncategorized);
      expect(result.confidence, 0.0);
    });
  });

  group('Confidence threshold', () {
    test('result below 0.65 is treated as not categorized', () {
      final service = CategorizationService(
        smartRules: [],
        userMerchantMap: {},
        dictionary: dictionary,
      );

      final result = service.categorize(_makeTxn(
        rawDescription: 'unknown',
        cleanedDescription: 'unknown',
        merchantToken: 'unknown',
      ));

      expect(result.isCategorized, isFalse);
    });

    test('result at 0.9+ is categorized', () {
      final service = CategorizationService(
        smartRules: [],
        userMerchantMap: {},
        dictionary: dictionary,
      );

      final result = service.categorize(_makeTxn(
        rawDescription: 'POS SWIGGY',
        merchantToken: 'swiggy',
      ));

      expect(result.isCategorized, isTrue);
      expect(result.confidence, greaterThanOrEqualTo(0.65));
    });
  });

  group('SmartRules case insensitive', () {
    test('matches regardless of case', () {
      final service = CategorizationService(
        smartRules: [SmartRuleData(keyword: 'Netflix', category: 'entertainment')],
        userMerchantMap: {},
        dictionary: dictionary,
      );

      final result = service.categorize(_makeTxn(
        rawDescription: 'POS NETFLIX.COM PURCHASE',
        merchantToken: 'netflix',
      ));

      expect(result.category, 'entertainment');
      expect(result.source, CategorizationSource.smartRule);
    });
  });

  group('Stage 1 only matches userCorrected source', () {
    test('ignores non-userCorrected mappings in Stage 1', () {
      final service = CategorizationService(
        smartRules: [],
        userMerchantMap: {
          'swiggy': const MerchantMappingData(
              category: 'shopping',
              source: 'shippedDictionary', // NOT userCorrected
              confidence: 0.9)
        },
        dictionary: dictionary,
      );

      final result = service.categorize(_makeTxn(
        rawDescription: 'POS SWIGGY',
        merchantToken: 'swiggy',
      ));

      // Should fall through to Stage 2 (dictionary) since Stage 1 skips non-userCorrected
      expect(result.category, 'foodAndDrink');
      expect(result.source, CategorizationSource.dictionary);
    });
  });
}

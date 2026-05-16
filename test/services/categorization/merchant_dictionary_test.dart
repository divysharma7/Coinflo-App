import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/services/categorization/merchant_dictionary.dart';

void main() {
  group('MerchantDictionary', () {
    late MerchantDictionary dictionary;

    setUp(() {
      dictionary = MerchantDictionary();
    });

    test('loads from JSON string', () {
      dictionary.loadFromString('''[
        {"token": "swiggy", "category": "foodAndDrink", "confidence": 0.95},
        {"token": "zomato", "category": "foodAndDrink", "confidence": 0.93}
      ]''');

      expect(dictionary.isLoaded, isTrue);
      expect(dictionary.allEntries, hasLength(2));
    });

    test('exact lookup works', () {
      dictionary.loadFromString('''[
        {"token": "swiggy", "category": "foodAndDrink", "confidence": 0.95}
      ]''');

      final result = dictionary.lookup('swiggy');
      expect(result, isNotNull);
      expect(result!.category, 'foodAndDrink');
      expect(result.confidence, 0.95);
    });

    test('contains fallback works', () {
      dictionary.loadFromString('''[
        {"token": "swiggy", "category": "foodAndDrink", "confidence": 0.95}
      ]''');

      // "swiggyorder" contains "swiggy"
      final result = dictionary.lookup('swiggyorder');
      expect(result, isNotNull);
      expect(result!.token, 'swiggy');
    });

    test('alias lookup works', () {
      dictionary.loadFromString('''[
        {"token": "swiggy", "category": "foodAndDrink", "confidence": 0.95, "aliases": ["swggy", "swigy"]}
      ]''');

      final result = dictionary.lookup('swggy');
      expect(result, isNotNull);
      expect(result!.token, 'swiggy');
    });

    test('no match returns null', () {
      dictionary.loadFromString('''[
        {"token": "swiggy", "category": "foodAndDrink", "confidence": 0.95}
      ]''');

      final result = dictionary.lookup('randommerchant');
      expect(result, isNull);
    });

    test('empty JSON handled gracefully', () {
      dictionary.loadFromString('[]');
      expect(dictionary.isLoaded, isTrue);
      expect(dictionary.allEntries, isEmpty);
    });

    test('loadFromEntries works', () {
      dictionary.loadFromEntries([
        const MerchantEntry(token: 'uber', category: 'transport', confidence: 0.9),
      ]);

      expect(dictionary.isLoaded, isTrue);
      expect(dictionary.lookup('uber'), isNotNull);
    });

    test('short tokens (< 3 chars) do not match via contains', () {
      dictionary.loadFromString('''[
        {"token": "ab", "category": "other", "confidence": 0.8}
      ]''');

      // "ab" is too short for contains-based fallback
      final result = dictionary.lookup('abcdef');
      expect(result, isNull);
    });
  });
}

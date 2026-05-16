import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/services/ai/category_classifier.dart';
import 'package:finance_buddy_app/services/categorization/merchant_dictionary.dart';

/// Singleton MerchantDictionary — loaded once, cached in memory.
final merchantDictionaryProvider = Provider<MerchantDictionary>((ref) {
  final dict = MerchantDictionary();
  // Load is async but MerchantDictionary handles unloaded state gracefully.
  dict.load();
  return dict;
});

final categoryClassifierProvider = Provider<CategoryClassifier>((ref) {
  final db = ref.watch(databaseProvider);
  final dict = ref.watch(merchantDictionaryProvider);
  return CategoryClassifier(db, dict);
});

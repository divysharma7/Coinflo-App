import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/services/ai/category_classifier.dart';

final categoryClassifierProvider = Provider<CategoryClassifier>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryClassifier(db);
});

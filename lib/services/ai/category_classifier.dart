import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import 'package:finance_buddy_app/constants/category_keywords.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';

class CategoryClassifier {
  final SpendlerDatabase _db;
  GenerativeModel? _model;

  CategoryClassifier(this._db);

  GenerativeModel _getModel() {
    return _model ??= FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.0-flash',
    );
  }

  /// Classify a transaction description into a category.
  /// Uses a 3-layer approach:
  ///   1. SQLite cache (instant)
  ///   2. Keyword dictionary with fuzzy matching (instant, offline)
  ///   3. Gemini LLM fallback (network, cached after first hit)
  Future<TransactionCategory?> classify(String text) async {
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) return null;

    // Layer 1: SQLite cache
    final cached = await _lookupCache(trimmed);
    if (cached != null) return cached;

    // Layer 2: Keyword dictionary (instant, no API)
    final keyword = CategoryKeywords.match(trimmed);
    if (keyword != null) {
      await _cacheResult(trimmed, keyword);
      return keyword;
    }

    // Layer 3: Gemini LLM fallback
    try {
      final ai = await _classifyWithAI(text.trim());
      if (ai != null) {
        await _cacheResult(trimmed, ai);
      }
      return ai;
    } on Exception catch (e) {
      debugPrint('AI classification failed: $e');
      return null;
    }
  }

  Future<TransactionCategory?> _lookupCache(String keyword) async {
    final rows = await (_db.select(_db.smartRules)
          ..where((r) => r.keyword.equals(keyword))
          ..limit(1))
        .get();
    if (rows.isEmpty) return null;
    return _parseCategory(rows.first.category);
  }

  Future<void> _cacheResult(String keyword, TransactionCategory category) async {
    await _db.into(_db.smartRules).insert(
      SmartRulesCompanion.insert(
        keyword: keyword,
        category: category.name,
      ),
    );
  }

  Future<TransactionCategory?> _classifyWithAI(String text) async {
    final prompt = '''
You are a personal finance transaction categorizer. Classify the transaction into exactly one category.

Categories and examples:
- foodAndDrink: groceries, restaurants, coffee, snacks, food delivery, drinks
- transport: cab, fuel, metro, bus, parking, toll, car service
- shopping: clothes, electronics, online orders, gifts, furniture
- billsAndUtilities: rent, electricity, wifi, phone bill, insurance, EMI, loan
- healthAndWellness: doctor, pharmacy, gym, fitness, medical tests, therapy
- entertainment: movies, streaming, gaming, concerts, events, sports
- personalCare: salon, spa, haircut, skincare, grooming, laundry
- education: courses, books, tuition, coaching, certifications, tools
- travel: flights, hotels, vacation, luggage, visa, booking
- other: anything that doesn't fit above

Transaction: "$text"

Reply with ONLY the category name (e.g. foodAndDrink). No explanation.''';

    final response = await _getModel().generateContent([Content.text(prompt)]);
    final result = response.text?.trim().toLowerCase();
    if (result == null) return null;

    return _parseCategory(result);
  }

  TransactionCategory? _parseCategory(String name) {
    final cleaned = name.trim().toLowerCase();
    for (final cat in TransactionCategory.groups) {
      if (cat.name.toLowerCase() == cleaned) return cat;
    }
    return null;
  }
}

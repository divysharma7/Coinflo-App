import 'package:drift/drift.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:finance_buddy_app/constants/category_keywords.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/services/categorization/categorization_service.dart';
import 'package:finance_buddy_app/services/categorization/merchant_dictionary.dart';
import 'package:finance_buddy_app/services/import/models/normalized_transaction.dart';
import 'package:finance_buddy_app/services/import/models/raw_transaction.dart';
import 'package:finance_buddy_app/services/import/transaction_normalizer.dart';

class CategoryClassifier {
  final SpendlerDatabase _db;
  final MerchantDictionary _merchantDictionary;
  GenerativeModel? _model;
  static const _uuid = Uuid();

  CategoryClassifier(this._db, this._merchantDictionary);

  GenerativeModel _getModel() {
    return _model ??= FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.0-flash',
    );
  }

  /// Classify a transaction description into a category.
  /// Uses an enhanced pipeline:
  ///   1. CategorizationService cascade (on-device, 6 stages)
  ///   2. SQLite cache (existing SmartRules)
  ///   3. Keyword dictionary with fuzzy matching
  ///   4. Gemini LLM fallback (network, cached after first hit)
  ///   5. If Gemini succeeds, persist to MerchantMappings (source=ml)
  Future<TransactionCategory?> classify(String text) async {
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) return null;

    // ── New: Try CategorizationService cascade first ─────
    final cascadeResult = await _tryCascade(trimmed);
    if (cascadeResult != null) return cascadeResult;

    // ── Layer 1: SQLite cache (existing behavior) ────────
    final cached = await _lookupCache(trimmed);
    if (cached != null) return cached;

    // ── Layer 2: Keyword dictionary (instant, no API) ────
    final keyword = CategoryKeywords.match(trimmed);
    if (keyword != null) {
      await _cacheResult(trimmed, keyword);
      return keyword;
    }

    // ── Layer 3: Gemini LLM fallback ─────────────────────
    try {
      final ai = await _classifyWithAI(text.trim());
      if (ai != null) {
        await _cacheResult(trimmed, ai);
        // Persist to MerchantMappings so future cascade lookups skip Gemini.
        await _persistMlMapping(trimmed, ai);
      }
      return ai;
    } on Exception catch (e) {
      debugPrint('AI classification failed: $e');
      return null;
    }
  }

  /// Build a NormalizedTransaction from quick-add text and run the cascade.
  Future<TransactionCategory?> _tryCascade(String text) async {
    // Construct a minimal NormalizedTransaction for cascade lookup.
    final normalizer = TransactionNormalizer();
    final now = DateTime.now();
    final normalized = NormalizedTransaction(
      date: now,
      amount: 0, // Not relevant for categorization.
      type: 'debit',
      rawDescription: text,
      cleanedDescription: text,
      merchantToken: normalizer.normalize(
        RawTransaction(
          date: now,
          amount: 0,
          type: 'debit',
          rawDescription: text,
          sourceBank: BankType.unknown,
        ),
      ).merchantToken,
      channel: TransactionChannel.other,
      rawHash: '',
      sourceBank: BankType.unknown,
    );

    // Fetch data for cascade (lightweight — only user corrections + smart rules).
    final mappingRows = await (_db.select(_db.merchantMappings)
          ..where((m) => m.merchantToken.equals(normalized.merchantToken)))
        .get();
    final merchantMap = <String, MerchantMappingData>{};
    for (final m in mappingRows) {
      if (!merchantMap.containsKey(m.merchantToken) ||
          m.source == 'userCorrected') {
        merchantMap[m.merchantToken] = MerchantMappingData(
          category: m.category,
          source: m.source,
          confidence: m.confidence,
        );
      }
    }

    final ruleRows = await _db.select(_db.smartRules).get();
    final smartRules = ruleRows
        .map((r) => SmartRuleData(keyword: r.keyword, category: r.category))
        .toList();

    final service = CategorizationService(
      smartRules: smartRules,
      userMerchantMap: merchantMap,
      dictionary: _merchantDictionary,
    );

    final result = service.categorize(normalized);
    if (result.isCategorized) {
      return _parseCategory(result.category!);
    }
    return null;
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

  /// Persist a Gemini-derived mapping so the cascade picks it up next time.
  Future<void> _persistMlMapping(String text, TransactionCategory category) async {
    final normalizer = TransactionNormalizer();
    final token = normalizer.normalize(
      RawTransaction(
        date: DateTime.now(),
        amount: 0,
        type: 'debit',
        rawDescription: text,
        sourceBank: BankType.unknown,
      ),
    ).merchantToken;

    if (token.isEmpty) return;

    final now = DateTime.now();
    // Only insert if no mapping exists for this token+source.
    final existing = await (_db.select(_db.merchantMappings)
          ..where((m) =>
              m.merchantToken.equals(token) & m.source.equals('ml')))
        .getSingleOrNull();
    if (existing != null) return;

    await _db.into(_db.merchantMappings).insert(
          MerchantMappingsCompanion.insert(
            id: _uuid.v4(),
            merchantToken: token,
            category: category.name,
            source: 'ml',
            confidence: 0.8,
            createdAt: now,
            updatedAt: now,
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

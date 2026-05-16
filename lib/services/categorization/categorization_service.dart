import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/services/categorization/merchant_dictionary.dart';
import 'package:finance_buddy_app/services/categorization/rule_engine.dart';
import 'package:finance_buddy_app/services/categorization/upi_parser.dart';
import 'package:finance_buddy_app/services/import/models/categorization_result.dart';
import 'package:finance_buddy_app/services/import/models/normalized_transaction.dart';

/// Data structure for merchant mappings passed into the cascade.
class MerchantMappingData {
  final String category;
  final String source; // MappingSource enum name
  final double confidence;

  const MerchantMappingData({
    required this.category,
    required this.source,
    required this.confidence,
  });
}

/// Data structure for smart rules passed into the cascade.
class SmartRuleData {
  final String keyword;
  final String category;

  const SmartRuleData({required this.keyword, required this.category});
}

/// The 6-stage on-device categorization cascade.
/// Fully stateless and safe to run in an isolate — all data is passed in.
///
/// Stage order (stop at first match with confidence >= 0.65):
///   0. SmartRules (user-authored keyword rules)
///   1. Personal merchant map (user corrections from MerchantMappings)
///   2. Shipped dictionary (from indian_merchants.json)
///   3. UPI VPA parsing (only if channel == UPI)
///   4. Regex rule engine (Indian banking patterns)
///   5. ML fallback (STUB — returns uncategorized)
class CategorizationService {
  final List<SmartRuleData> _smartRules;
  final Map<String, MerchantMappingData> _userMerchantMap;
  final MerchantDictionary _dictionary;
  final UpiParser _upiParser;
  final RuleEngine _ruleEngine;

  static const double _confidenceThreshold = 0.65;

  CategorizationService({
    required List<SmartRuleData> smartRules,
    required Map<String, MerchantMappingData> userMerchantMap,
    required MerchantDictionary dictionary,
  })  : _smartRules = smartRules,
        _userMerchantMap = userMerchantMap,
        _dictionary = dictionary,
        _upiParser = UpiParser(dictionary),
        _ruleEngine = RuleEngine();

  /// Categorize a single normalized transaction through the 6-stage cascade.
  CategorizationResult categorize(NormalizedTransaction txn) {
    // STAGE 0 — SmartRules (user-authored keyword rules always win)
    final stage0 = _checkSmartRules(txn.rawDescription);
    if (stage0 != null && stage0.confidence >= _confidenceThreshold) return stage0;

    // STAGE 1 — Personal merchant map (user corrections)
    final stage1 = _checkUserMerchantMap(txn.merchantToken);
    if (stage1 != null && stage1.confidence >= _confidenceThreshold) return stage1;

    // STAGE 2 — Shipped dictionary
    final stage2 = _checkDictionary(txn.merchantToken);
    if (stage2 != null && stage2.confidence >= _confidenceThreshold) return stage2;

    // STAGE 3 — UPI VPA parsing (only for UPI channel)
    if (txn.channel == TransactionChannel.upi) {
      final stage3 = _upiParser.parse(txn.rawDescription);
      if (stage3 != null && stage3.confidence >= _confidenceThreshold) return stage3;
    }

    // STAGE 4 — Rule engine (regex patterns)
    final stage4 = _ruleEngine.match(txn.cleanedDescription);
    if (stage4 != null && stage4.confidence >= _confidenceThreshold) return stage4;

    // STAGE 5 — ML fallback (STUB for v1)
    // TODO(v2): On-device Naive Bayes goes here.
    // Architecture allows swapping in ML without changing callers.
    return CategorizationResult.uncategorized;
  }

  /// Stage 0: Check SmartRules — case-insensitive substring match.
  CategorizationResult? _checkSmartRules(String rawDescription) {
    final lower = rawDescription.toLowerCase();
    for (final rule in _smartRules) {
      if (lower.contains(rule.keyword.toLowerCase())) {
        return CategorizationResult(
          category: rule.category,
          source: CategorizationSource.smartRule,
          confidence: 1.0,
        );
      }
    }
    return null;
  }

  /// Stage 1: Check user-corrected merchant mappings by exact merchantToken.
  CategorizationResult? _checkUserMerchantMap(String merchantToken) {
    final mapping = _userMerchantMap[merchantToken];
    if (mapping == null) return null;
    if (mapping.source != 'userCorrected') return null;
    return CategorizationResult(
      category: mapping.category,
      source: CategorizationSource.user,
      confidence: 1.0,
    );
  }

  /// Stage 2: Check shipped dictionary by token lookup.
  CategorizationResult? _checkDictionary(String merchantToken) {
    final entry = _dictionary.lookup(merchantToken);
    if (entry == null) return null;
    return CategorizationResult(
      category: entry.category,
      source: CategorizationSource.dictionary,
      confidence: entry.confidence,
    );
  }
}

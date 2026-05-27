import 'package:finance_buddy_app/services/categorization/models/categorization_result.dart';
import 'package:finance_buddy_app/core/enums.dart';

/// A single categorization rule: regex pattern → category mapping.
class _Rule {
  final RegExp pattern;
  final String category;
  final double confidence;

  const _Rule(this.pattern, this.category, this.confidence);
}

/// Pre-compiled regex rule engine for Indian banking patterns.
/// Stage 4 of the categorization cascade.
///
/// Category mapping to TransactionCategory enum values:
///   Salary/Income → 'income'
///   ATM/Cash → 'cash'
///   EMI → 'billsAndUtilities'
///   Bills/Electricity → 'billsAndUtilities'
///   Education → 'education'
///   Health → 'healthAndWellness'
///   Insurance → 'insurance'
///   Investments → 'investments'
class RuleEngine {
  // Patterns compiled once at construction — not per-transaction.
  static final List<_Rule> _rules = [
    _Rule(
      RegExp(r'sal(?:ary)?[\s.]*cr|\bsalary\b|payroll|monthly sal', caseSensitive: false),
      'income',
      0.95,
    ),
    _Rule(
      RegExp(r'atm[\s-]*(wdl|cwd|withdrawal)', caseSensitive: false),
      'cash',
      1.0,
    ),
    _Rule(
      RegExp(r'\bemi\b|loan emi|home loan|car loan', caseSensitive: false),
      'billsAndUtilities',
      0.9,
    ),
    _Rule(
      RegExp(
        r'electricity|bescom|tata power|adani elec|water bill|bwssb|gas bill|bbps',
        caseSensitive: false,
      ),
      'billsAndUtilities',
      0.95,
    ),
    _Rule(
      RegExp(r'school fee|college fee|tuition|byjus|unacademy', caseSensitive: false),
      'education',
      0.9,
    ),
    _Rule(
      RegExp(
        r'apollo|fortis|max hosp|medplus|1mg|pharmeasy|netmeds|hospital|pharmacy',
        caseSensitive: false,
      ),
      'healthAndWellness',
      0.9,
    ),
    _Rule(
      RegExp(r'lic|policybazaar|premium|insurance', caseSensitive: false),
      'insurance',
      0.9,
    ),
    _Rule(
      RegExp(r'zerodha|groww|upstox|kuvera|coin\.dcx|mf order|sip', caseSensitive: false),
      'investments',
      0.95,
    ),
  ];

  /// Match a cleaned description against all rules.
  /// Returns first match or null.
  CategorizationResult? match(String cleanedDescription) {
    for (final rule in _rules) {
      if (rule.pattern.hasMatch(cleanedDescription)) {
        return CategorizationResult(
          category: rule.category,
          source: CategorizationSource.rule,
          confidence: rule.confidence,
        );
      }
    }
    return null;
  }
}

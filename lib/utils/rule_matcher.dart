import 'package:finance_buddy_app/models/smart_rule_model.dart';

class RuleMatcher {
  /// Returns the matching category name, or null if no rule matches.
  /// Rules must be passed sorted by createdAt DESCENDING (last-added first).
  static String? match({
    required String transactionTitle,
    required List<SmartRuleModel> rules,
  }) {
    if (transactionTitle.isEmpty) return null;
    final titleLower = transactionTitle.toLowerCase();
    for (final rule in rules) {
      if (titleLower.contains(rule.keyword.toLowerCase())) {
        return rule.categoryName;
      }
    }
    return null;
  }
}

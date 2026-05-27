import 'package:finance_buddy_app/data/repositories/split_repository.dart';

enum SplitMethod { equal, exact, percentage, shares }

class SplitCalculator {
  static List<SplitEntry> equal(double totalAmount, List<int> personIds) {
    final count = personIds.length + 1;
    final baseAmount = (totalAmount * 100).round() ~/ count / 100.0;
    final remainder = totalAmount - baseAmount * count;

    final splits = <SplitEntry>[
      SplitEntry(personId: null, shareAmount: baseAmount + remainder),
    ];
    for (final pid in personIds) {
      splits.add(SplitEntry(personId: pid, shareAmount: baseAmount));
    }
    return splits;
  }

  static List<SplitEntry> exact(Map<int?, double> amounts) {
    return amounts.entries
        .map((e) => SplitEntry(personId: e.key, shareAmount: e.value))
        .toList();
  }

  static List<SplitEntry> percentage(
      double totalAmount, Map<int?, double> percentages) {
    final splits = <SplitEntry>[];
    double allocated = 0;
    final entries = percentages.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final isLast = i == entries.length - 1;
      final share = isLast
          ? totalAmount - allocated
          : (totalAmount * entries[i].value / 100 * 100).round() / 100.0;
      splits.add(SplitEntry(personId: entries[i].key, shareAmount: share));
      allocated += share;
    }
    return splits;
  }

  static List<SplitEntry> byShares(
      double totalAmount, Map<int?, int> shareUnits) {
    final totalShares = shareUnits.values.fold(0, (a, b) => a + b);
    final splits = <SplitEntry>[];
    double allocated = 0;
    final entries = shareUnits.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final isLast = i == entries.length - 1;
      final share = isLast
          ? totalAmount - allocated
          : (totalAmount * entries[i].value / totalShares * 100).round() /
              100.0;
      splits.add(SplitEntry(personId: entries[i].key, shareAmount: share));
      allocated += share;
    }
    return splits;
  }
}

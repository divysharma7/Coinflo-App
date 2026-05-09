import 'dart:math';

class NotificationCopy {
  static final _random = Random();

  static String transactionDetected(int count) {
    final templates = [
      '$count new transactions detected. A quick confirm will keep things clean.',
      '$count transactions waiting for you. Takes a minute.',
      'You\'ve got $count pending — tap to review and confirm.',
    ];
    return templates[_random.nextInt(templates.length)];
  }

  static String eveningCheckin(int count, double totalPending) {
    final amt = '\$${totalPending.toStringAsFixed(0)}';
    final templates = [
      '$amt still untagged today. One minute before bed — you\'ll thank yourself tomorrow.',
      'End of day check-in: $count transactions need a look. Quick and painless.',
      'Day\'s almost done. $amt pending — confirm now so Monday you is grateful.',
    ];
    return templates[_random.nextInt(templates.length)];
  }

  static String sundayDigest(double totalSpent, String topCategory, double topAmount) {
    final total = '\$${totalSpent.toStringAsFixed(0)}';
    final top = '\$${topAmount.toStringAsFixed(0)}';
    final templates = [
      'Your week in review: $total spent. $topCategory led at $top. Take a look.',
      'Weekly rhythm check — $total total. Top category: $topCategory. Your summary is ready.',
      'Sunday pulse: $total this week. $topCategory was the big one at $top.',
    ];
    return templates[_random.nextInt(templates.length)];
  }

  static String splitSettlementQuery(double amount, String? merchant) {
    final amt = '\$${amount.toStringAsFixed(0)}';
    if (merchant != null) {
      return '$amt received. Is this the $merchant settlement?';
    }
    return '$amt received. Is this a split settlement?';
  }
}

class ParsedSms {
  final double amount;
  final bool isDebit;
  final String? merchant;
  final String rawText;
  final DateTime receivedAt;

  const ParsedSms({
    required this.amount,
    required this.isDebit,
    this.merchant,
    required this.rawText,
    required this.receivedAt,
  });
}

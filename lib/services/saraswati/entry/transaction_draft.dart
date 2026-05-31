import 'dart:convert';

/// The kind of transaction being entered.
enum TransactionKind {
  expense,
  income,
  transfer,
  split;

  String toJson() => name;

  static TransactionKind fromJson(String json) =>
      TransactionKind.values.firstWhere(
        (e) => e.name == json,
        orElse: () => TransactionKind.expense,
      );
}

/// Who paid for the transaction.
enum PayerKind {
  user,
  counterparty,
  splitEqual,
  splitCustom;

  String toJson() => name;

  static PayerKind fromJson(String json) => PayerKind.values.firstWhere(
        (e) => e.name == json,
        orElse: () => PayerKind.user,
      );
}

/// A structured draft extracted from natural-language chat input.
///
/// Produced by the entry pipeline (Stages 0-3) and consumed by the
/// disambiguation engine to decide whether to commit, ask, or fall back.
class TransactionDraft {
  final TransactionKind kind;
  final double? amount;
  final String? counterparty;
  final String? counterpartyId;
  final String? category;
  final DateTime? date;
  final PayerKind? payer;
  final List<String>? splitWith;
  final String? note;
  final String source; // 'quickadd' | 'pattern' | 'cache' | 'llm'

  /// Per-field confidence (0.0-1.0). Missing key = field absent.
  final Map<String, double> fieldConfidence;

  /// The raw input that produced this draft (for audit + cache key).
  final String rawInput;

  const TransactionDraft({
    required this.kind,
    this.amount,
    this.counterparty,
    this.counterpartyId,
    this.category,
    this.date,
    this.payer,
    this.splitWith,
    this.note,
    required this.source,
    this.fieldConfidence = const {},
    required this.rawInput,
  });

  /// Fields whose confidence is below [threshold].
  /// Excludes null/absent fields — only checks fields that exist in the map.
  List<String> uncertainFields({double threshold = 0.85}) {
    return fieldConfidence.entries
        .where((e) => e.value < threshold)
        .map((e) => e.key)
        .toList();
  }

  /// Required fields (per [kind]) that are null. Distinct from uncertain.
  List<String> missingRequiredFields() {
    final missing = <String>[];

    // Amount is required for all kinds.
    if (amount == null) missing.add('amount');
    // Date is required for all kinds.
    if (date == null) missing.add('date');

    switch (kind) {
      case TransactionKind.expense:
        if (category == null) missing.add('category');
      case TransactionKind.income:
        if (category == null) missing.add('category');
      case TransactionKind.transfer:
        if (counterparty == null && counterpartyId == null) {
          missing.add('counterparty');
        }
      case TransactionKind.split:
        if (counterparty == null &&
            counterpartyId == null &&
            (splitWith == null || splitWith!.isEmpty)) {
          missing.add('counterparty');
        }
        if (payer == null) missing.add('payer');
    }

    return missing;
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.toJson(),
        if (amount != null) 'amount': amount,
        if (counterparty != null) 'counterparty': counterparty,
        if (counterpartyId != null) 'counterparty_id': counterpartyId,
        if (category != null) 'category': category,
        if (date != null) 'date': date!.toIso8601String(),
        if (payer != null) 'payer': payer!.toJson(),
        if (splitWith != null) 'split_with': splitWith,
        if (note != null) 'note': note,
        'source': source,
        'field_confidence': fieldConfidence,
        'raw_input': rawInput,
      };

  factory TransactionDraft.fromJson(Map<String, dynamic> json) {
    return TransactionDraft(
      kind: TransactionKind.fromJson(json['kind'] as String),
      amount: (json['amount'] as num?)?.toDouble(),
      counterparty: json['counterparty'] as String?,
      counterpartyId: json['counterparty_id'] as String?,
      category: json['category'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      payer: json['payer'] != null
          ? PayerKind.fromJson(json['payer'] as String)
          : null,
      splitWith: (json['split_with'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      note: json['note'] as String?,
      source: json['source'] as String,
      fieldConfidence: (json['field_confidence'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          const {},
      rawInput: json['raw_input'] as String,
    );
  }

  TransactionDraft copyWith({
    TransactionKind? kind,
    double? Function()? amount,
    String? Function()? counterparty,
    String? Function()? counterpartyId,
    String? Function()? category,
    DateTime? Function()? date,
    PayerKind? Function()? payer,
    List<String>? Function()? splitWith,
    String? Function()? note,
    String? source,
    Map<String, double>? fieldConfidence,
    String? rawInput,
  }) {
    return TransactionDraft(
      kind: kind ?? this.kind,
      amount: amount != null ? amount() : this.amount,
      counterparty: counterparty != null ? counterparty() : this.counterparty,
      counterpartyId:
          counterpartyId != null ? counterpartyId() : this.counterpartyId,
      category: category != null ? category() : this.category,
      date: date != null ? date() : this.date,
      payer: payer != null ? payer() : this.payer,
      splitWith: splitWith != null ? splitWith() : this.splitWith,
      note: note != null ? note() : this.note,
      source: source ?? this.source,
      fieldConfidence: fieldConfidence ?? this.fieldConfidence,
      rawInput: rawInput ?? this.rawInput,
    );
  }

  /// Serialize the extraction metadata for audit storage.
  String toExtractionMetaJson() => jsonEncode({
        'source': source,
        'field_confidence': fieldConfidence,
      });

  @override
  String toString() =>
      'TransactionDraft(kind: $kind, amount: $amount, '
      'counterparty: $counterparty, category: $category, '
      'date: $date, source: $source)';
}

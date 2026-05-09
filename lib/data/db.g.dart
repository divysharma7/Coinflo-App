// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $SpendlerTransactionsTable extends SpendlerTransactions
    with TableInfo<$SpendlerTransactionsTable, SpendlerTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpendlerTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _happenedAtMeta = const VerificationMeta(
    'happenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> happenedAt = GeneratedColumn<DateTime>(
    'happened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('confirmed'),
  );
  static const VerificationMeta _isSplitMeta = const VerificationMeta(
    'isSplit',
  );
  @override
  late final GeneratedColumn<bool> isSplit = GeneratedColumn<bool>(
    'is_split',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_split" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _splitCountMeta = const VerificationMeta(
    'splitCount',
  );
  @override
  late final GeneratedColumn<int> splitCount = GeneratedColumn<int>(
    'split_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _splitMyShareMeta = const VerificationMeta(
    'splitMyShare',
  );
  @override
  late final GeneratedColumn<double> splitMyShare = GeneratedColumn<double>(
    'split_my_share',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _splitPendingAmountMeta =
      const VerificationMeta('splitPendingAmount');
  @override
  late final GeneratedColumn<double> splitPendingAmount =
      GeneratedColumn<double>(
        'split_pending_amount',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _splitSettledMeta = const VerificationMeta(
    'splitSettled',
  );
  @override
  late final GeneratedColumn<bool> splitSettled = GeneratedColumn<bool>(
    'split_settled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("split_settled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ledgerTypeMeta = const VerificationMeta(
    'ledgerType',
  );
  @override
  late final GeneratedColumn<String> ledgerType = GeneratedColumn<String>(
    'ledger_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('personal'),
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amount,
    category,
    merchant,
    note,
    happenedAt,
    source,
    status,
    isSplit,
    splitCount,
    splitMyShare,
    splitPendingAmount,
    splitSettled,
    ledgerType,
    syncId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'spendler_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SpendlerTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('happened_at')) {
      context.handle(
        _happenedAtMeta,
        happenedAt.isAcceptableOrUnknown(data['happened_at']!, _happenedAtMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('is_split')) {
      context.handle(
        _isSplitMeta,
        isSplit.isAcceptableOrUnknown(data['is_split']!, _isSplitMeta),
      );
    }
    if (data.containsKey('split_count')) {
      context.handle(
        _splitCountMeta,
        splitCount.isAcceptableOrUnknown(data['split_count']!, _splitCountMeta),
      );
    }
    if (data.containsKey('split_my_share')) {
      context.handle(
        _splitMyShareMeta,
        splitMyShare.isAcceptableOrUnknown(
          data['split_my_share']!,
          _splitMyShareMeta,
        ),
      );
    }
    if (data.containsKey('split_pending_amount')) {
      context.handle(
        _splitPendingAmountMeta,
        splitPendingAmount.isAcceptableOrUnknown(
          data['split_pending_amount']!,
          _splitPendingAmountMeta,
        ),
      );
    }
    if (data.containsKey('split_settled')) {
      context.handle(
        _splitSettledMeta,
        splitSettled.isAcceptableOrUnknown(
          data['split_settled']!,
          _splitSettledMeta,
        ),
      );
    }
    if (data.containsKey('ledger_type')) {
      context.handle(
        _ledgerTypeMeta,
        ledgerType.isAcceptableOrUnknown(data['ledger_type']!, _ledgerTypeMeta),
      );
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SpendlerTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpendlerTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      happenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}happened_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isSplit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_split'],
      )!,
      splitCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}split_count'],
      ),
      splitMyShare: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}split_my_share'],
      ),
      splitPendingAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}split_pending_amount'],
      ),
      splitSettled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}split_settled'],
      )!,
      ledgerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ledger_type'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SpendlerTransactionsTable createAlias(String alias) {
    return $SpendlerTransactionsTable(attachedDatabase, alias);
  }
}

class SpendlerTransaction extends DataClass
    implements Insertable<SpendlerTransaction> {
  final int id;
  final double amount;
  final String category;
  final String? merchant;
  final String? note;
  final DateTime happenedAt;
  final String source;
  final String status;
  final bool isSplit;
  final int? splitCount;
  final double? splitMyShare;
  final double? splitPendingAmount;
  final bool splitSettled;
  final String ledgerType;
  final String? syncId;
  final DateTime createdAt;
  const SpendlerTransaction({
    required this.id,
    required this.amount,
    required this.category,
    this.merchant,
    this.note,
    required this.happenedAt,
    required this.source,
    required this.status,
    required this.isSplit,
    this.splitCount,
    this.splitMyShare,
    this.splitPendingAmount,
    required this.splitSettled,
    required this.ledgerType,
    this.syncId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount'] = Variable<double>(amount);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['happened_at'] = Variable<DateTime>(happenedAt);
    map['source'] = Variable<String>(source);
    map['status'] = Variable<String>(status);
    map['is_split'] = Variable<bool>(isSplit);
    if (!nullToAbsent || splitCount != null) {
      map['split_count'] = Variable<int>(splitCount);
    }
    if (!nullToAbsent || splitMyShare != null) {
      map['split_my_share'] = Variable<double>(splitMyShare);
    }
    if (!nullToAbsent || splitPendingAmount != null) {
      map['split_pending_amount'] = Variable<double>(splitPendingAmount);
    }
    map['split_settled'] = Variable<bool>(splitSettled);
    map['ledger_type'] = Variable<String>(ledgerType);
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SpendlerTransactionsCompanion toCompanion(bool nullToAbsent) {
    return SpendlerTransactionsCompanion(
      id: Value(id),
      amount: Value(amount),
      category: Value(category),
      merchant: merchant == null && nullToAbsent
          ? const Value.absent()
          : Value(merchant),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      happenedAt: Value(happenedAt),
      source: Value(source),
      status: Value(status),
      isSplit: Value(isSplit),
      splitCount: splitCount == null && nullToAbsent
          ? const Value.absent()
          : Value(splitCount),
      splitMyShare: splitMyShare == null && nullToAbsent
          ? const Value.absent()
          : Value(splitMyShare),
      splitPendingAmount: splitPendingAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(splitPendingAmount),
      splitSettled: Value(splitSettled),
      ledgerType: Value(ledgerType),
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      createdAt: Value(createdAt),
    );
  }

  factory SpendlerTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpendlerTransaction(
      id: serializer.fromJson<int>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      category: serializer.fromJson<String>(json['category']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      note: serializer.fromJson<String?>(json['note']),
      happenedAt: serializer.fromJson<DateTime>(json['happenedAt']),
      source: serializer.fromJson<String>(json['source']),
      status: serializer.fromJson<String>(json['status']),
      isSplit: serializer.fromJson<bool>(json['isSplit']),
      splitCount: serializer.fromJson<int?>(json['splitCount']),
      splitMyShare: serializer.fromJson<double?>(json['splitMyShare']),
      splitPendingAmount: serializer.fromJson<double?>(
        json['splitPendingAmount'],
      ),
      splitSettled: serializer.fromJson<bool>(json['splitSettled']),
      ledgerType: serializer.fromJson<String>(json['ledgerType']),
      syncId: serializer.fromJson<String?>(json['syncId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amount': serializer.toJson<double>(amount),
      'category': serializer.toJson<String>(category),
      'merchant': serializer.toJson<String?>(merchant),
      'note': serializer.toJson<String?>(note),
      'happenedAt': serializer.toJson<DateTime>(happenedAt),
      'source': serializer.toJson<String>(source),
      'status': serializer.toJson<String>(status),
      'isSplit': serializer.toJson<bool>(isSplit),
      'splitCount': serializer.toJson<int?>(splitCount),
      'splitMyShare': serializer.toJson<double?>(splitMyShare),
      'splitPendingAmount': serializer.toJson<double?>(splitPendingAmount),
      'splitSettled': serializer.toJson<bool>(splitSettled),
      'ledgerType': serializer.toJson<String>(ledgerType),
      'syncId': serializer.toJson<String?>(syncId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SpendlerTransaction copyWith({
    int? id,
    double? amount,
    String? category,
    Value<String?> merchant = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? happenedAt,
    String? source,
    String? status,
    bool? isSplit,
    Value<int?> splitCount = const Value.absent(),
    Value<double?> splitMyShare = const Value.absent(),
    Value<double?> splitPendingAmount = const Value.absent(),
    bool? splitSettled,
    String? ledgerType,
    Value<String?> syncId = const Value.absent(),
    DateTime? createdAt,
  }) => SpendlerTransaction(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    merchant: merchant.present ? merchant.value : this.merchant,
    note: note.present ? note.value : this.note,
    happenedAt: happenedAt ?? this.happenedAt,
    source: source ?? this.source,
    status: status ?? this.status,
    isSplit: isSplit ?? this.isSplit,
    splitCount: splitCount.present ? splitCount.value : this.splitCount,
    splitMyShare: splitMyShare.present ? splitMyShare.value : this.splitMyShare,
    splitPendingAmount: splitPendingAmount.present
        ? splitPendingAmount.value
        : this.splitPendingAmount,
    splitSettled: splitSettled ?? this.splitSettled,
    ledgerType: ledgerType ?? this.ledgerType,
    syncId: syncId.present ? syncId.value : this.syncId,
    createdAt: createdAt ?? this.createdAt,
  );
  SpendlerTransaction copyWithCompanion(SpendlerTransactionsCompanion data) {
    return SpendlerTransaction(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      note: data.note.present ? data.note.value : this.note,
      happenedAt: data.happenedAt.present
          ? data.happenedAt.value
          : this.happenedAt,
      source: data.source.present ? data.source.value : this.source,
      status: data.status.present ? data.status.value : this.status,
      isSplit: data.isSplit.present ? data.isSplit.value : this.isSplit,
      splitCount: data.splitCount.present
          ? data.splitCount.value
          : this.splitCount,
      splitMyShare: data.splitMyShare.present
          ? data.splitMyShare.value
          : this.splitMyShare,
      splitPendingAmount: data.splitPendingAmount.present
          ? data.splitPendingAmount.value
          : this.splitPendingAmount,
      splitSettled: data.splitSettled.present
          ? data.splitSettled.value
          : this.splitSettled,
      ledgerType: data.ledgerType.present
          ? data.ledgerType.value
          : this.ledgerType,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpendlerTransaction(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('merchant: $merchant, ')
          ..write('note: $note, ')
          ..write('happenedAt: $happenedAt, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('isSplit: $isSplit, ')
          ..write('splitCount: $splitCount, ')
          ..write('splitMyShare: $splitMyShare, ')
          ..write('splitPendingAmount: $splitPendingAmount, ')
          ..write('splitSettled: $splitSettled, ')
          ..write('ledgerType: $ledgerType, ')
          ..write('syncId: $syncId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amount,
    category,
    merchant,
    note,
    happenedAt,
    source,
    status,
    isSplit,
    splitCount,
    splitMyShare,
    splitPendingAmount,
    splitSettled,
    ledgerType,
    syncId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpendlerTransaction &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.merchant == this.merchant &&
          other.note == this.note &&
          other.happenedAt == this.happenedAt &&
          other.source == this.source &&
          other.status == this.status &&
          other.isSplit == this.isSplit &&
          other.splitCount == this.splitCount &&
          other.splitMyShare == this.splitMyShare &&
          other.splitPendingAmount == this.splitPendingAmount &&
          other.splitSettled == this.splitSettled &&
          other.ledgerType == this.ledgerType &&
          other.syncId == this.syncId &&
          other.createdAt == this.createdAt);
}

class SpendlerTransactionsCompanion extends UpdateCompanion<SpendlerTransaction> {
  final Value<int> id;
  final Value<double> amount;
  final Value<String> category;
  final Value<String?> merchant;
  final Value<String?> note;
  final Value<DateTime> happenedAt;
  final Value<String> source;
  final Value<String> status;
  final Value<bool> isSplit;
  final Value<int?> splitCount;
  final Value<double?> splitMyShare;
  final Value<double?> splitPendingAmount;
  final Value<bool> splitSettled;
  final Value<String> ledgerType;
  final Value<String?> syncId;
  final Value<DateTime> createdAt;
  const SpendlerTransactionsCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.merchant = const Value.absent(),
    this.note = const Value.absent(),
    this.happenedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.isSplit = const Value.absent(),
    this.splitCount = const Value.absent(),
    this.splitMyShare = const Value.absent(),
    this.splitPendingAmount = const Value.absent(),
    this.splitSettled = const Value.absent(),
    this.ledgerType = const Value.absent(),
    this.syncId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SpendlerTransactionsCompanion.insert({
    this.id = const Value.absent(),
    required double amount,
    required String category,
    this.merchant = const Value.absent(),
    this.note = const Value.absent(),
    this.happenedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.isSplit = const Value.absent(),
    this.splitCount = const Value.absent(),
    this.splitMyShare = const Value.absent(),
    this.splitPendingAmount = const Value.absent(),
    this.splitSettled = const Value.absent(),
    this.ledgerType = const Value.absent(),
    this.syncId = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : amount = Value(amount),
       category = Value(category);
  static Insertable<SpendlerTransaction> custom({
    Expression<int>? id,
    Expression<double>? amount,
    Expression<String>? category,
    Expression<String>? merchant,
    Expression<String>? note,
    Expression<DateTime>? happenedAt,
    Expression<String>? source,
    Expression<String>? status,
    Expression<bool>? isSplit,
    Expression<int>? splitCount,
    Expression<double>? splitMyShare,
    Expression<double>? splitPendingAmount,
    Expression<bool>? splitSettled,
    Expression<String>? ledgerType,
    Expression<String>? syncId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (merchant != null) 'merchant': merchant,
      if (note != null) 'note': note,
      if (happenedAt != null) 'happened_at': happenedAt,
      if (source != null) 'source': source,
      if (status != null) 'status': status,
      if (isSplit != null) 'is_split': isSplit,
      if (splitCount != null) 'split_count': splitCount,
      if (splitMyShare != null) 'split_my_share': splitMyShare,
      if (splitPendingAmount != null)
        'split_pending_amount': splitPendingAmount,
      if (splitSettled != null) 'split_settled': splitSettled,
      if (ledgerType != null) 'ledger_type': ledgerType,
      if (syncId != null) 'sync_id': syncId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SpendlerTransactionsCompanion copyWith({
    Value<int>? id,
    Value<double>? amount,
    Value<String>? category,
    Value<String?>? merchant,
    Value<String?>? note,
    Value<DateTime>? happenedAt,
    Value<String>? source,
    Value<String>? status,
    Value<bool>? isSplit,
    Value<int?>? splitCount,
    Value<double?>? splitMyShare,
    Value<double?>? splitPendingAmount,
    Value<bool>? splitSettled,
    Value<String>? ledgerType,
    Value<String?>? syncId,
    Value<DateTime>? createdAt,
  }) {
    return SpendlerTransactionsCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      merchant: merchant ?? this.merchant,
      note: note ?? this.note,
      happenedAt: happenedAt ?? this.happenedAt,
      source: source ?? this.source,
      status: status ?? this.status,
      isSplit: isSplit ?? this.isSplit,
      splitCount: splitCount ?? this.splitCount,
      splitMyShare: splitMyShare ?? this.splitMyShare,
      splitPendingAmount: splitPendingAmount ?? this.splitPendingAmount,
      splitSettled: splitSettled ?? this.splitSettled,
      ledgerType: ledgerType ?? this.ledgerType,
      syncId: syncId ?? this.syncId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (happenedAt.present) {
      map['happened_at'] = Variable<DateTime>(happenedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isSplit.present) {
      map['is_split'] = Variable<bool>(isSplit.value);
    }
    if (splitCount.present) {
      map['split_count'] = Variable<int>(splitCount.value);
    }
    if (splitMyShare.present) {
      map['split_my_share'] = Variable<double>(splitMyShare.value);
    }
    if (splitPendingAmount.present) {
      map['split_pending_amount'] = Variable<double>(splitPendingAmount.value);
    }
    if (splitSettled.present) {
      map['split_settled'] = Variable<bool>(splitSettled.value);
    }
    if (ledgerType.present) {
      map['ledger_type'] = Variable<String>(ledgerType.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpendlerTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('merchant: $merchant, ')
          ..write('note: $note, ')
          ..write('happenedAt: $happenedAt, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('isSplit: $isSplit, ')
          ..write('splitCount: $splitCount, ')
          ..write('splitMyShare: $splitMyShare, ')
          ..write('splitPendingAmount: $splitPendingAmount, ')
          ..write('splitSettled: $splitSettled, ')
          ..write('ledgerType: $ledgerType, ')
          ..write('syncId: $syncId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FamilyEntriesTable extends FamilyEntries
    with TableInfo<$FamilyEntriesTable, FamilyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromPersonMeta = const VerificationMeta(
    'fromPerson',
  );
  @override
  late final GeneratedColumn<String> fromPerson = GeneratedColumn<String>(
    'from_person',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _happenedAtMeta = const VerificationMeta(
    'happenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> happenedAt = GeneratedColumn<DateTime>(
    'happened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _investmentTypeMeta = const VerificationMeta(
    'investmentType',
  );
  @override
  late final GeneratedColumn<String> investmentType = GeneratedColumn<String>(
    'investment_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    amount,
    fromPerson,
    note,
    happenedAt,
    investmentType,
    syncId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('from_person')) {
      context.handle(
        _fromPersonMeta,
        fromPerson.isAcceptableOrUnknown(data['from_person']!, _fromPersonMeta),
      );
    } else if (isInserting) {
      context.missing(_fromPersonMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('happened_at')) {
      context.handle(
        _happenedAtMeta,
        happenedAt.isAcceptableOrUnknown(data['happened_at']!, _happenedAtMeta),
      );
    }
    if (data.containsKey('investment_type')) {
      context.handle(
        _investmentTypeMeta,
        investmentType.isAcceptableOrUnknown(
          data['investment_type']!,
          _investmentTypeMeta,
        ),
      );
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      fromPerson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_person'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      happenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}happened_at'],
      )!,
      investmentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}investment_type'],
      ),
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FamilyEntriesTable createAlias(String alias) {
    return $FamilyEntriesTable(attachedDatabase, alias);
  }
}

class FamilyEntry extends DataClass implements Insertable<FamilyEntry> {
  final int id;
  final String type;
  final double amount;
  final String fromPerson;
  final String? note;
  final DateTime happenedAt;
  final String? investmentType;
  final String? syncId;
  final DateTime createdAt;
  const FamilyEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.fromPerson,
    this.note,
    required this.happenedAt,
    this.investmentType,
    this.syncId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<double>(amount);
    map['from_person'] = Variable<String>(fromPerson);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['happened_at'] = Variable<DateTime>(happenedAt);
    if (!nullToAbsent || investmentType != null) {
      map['investment_type'] = Variable<String>(investmentType);
    }
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FamilyEntriesCompanion toCompanion(bool nullToAbsent) {
    return FamilyEntriesCompanion(
      id: Value(id),
      type: Value(type),
      amount: Value(amount),
      fromPerson: Value(fromPerson),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      happenedAt: Value(happenedAt),
      investmentType: investmentType == null && nullToAbsent
          ? const Value.absent()
          : Value(investmentType),
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      createdAt: Value(createdAt),
    );
  }

  factory FamilyEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyEntry(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<double>(json['amount']),
      fromPerson: serializer.fromJson<String>(json['fromPerson']),
      note: serializer.fromJson<String?>(json['note']),
      happenedAt: serializer.fromJson<DateTime>(json['happenedAt']),
      investmentType: serializer.fromJson<String?>(json['investmentType']),
      syncId: serializer.fromJson<String?>(json['syncId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<double>(amount),
      'fromPerson': serializer.toJson<String>(fromPerson),
      'note': serializer.toJson<String?>(note),
      'happenedAt': serializer.toJson<DateTime>(happenedAt),
      'investmentType': serializer.toJson<String?>(investmentType),
      'syncId': serializer.toJson<String?>(syncId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FamilyEntry copyWith({
    int? id,
    String? type,
    double? amount,
    String? fromPerson,
    Value<String?> note = const Value.absent(),
    DateTime? happenedAt,
    Value<String?> investmentType = const Value.absent(),
    Value<String?> syncId = const Value.absent(),
    DateTime? createdAt,
  }) => FamilyEntry(
    id: id ?? this.id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    fromPerson: fromPerson ?? this.fromPerson,
    note: note.present ? note.value : this.note,
    happenedAt: happenedAt ?? this.happenedAt,
    investmentType: investmentType.present
        ? investmentType.value
        : this.investmentType,
    syncId: syncId.present ? syncId.value : this.syncId,
    createdAt: createdAt ?? this.createdAt,
  );
  FamilyEntry copyWithCompanion(FamilyEntriesCompanion data) {
    return FamilyEntry(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      fromPerson: data.fromPerson.present
          ? data.fromPerson.value
          : this.fromPerson,
      note: data.note.present ? data.note.value : this.note,
      happenedAt: data.happenedAt.present
          ? data.happenedAt.value
          : this.happenedAt,
      investmentType: data.investmentType.present
          ? data.investmentType.value
          : this.investmentType,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyEntry(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('fromPerson: $fromPerson, ')
          ..write('note: $note, ')
          ..write('happenedAt: $happenedAt, ')
          ..write('investmentType: $investmentType, ')
          ..write('syncId: $syncId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amount,
    fromPerson,
    note,
    happenedAt,
    investmentType,
    syncId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyEntry &&
          other.id == this.id &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.fromPerson == this.fromPerson &&
          other.note == this.note &&
          other.happenedAt == this.happenedAt &&
          other.investmentType == this.investmentType &&
          other.syncId == this.syncId &&
          other.createdAt == this.createdAt);
}

class FamilyEntriesCompanion extends UpdateCompanion<FamilyEntry> {
  final Value<int> id;
  final Value<String> type;
  final Value<double> amount;
  final Value<String> fromPerson;
  final Value<String?> note;
  final Value<DateTime> happenedAt;
  final Value<String?> investmentType;
  final Value<String?> syncId;
  final Value<DateTime> createdAt;
  const FamilyEntriesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.fromPerson = const Value.absent(),
    this.note = const Value.absent(),
    this.happenedAt = const Value.absent(),
    this.investmentType = const Value.absent(),
    this.syncId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FamilyEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required double amount,
    required String fromPerson,
    this.note = const Value.absent(),
    this.happenedAt = const Value.absent(),
    this.investmentType = const Value.absent(),
    this.syncId = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : type = Value(type),
       amount = Value(amount),
       fromPerson = Value(fromPerson);
  static Insertable<FamilyEntry> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<String>? fromPerson,
    Expression<String>? note,
    Expression<DateTime>? happenedAt,
    Expression<String>? investmentType,
    Expression<String>? syncId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (fromPerson != null) 'from_person': fromPerson,
      if (note != null) 'note': note,
      if (happenedAt != null) 'happened_at': happenedAt,
      if (investmentType != null) 'investment_type': investmentType,
      if (syncId != null) 'sync_id': syncId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FamilyEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<double>? amount,
    Value<String>? fromPerson,
    Value<String?>? note,
    Value<DateTime>? happenedAt,
    Value<String?>? investmentType,
    Value<String?>? syncId,
    Value<DateTime>? createdAt,
  }) {
    return FamilyEntriesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      fromPerson: fromPerson ?? this.fromPerson,
      note: note ?? this.note,
      happenedAt: happenedAt ?? this.happenedAt,
      investmentType: investmentType ?? this.investmentType,
      syncId: syncId ?? this.syncId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (fromPerson.present) {
      map['from_person'] = Variable<String>(fromPerson.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (happenedAt.present) {
      map['happened_at'] = Variable<DateTime>(happenedAt.value);
    }
    if (investmentType.present) {
      map['investment_type'] = Variable<String>(investmentType.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyEntriesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('fromPerson: $fromPerson, ')
          ..write('note: $note, ')
          ..write('happenedAt: $happenedAt, ')
          ..write('investmentType: $investmentType, ')
          ..write('syncId: $syncId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WeeklyReflectionsTable extends WeeklyReflections
    with TableInfo<$WeeklyReflectionsTable, WeeklyReflection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyReflectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _weekStartDateMeta = const VerificationMeta(
    'weekStartDate',
  );
  @override
  late final GeneratedColumn<DateTime> weekStartDate =
      GeneratedColumn<DateTime>(
        'week_start_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _totalSpentMeta = const VerificationMeta(
    'totalSpent',
  );
  @override
  late final GeneratedColumn<double> totalSpent = GeneratedColumn<double>(
    'total_spent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topCategoryMeta = const VerificationMeta(
    'topCategory',
  );
  @override
  late final GeneratedColumn<String> topCategory = GeneratedColumn<String>(
    'top_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _llmReportGeneratedAtMeta =
      const VerificationMeta('llmReportGeneratedAt');
  @override
  late final GeneratedColumn<DateTime> llmReportGeneratedAt =
      GeneratedColumn<DateTime>(
        'llm_report_generated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weekStartDate,
    totalSpent,
    topCategory,
    openedAt,
    llmReportGeneratedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_reflections';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeeklyReflection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('week_start_date')) {
      context.handle(
        _weekStartDateMeta,
        weekStartDate.isAcceptableOrUnknown(
          data['week_start_date']!,
          _weekStartDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weekStartDateMeta);
    }
    if (data.containsKey('total_spent')) {
      context.handle(
        _totalSpentMeta,
        totalSpent.isAcceptableOrUnknown(data['total_spent']!, _totalSpentMeta),
      );
    } else if (isInserting) {
      context.missing(_totalSpentMeta);
    }
    if (data.containsKey('top_category')) {
      context.handle(
        _topCategoryMeta,
        topCategory.isAcceptableOrUnknown(
          data['top_category']!,
          _topCategoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_topCategoryMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    }
    if (data.containsKey('llm_report_generated_at')) {
      context.handle(
        _llmReportGeneratedAtMeta,
        llmReportGeneratedAt.isAcceptableOrUnknown(
          data['llm_report_generated_at']!,
          _llmReportGeneratedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeeklyReflection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyReflection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      weekStartDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}week_start_date'],
      )!,
      totalSpent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_spent'],
      )!,
      topCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}top_category'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      ),
      llmReportGeneratedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}llm_report_generated_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WeeklyReflectionsTable createAlias(String alias) {
    return $WeeklyReflectionsTable(attachedDatabase, alias);
  }
}

class WeeklyReflection extends DataClass
    implements Insertable<WeeklyReflection> {
  final int id;
  final DateTime weekStartDate;
  final double totalSpent;
  final String topCategory;
  final DateTime? openedAt;
  final DateTime? llmReportGeneratedAt;
  final DateTime createdAt;
  const WeeklyReflection({
    required this.id,
    required this.weekStartDate,
    required this.totalSpent,
    required this.topCategory,
    this.openedAt,
    this.llmReportGeneratedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['week_start_date'] = Variable<DateTime>(weekStartDate);
    map['total_spent'] = Variable<double>(totalSpent);
    map['top_category'] = Variable<String>(topCategory);
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<DateTime>(openedAt);
    }
    if (!nullToAbsent || llmReportGeneratedAt != null) {
      map['llm_report_generated_at'] = Variable<DateTime>(llmReportGeneratedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WeeklyReflectionsCompanion toCompanion(bool nullToAbsent) {
    return WeeklyReflectionsCompanion(
      id: Value(id),
      weekStartDate: Value(weekStartDate),
      totalSpent: Value(totalSpent),
      topCategory: Value(topCategory),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      llmReportGeneratedAt: llmReportGeneratedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(llmReportGeneratedAt),
      createdAt: Value(createdAt),
    );
  }

  factory WeeklyReflection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyReflection(
      id: serializer.fromJson<int>(json['id']),
      weekStartDate: serializer.fromJson<DateTime>(json['weekStartDate']),
      totalSpent: serializer.fromJson<double>(json['totalSpent']),
      topCategory: serializer.fromJson<String>(json['topCategory']),
      openedAt: serializer.fromJson<DateTime?>(json['openedAt']),
      llmReportGeneratedAt: serializer.fromJson<DateTime?>(
        json['llmReportGeneratedAt'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weekStartDate': serializer.toJson<DateTime>(weekStartDate),
      'totalSpent': serializer.toJson<double>(totalSpent),
      'topCategory': serializer.toJson<String>(topCategory),
      'openedAt': serializer.toJson<DateTime?>(openedAt),
      'llmReportGeneratedAt': serializer.toJson<DateTime?>(
        llmReportGeneratedAt,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WeeklyReflection copyWith({
    int? id,
    DateTime? weekStartDate,
    double? totalSpent,
    String? topCategory,
    Value<DateTime?> openedAt = const Value.absent(),
    Value<DateTime?> llmReportGeneratedAt = const Value.absent(),
    DateTime? createdAt,
  }) => WeeklyReflection(
    id: id ?? this.id,
    weekStartDate: weekStartDate ?? this.weekStartDate,
    totalSpent: totalSpent ?? this.totalSpent,
    topCategory: topCategory ?? this.topCategory,
    openedAt: openedAt.present ? openedAt.value : this.openedAt,
    llmReportGeneratedAt: llmReportGeneratedAt.present
        ? llmReportGeneratedAt.value
        : this.llmReportGeneratedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  WeeklyReflection copyWithCompanion(WeeklyReflectionsCompanion data) {
    return WeeklyReflection(
      id: data.id.present ? data.id.value : this.id,
      weekStartDate: data.weekStartDate.present
          ? data.weekStartDate.value
          : this.weekStartDate,
      totalSpent: data.totalSpent.present
          ? data.totalSpent.value
          : this.totalSpent,
      topCategory: data.topCategory.present
          ? data.topCategory.value
          : this.topCategory,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      llmReportGeneratedAt: data.llmReportGeneratedAt.present
          ? data.llmReportGeneratedAt.value
          : this.llmReportGeneratedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyReflection(')
          ..write('id: $id, ')
          ..write('weekStartDate: $weekStartDate, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('topCategory: $topCategory, ')
          ..write('openedAt: $openedAt, ')
          ..write('llmReportGeneratedAt: $llmReportGeneratedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    weekStartDate,
    totalSpent,
    topCategory,
    openedAt,
    llmReportGeneratedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyReflection &&
          other.id == this.id &&
          other.weekStartDate == this.weekStartDate &&
          other.totalSpent == this.totalSpent &&
          other.topCategory == this.topCategory &&
          other.openedAt == this.openedAt &&
          other.llmReportGeneratedAt == this.llmReportGeneratedAt &&
          other.createdAt == this.createdAt);
}

class WeeklyReflectionsCompanion extends UpdateCompanion<WeeklyReflection> {
  final Value<int> id;
  final Value<DateTime> weekStartDate;
  final Value<double> totalSpent;
  final Value<String> topCategory;
  final Value<DateTime?> openedAt;
  final Value<DateTime?> llmReportGeneratedAt;
  final Value<DateTime> createdAt;
  const WeeklyReflectionsCompanion({
    this.id = const Value.absent(),
    this.weekStartDate = const Value.absent(),
    this.totalSpent = const Value.absent(),
    this.topCategory = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.llmReportGeneratedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WeeklyReflectionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime weekStartDate,
    required double totalSpent,
    required String topCategory,
    this.openedAt = const Value.absent(),
    this.llmReportGeneratedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : weekStartDate = Value(weekStartDate),
       totalSpent = Value(totalSpent),
       topCategory = Value(topCategory);
  static Insertable<WeeklyReflection> custom({
    Expression<int>? id,
    Expression<DateTime>? weekStartDate,
    Expression<double>? totalSpent,
    Expression<String>? topCategory,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? llmReportGeneratedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weekStartDate != null) 'week_start_date': weekStartDate,
      if (totalSpent != null) 'total_spent': totalSpent,
      if (topCategory != null) 'top_category': topCategory,
      if (openedAt != null) 'opened_at': openedAt,
      if (llmReportGeneratedAt != null)
        'llm_report_generated_at': llmReportGeneratedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WeeklyReflectionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? weekStartDate,
    Value<double>? totalSpent,
    Value<String>? topCategory,
    Value<DateTime?>? openedAt,
    Value<DateTime?>? llmReportGeneratedAt,
    Value<DateTime>? createdAt,
  }) {
    return WeeklyReflectionsCompanion(
      id: id ?? this.id,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      totalSpent: totalSpent ?? this.totalSpent,
      topCategory: topCategory ?? this.topCategory,
      openedAt: openedAt ?? this.openedAt,
      llmReportGeneratedAt: llmReportGeneratedAt ?? this.llmReportGeneratedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weekStartDate.present) {
      map['week_start_date'] = Variable<DateTime>(weekStartDate.value);
    }
    if (totalSpent.present) {
      map['total_spent'] = Variable<double>(totalSpent.value);
    }
    if (topCategory.present) {
      map['top_category'] = Variable<String>(topCategory.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (llmReportGeneratedAt.present) {
      map['llm_report_generated_at'] = Variable<DateTime>(
        llmReportGeneratedAt.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyReflectionsCompanion(')
          ..write('id: $id, ')
          ..write('weekStartDate: $weekStartDate, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('topCategory: $topCategory, ')
          ..write('openedAt: $openedAt, ')
          ..write('llmReportGeneratedAt: $llmReportGeneratedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AppMetricsTable extends AppMetrics
    with TableInfo<$AppMetricsTable, AppMetric> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _metricTypeMeta = const VerificationMeta(
    'metricType',
  );
  @override
  late final GeneratedColumn<String> metricType = GeneratedColumn<String>(
    'metric_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, metricType, recordedAt, metadata];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_metrics';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetric> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('metric_type')) {
      context.handle(
        _metricTypeMeta,
        metricType.isAcceptableOrUnknown(data['metric_type']!, _metricTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_metricTypeMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppMetric map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetric(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      metricType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric_type'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
    );
  }

  @override
  $AppMetricsTable createAlias(String alias) {
    return $AppMetricsTable(attachedDatabase, alias);
  }
}

class AppMetric extends DataClass implements Insertable<AppMetric> {
  final int id;
  final String metricType;
  final DateTime recordedAt;
  final String? metadata;
  const AppMetric({
    required this.id,
    required this.metricType,
    required this.recordedAt,
    this.metadata,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['metric_type'] = Variable<String>(metricType);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  AppMetricsCompanion toCompanion(bool nullToAbsent) {
    return AppMetricsCompanion(
      id: Value(id),
      metricType: Value(metricType),
      recordedAt: Value(recordedAt),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory AppMetric.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetric(
      id: serializer.fromJson<int>(json['id']),
      metricType: serializer.fromJson<String>(json['metricType']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'metricType': serializer.toJson<String>(metricType),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  AppMetric copyWith({
    int? id,
    String? metricType,
    DateTime? recordedAt,
    Value<String?> metadata = const Value.absent(),
  }) => AppMetric(
    id: id ?? this.id,
    metricType: metricType ?? this.metricType,
    recordedAt: recordedAt ?? this.recordedAt,
    metadata: metadata.present ? metadata.value : this.metadata,
  );
  AppMetric copyWithCompanion(AppMetricsCompanion data) {
    return AppMetric(
      id: data.id.present ? data.id.value : this.id,
      metricType: data.metricType.present
          ? data.metricType.value
          : this.metricType,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetric(')
          ..write('id: $id, ')
          ..write('metricType: $metricType, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, metricType, recordedAt, metadata);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetric &&
          other.id == this.id &&
          other.metricType == this.metricType &&
          other.recordedAt == this.recordedAt &&
          other.metadata == this.metadata);
}

class AppMetricsCompanion extends UpdateCompanion<AppMetric> {
  final Value<int> id;
  final Value<String> metricType;
  final Value<DateTime> recordedAt;
  final Value<String?> metadata;
  const AppMetricsCompanion({
    this.id = const Value.absent(),
    this.metricType = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.metadata = const Value.absent(),
  });
  AppMetricsCompanion.insert({
    this.id = const Value.absent(),
    required String metricType,
    this.recordedAt = const Value.absent(),
    this.metadata = const Value.absent(),
  }) : metricType = Value(metricType);
  static Insertable<AppMetric> custom({
    Expression<int>? id,
    Expression<String>? metricType,
    Expression<DateTime>? recordedAt,
    Expression<String>? metadata,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (metricType != null) 'metric_type': metricType,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (metadata != null) 'metadata': metadata,
    });
  }

  AppMetricsCompanion copyWith({
    Value<int>? id,
    Value<String>? metricType,
    Value<DateTime>? recordedAt,
    Value<String?>? metadata,
  }) {
    return AppMetricsCompanion(
      id: id ?? this.id,
      metricType: metricType ?? this.metricType,
      recordedAt: recordedAt ?? this.recordedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (metricType.present) {
      map['metric_type'] = Variable<String>(metricType.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetricsCompanion(')
          ..write('id: $id, ')
          ..write('metricType: $metricType, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }
}

class $AppNotificationsTable extends AppNotifications
    with TableInfo<$AppNotificationsTable, AppNotification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, type, title, body, sentAt, isRead];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppNotification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppNotification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppNotification(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
    );
  }

  @override
  $AppNotificationsTable createAlias(String alias) {
    return $AppNotificationsTable(attachedDatabase, alias);
  }
}

class AppNotification extends DataClass implements Insertable<AppNotification> {
  final int id;
  final String type;
  final String title;
  final String body;
  final DateTime sentAt;
  final bool isRead;
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.sentAt,
    required this.isRead,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['sent_at'] = Variable<DateTime>(sentAt);
    map['is_read'] = Variable<bool>(isRead);
    return map;
  }

  AppNotificationsCompanion toCompanion(bool nullToAbsent) {
    return AppNotificationsCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      body: Value(body),
      sentAt: Value(sentAt),
      isRead: Value(isRead),
    );
  }

  factory AppNotification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppNotification(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      isRead: serializer.fromJson<bool>(json['isRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'isRead': serializer.toJson<bool>(isRead),
    };
  }

  AppNotification copyWith({
    int? id,
    String? type,
    String? title,
    String? body,
    DateTime? sentAt,
    bool? isRead,
  }) => AppNotification(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    body: body ?? this.body,
    sentAt: sentAt ?? this.sentAt,
    isRead: isRead ?? this.isRead,
  );
  AppNotification copyWithCompanion(AppNotificationsCompanion data) {
    return AppNotification(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppNotification(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('sentAt: $sentAt, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, title, body, sentAt, isRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppNotification &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.body == this.body &&
          other.sentAt == this.sentAt &&
          other.isRead == this.isRead);
}

class AppNotificationsCompanion extends UpdateCompanion<AppNotification> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> title;
  final Value<String> body;
  final Value<DateTime> sentAt;
  final Value<bool> isRead;
  const AppNotificationsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.isRead = const Value.absent(),
  });
  AppNotificationsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String title,
    required String body,
    this.sentAt = const Value.absent(),
    this.isRead = const Value.absent(),
  }) : type = Value(type),
       title = Value(title),
       body = Value(body);
  static Insertable<AppNotification> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? sentAt,
    Expression<bool>? isRead,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (sentAt != null) 'sent_at': sentAt,
      if (isRead != null) 'is_read': isRead,
    });
  }

  AppNotificationsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? title,
    Value<String>? body,
    Value<DateTime>? sentAt,
    Value<bool>? isRead,
  }) {
    return AppNotificationsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('sentAt: $sentAt, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }
}

class $FriendContactsTable extends FriendContacts
    with TableInfo<$FriendContactsTable, FriendContact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FriendContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 30),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarColourMeta = const VerificationMeta(
    'avatarColour',
  );
  @override
  late final GeneratedColumn<String> avatarColour = GeneratedColumn<String>(
    'avatar_colour',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    note,
    avatarColour,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'friend_contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<FriendContact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('avatar_colour')) {
      context.handle(
        _avatarColourMeta,
        avatarColour.isAcceptableOrUnknown(
          data['avatar_colour']!,
          _avatarColourMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avatarColourMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FriendContact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FriendContact(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      avatarColour: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_colour'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FriendContactsTable createAlias(String alias) {
    return $FriendContactsTable(attachedDatabase, alias);
  }
}

class FriendContact extends DataClass implements Insertable<FriendContact> {
  final int id;
  final String name;
  final String? note;
  final String avatarColour;
  final DateTime createdAt;
  const FriendContact({
    required this.id,
    required this.name,
    this.note,
    required this.avatarColour,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['avatar_colour'] = Variable<String>(avatarColour);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FriendContactsCompanion toCompanion(bool nullToAbsent) {
    return FriendContactsCompanion(
      id: Value(id),
      name: Value(name),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      avatarColour: Value(avatarColour),
      createdAt: Value(createdAt),
    );
  }

  factory FriendContact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FriendContact(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      note: serializer.fromJson<String?>(json['note']),
      avatarColour: serializer.fromJson<String>(json['avatarColour']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'note': serializer.toJson<String?>(note),
      'avatarColour': serializer.toJson<String>(avatarColour),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FriendContact copyWith({
    int? id,
    String? name,
    Value<String?> note = const Value.absent(),
    String? avatarColour,
    DateTime? createdAt,
  }) => FriendContact(
    id: id ?? this.id,
    name: name ?? this.name,
    note: note.present ? note.value : this.note,
    avatarColour: avatarColour ?? this.avatarColour,
    createdAt: createdAt ?? this.createdAt,
  );
  FriendContact copyWithCompanion(FriendContactsCompanion data) {
    return FriendContact(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      note: data.note.present ? data.note.value : this.note,
      avatarColour: data.avatarColour.present
          ? data.avatarColour.value
          : this.avatarColour,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FriendContact(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('avatarColour: $avatarColour, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, note, avatarColour, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FriendContact &&
          other.id == this.id &&
          other.name == this.name &&
          other.note == this.note &&
          other.avatarColour == this.avatarColour &&
          other.createdAt == this.createdAt);
}

class FriendContactsCompanion extends UpdateCompanion<FriendContact> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> note;
  final Value<String> avatarColour;
  final Value<DateTime> createdAt;
  const FriendContactsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.note = const Value.absent(),
    this.avatarColour = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FriendContactsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.note = const Value.absent(),
    required String avatarColour,
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       avatarColour = Value(avatarColour);
  static Insertable<FriendContact> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? note,
    Expression<String>? avatarColour,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (note != null) 'note': note,
      if (avatarColour != null) 'avatar_colour': avatarColour,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FriendContactsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? note,
    Value<String>? avatarColour,
    Value<DateTime>? createdAt,
  }) {
    return FriendContactsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      avatarColour: avatarColour ?? this.avatarColour,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (avatarColour.present) {
      map['avatar_colour'] = Variable<String>(avatarColour.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FriendContactsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('avatarColour: $avatarColour, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FriendSplitsTable extends FriendSplits
    with TableInfo<$FriendSplitsTable, FriendSplit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FriendSplitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _friendContactIdMeta = const VerificationMeta(
    'friendContactId',
  );
  @override
  late final GeneratedColumn<int> friendContactId = GeneratedColumn<int>(
    'friend_contact_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSettledMeta = const VerificationMeta(
    'isSettled',
  );
  @override
  late final GeneratedColumn<bool> isSettled = GeneratedColumn<bool>(
    'is_settled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_settled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isWrittenOffMeta = const VerificationMeta(
    'isWrittenOff',
  );
  @override
  late final GeneratedColumn<bool> isWrittenOff = GeneratedColumn<bool>(
    'is_written_off',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_written_off" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _settledAtMeta = const VerificationMeta(
    'settledAt',
  );
  @override
  late final GeneratedColumn<DateTime> settledAt = GeneratedColumn<DateTime>(
    'settled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _settlementMethodMeta = const VerificationMeta(
    'settlementMethod',
  );
  @override
  late final GeneratedColumn<String> settlementMethod = GeneratedColumn<String>(
    'settlement_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    friendContactId,
    amount,
    direction,
    isSettled,
    isWrittenOff,
    settledAt,
    settlementMethod,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'friend_splits';
  @override
  VerificationContext validateIntegrity(
    Insertable<FriendSplit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('friend_contact_id')) {
      context.handle(
        _friendContactIdMeta,
        friendContactId.isAcceptableOrUnknown(
          data['friend_contact_id']!,
          _friendContactIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_friendContactIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('is_settled')) {
      context.handle(
        _isSettledMeta,
        isSettled.isAcceptableOrUnknown(data['is_settled']!, _isSettledMeta),
      );
    }
    if (data.containsKey('is_written_off')) {
      context.handle(
        _isWrittenOffMeta,
        isWrittenOff.isAcceptableOrUnknown(
          data['is_written_off']!,
          _isWrittenOffMeta,
        ),
      );
    }
    if (data.containsKey('settled_at')) {
      context.handle(
        _settledAtMeta,
        settledAt.isAcceptableOrUnknown(data['settled_at']!, _settledAtMeta),
      );
    }
    if (data.containsKey('settlement_method')) {
      context.handle(
        _settlementMethodMeta,
        settlementMethod.isAcceptableOrUnknown(
          data['settlement_method']!,
          _settlementMethodMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FriendSplit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FriendSplit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_id'],
      )!,
      friendContactId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}friend_contact_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      isSettled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_settled'],
      )!,
      isWrittenOff: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_written_off'],
      )!,
      settledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}settled_at'],
      ),
      settlementMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settlement_method'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FriendSplitsTable createAlias(String alias) {
    return $FriendSplitsTable(attachedDatabase, alias);
  }
}

class FriendSplit extends DataClass implements Insertable<FriendSplit> {
  final int id;
  final int transactionId;
  final int friendContactId;
  final double amount;
  final String direction;
  final bool isSettled;
  final bool isWrittenOff;
  final DateTime? settledAt;
  final String? settlementMethod;
  final DateTime createdAt;
  const FriendSplit({
    required this.id,
    required this.transactionId,
    required this.friendContactId,
    required this.amount,
    required this.direction,
    required this.isSettled,
    required this.isWrittenOff,
    this.settledAt,
    this.settlementMethod,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transaction_id'] = Variable<int>(transactionId);
    map['friend_contact_id'] = Variable<int>(friendContactId);
    map['amount'] = Variable<double>(amount);
    map['direction'] = Variable<String>(direction);
    map['is_settled'] = Variable<bool>(isSettled);
    map['is_written_off'] = Variable<bool>(isWrittenOff);
    if (!nullToAbsent || settledAt != null) {
      map['settled_at'] = Variable<DateTime>(settledAt);
    }
    if (!nullToAbsent || settlementMethod != null) {
      map['settlement_method'] = Variable<String>(settlementMethod);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FriendSplitsCompanion toCompanion(bool nullToAbsent) {
    return FriendSplitsCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      friendContactId: Value(friendContactId),
      amount: Value(amount),
      direction: Value(direction),
      isSettled: Value(isSettled),
      isWrittenOff: Value(isWrittenOff),
      settledAt: settledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(settledAt),
      settlementMethod: settlementMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(settlementMethod),
      createdAt: Value(createdAt),
    );
  }

  factory FriendSplit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FriendSplit(
      id: serializer.fromJson<int>(json['id']),
      transactionId: serializer.fromJson<int>(json['transactionId']),
      friendContactId: serializer.fromJson<int>(json['friendContactId']),
      amount: serializer.fromJson<double>(json['amount']),
      direction: serializer.fromJson<String>(json['direction']),
      isSettled: serializer.fromJson<bool>(json['isSettled']),
      isWrittenOff: serializer.fromJson<bool>(json['isWrittenOff']),
      settledAt: serializer.fromJson<DateTime?>(json['settledAt']),
      settlementMethod: serializer.fromJson<String?>(json['settlementMethod']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transactionId': serializer.toJson<int>(transactionId),
      'friendContactId': serializer.toJson<int>(friendContactId),
      'amount': serializer.toJson<double>(amount),
      'direction': serializer.toJson<String>(direction),
      'isSettled': serializer.toJson<bool>(isSettled),
      'isWrittenOff': serializer.toJson<bool>(isWrittenOff),
      'settledAt': serializer.toJson<DateTime?>(settledAt),
      'settlementMethod': serializer.toJson<String?>(settlementMethod),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FriendSplit copyWith({
    int? id,
    int? transactionId,
    int? friendContactId,
    double? amount,
    String? direction,
    bool? isSettled,
    bool? isWrittenOff,
    Value<DateTime?> settledAt = const Value.absent(),
    Value<String?> settlementMethod = const Value.absent(),
    DateTime? createdAt,
  }) => FriendSplit(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    friendContactId: friendContactId ?? this.friendContactId,
    amount: amount ?? this.amount,
    direction: direction ?? this.direction,
    isSettled: isSettled ?? this.isSettled,
    isWrittenOff: isWrittenOff ?? this.isWrittenOff,
    settledAt: settledAt.present ? settledAt.value : this.settledAt,
    settlementMethod: settlementMethod.present
        ? settlementMethod.value
        : this.settlementMethod,
    createdAt: createdAt ?? this.createdAt,
  );
  FriendSplit copyWithCompanion(FriendSplitsCompanion data) {
    return FriendSplit(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      friendContactId: data.friendContactId.present
          ? data.friendContactId.value
          : this.friendContactId,
      amount: data.amount.present ? data.amount.value : this.amount,
      direction: data.direction.present ? data.direction.value : this.direction,
      isSettled: data.isSettled.present ? data.isSettled.value : this.isSettled,
      isWrittenOff: data.isWrittenOff.present
          ? data.isWrittenOff.value
          : this.isWrittenOff,
      settledAt: data.settledAt.present ? data.settledAt.value : this.settledAt,
      settlementMethod: data.settlementMethod.present
          ? data.settlementMethod.value
          : this.settlementMethod,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FriendSplit(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('friendContactId: $friendContactId, ')
          ..write('amount: $amount, ')
          ..write('direction: $direction, ')
          ..write('isSettled: $isSettled, ')
          ..write('isWrittenOff: $isWrittenOff, ')
          ..write('settledAt: $settledAt, ')
          ..write('settlementMethod: $settlementMethod, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionId,
    friendContactId,
    amount,
    direction,
    isSettled,
    isWrittenOff,
    settledAt,
    settlementMethod,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FriendSplit &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.friendContactId == this.friendContactId &&
          other.amount == this.amount &&
          other.direction == this.direction &&
          other.isSettled == this.isSettled &&
          other.isWrittenOff == this.isWrittenOff &&
          other.settledAt == this.settledAt &&
          other.settlementMethod == this.settlementMethod &&
          other.createdAt == this.createdAt);
}

class FriendSplitsCompanion extends UpdateCompanion<FriendSplit> {
  final Value<int> id;
  final Value<int> transactionId;
  final Value<int> friendContactId;
  final Value<double> amount;
  final Value<String> direction;
  final Value<bool> isSettled;
  final Value<bool> isWrittenOff;
  final Value<DateTime?> settledAt;
  final Value<String?> settlementMethod;
  final Value<DateTime> createdAt;
  const FriendSplitsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.friendContactId = const Value.absent(),
    this.amount = const Value.absent(),
    this.direction = const Value.absent(),
    this.isSettled = const Value.absent(),
    this.isWrittenOff = const Value.absent(),
    this.settledAt = const Value.absent(),
    this.settlementMethod = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FriendSplitsCompanion.insert({
    this.id = const Value.absent(),
    required int transactionId,
    required int friendContactId,
    required double amount,
    required String direction,
    this.isSettled = const Value.absent(),
    this.isWrittenOff = const Value.absent(),
    this.settledAt = const Value.absent(),
    this.settlementMethod = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : transactionId = Value(transactionId),
       friendContactId = Value(friendContactId),
       amount = Value(amount),
       direction = Value(direction);
  static Insertable<FriendSplit> custom({
    Expression<int>? id,
    Expression<int>? transactionId,
    Expression<int>? friendContactId,
    Expression<double>? amount,
    Expression<String>? direction,
    Expression<bool>? isSettled,
    Expression<bool>? isWrittenOff,
    Expression<DateTime>? settledAt,
    Expression<String>? settlementMethod,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (friendContactId != null) 'friend_contact_id': friendContactId,
      if (amount != null) 'amount': amount,
      if (direction != null) 'direction': direction,
      if (isSettled != null) 'is_settled': isSettled,
      if (isWrittenOff != null) 'is_written_off': isWrittenOff,
      if (settledAt != null) 'settled_at': settledAt,
      if (settlementMethod != null) 'settlement_method': settlementMethod,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FriendSplitsCompanion copyWith({
    Value<int>? id,
    Value<int>? transactionId,
    Value<int>? friendContactId,
    Value<double>? amount,
    Value<String>? direction,
    Value<bool>? isSettled,
    Value<bool>? isWrittenOff,
    Value<DateTime?>? settledAt,
    Value<String?>? settlementMethod,
    Value<DateTime>? createdAt,
  }) {
    return FriendSplitsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      friendContactId: friendContactId ?? this.friendContactId,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      isSettled: isSettled ?? this.isSettled,
      isWrittenOff: isWrittenOff ?? this.isWrittenOff,
      settledAt: settledAt ?? this.settledAt,
      settlementMethod: settlementMethod ?? this.settlementMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (friendContactId.present) {
      map['friend_contact_id'] = Variable<int>(friendContactId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (isSettled.present) {
      map['is_settled'] = Variable<bool>(isSettled.value);
    }
    if (isWrittenOff.present) {
      map['is_written_off'] = Variable<bool>(isWrittenOff.value);
    }
    if (settledAt.present) {
      map['settled_at'] = Variable<DateTime>(settledAt.value);
    }
    if (settlementMethod.present) {
      map['settlement_method'] = Variable<String>(settlementMethod.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FriendSplitsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('friendContactId: $friendContactId, ')
          ..write('amount: $amount, ')
          ..write('direction: $direction, ')
          ..write('isSettled: $isSettled, ')
          ..write('isWrittenOff: $isWrittenOff, ')
          ..write('settledAt: $settledAt, ')
          ..write('settlementMethod: $settlementMethod, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionsTable extends Subscriptions
    with TableInfo<$SubscriptionsTable, Subscription> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billingCycleMeta = const VerificationMeta(
    'billingCycle',
  );
  @override
  late final GeneratedColumn<String> billingCycle = GeneratedColumn<String>(
    'billing_cycle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextBillingDateMeta = const VerificationMeta(
    'nextBillingDate',
  );
  @override
  late final GeneratedColumn<DateTime> nextBillingDate =
      GeneratedColumn<DateTime>(
        'next_billing_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amount,
    billingCycle,
    nextBillingDate,
    category,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subscription> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('billing_cycle')) {
      context.handle(
        _billingCycleMeta,
        billingCycle.isAcceptableOrUnknown(
          data['billing_cycle']!,
          _billingCycleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_billingCycleMeta);
    }
    if (data.containsKey('next_billing_date')) {
      context.handle(
        _nextBillingDateMeta,
        nextBillingDate.isAcceptableOrUnknown(
          data['next_billing_date']!,
          _nextBillingDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextBillingDateMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subscription map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subscription(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      billingCycle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}billing_cycle'],
      )!,
      nextBillingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_billing_date'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }
}

class Subscription extends DataClass implements Insertable<Subscription> {
  final int id;
  final String name;
  final double amount;
  final String billingCycle;
  final DateTime nextBillingDate;
  final String category;
  final bool isActive;
  final DateTime createdAt;
  const Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.category,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    map['billing_cycle'] = Variable<String>(billingCycle);
    map['next_billing_date'] = Variable<DateTime>(nextBillingDate);
    map['category'] = Variable<String>(category);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      id: Value(id),
      name: Value(name),
      amount: Value(amount),
      billingCycle: Value(billingCycle),
      nextBillingDate: Value(nextBillingDate),
      category: Value(category),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory Subscription.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subscription(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      billingCycle: serializer.fromJson<String>(json['billingCycle']),
      nextBillingDate: serializer.fromJson<DateTime>(json['nextBillingDate']),
      category: serializer.fromJson<String>(json['category']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'billingCycle': serializer.toJson<String>(billingCycle),
      'nextBillingDate': serializer.toJson<DateTime>(nextBillingDate),
      'category': serializer.toJson<String>(category),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Subscription copyWith({
    int? id,
    String? name,
    double? amount,
    String? billingCycle,
    DateTime? nextBillingDate,
    String? category,
    bool? isActive,
    DateTime? createdAt,
  }) => Subscription(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    billingCycle: billingCycle ?? this.billingCycle,
    nextBillingDate: nextBillingDate ?? this.nextBillingDate,
    category: category ?? this.category,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  Subscription copyWithCompanion(SubscriptionsCompanion data) {
    return Subscription(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      billingCycle: data.billingCycle.present
          ? data.billingCycle.value
          : this.billingCycle,
      nextBillingDate: data.nextBillingDate.present
          ? data.nextBillingDate.value
          : this.nextBillingDate,
      category: data.category.present ? data.category.value : this.category,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subscription(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('billingCycle: $billingCycle, ')
          ..write('nextBillingDate: $nextBillingDate, ')
          ..write('category: $category, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    billingCycle,
    nextBillingDate,
    category,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subscription &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.billingCycle == this.billingCycle &&
          other.nextBillingDate == this.nextBillingDate &&
          other.category == this.category &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class SubscriptionsCompanion extends UpdateCompanion<Subscription> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> amount;
  final Value<String> billingCycle;
  final Value<DateTime> nextBillingDate;
  final Value<String> category;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  const SubscriptionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.billingCycle = const Value.absent(),
    this.nextBillingDate = const Value.absent(),
    this.category = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double amount,
    required String billingCycle,
    required DateTime nextBillingDate,
    required String category,
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       amount = Value(amount),
       billingCycle = Value(billingCycle),
       nextBillingDate = Value(nextBillingDate),
       category = Value(category);
  static Insertable<Subscription> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<String>? billingCycle,
    Expression<DateTime>? nextBillingDate,
    Expression<String>? category,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (billingCycle != null) 'billing_cycle': billingCycle,
      if (nextBillingDate != null) 'next_billing_date': nextBillingDate,
      if (category != null) 'category': category,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SubscriptionsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? amount,
    Value<String>? billingCycle,
    Value<DateTime>? nextBillingDate,
    Value<String>? category,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
  }) {
    return SubscriptionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (billingCycle.present) {
      map['billing_cycle'] = Variable<String>(billingCycle.value);
    }
    if (nextBillingDate.present) {
      map['next_billing_date'] = Variable<DateTime>(nextBillingDate.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('billingCycle: $billingCycle, ')
          ..write('nextBillingDate: $nextBillingDate, ')
          ..write('category: $category, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}


class $CategoryBudgetsTable extends CategoryBudgets
    with TableInfo<$CategoryBudgetsTable, CategoryBudget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryBudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthlyLimitMeta = const VerificationMeta(
    'monthlyLimit',
  );
  @override
  late final GeneratedColumn<double> monthlyLimit = GeneratedColumn<double>(
    'monthly_limit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, category, monthlyLimit, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryBudget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('monthly_limit')) {
      context.handle(
        _monthlyLimitMeta,
        monthlyLimit.isAcceptableOrUnknown(
          data['monthly_limit']!,
          _monthlyLimitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_monthlyLimitMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryBudget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryBudget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      monthlyLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_limit'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CategoryBudgetsTable createAlias(String alias) {
    return $CategoryBudgetsTable(attachedDatabase, alias);
  }
}

class CategoryBudget extends DataClass implements Insertable<CategoryBudget> {
  final int id;
  final String category;
  final double monthlyLimit;
  final DateTime createdAt;
  const CategoryBudget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category'] = Variable<String>(category);
    map['monthly_limit'] = Variable<double>(monthlyLimit);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CategoryBudgetsCompanion toCompanion(bool nullToAbsent) {
    return CategoryBudgetsCompanion(
      id: Value(id),
      category: Value(category),
      monthlyLimit: Value(monthlyLimit),
      createdAt: Value(createdAt),
    );
  }

  factory CategoryBudget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryBudget(
      id: serializer.fromJson<int>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      monthlyLimit: serializer.fromJson<double>(json['monthlyLimit']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'category': serializer.toJson<String>(category),
      'monthlyLimit': serializer.toJson<double>(monthlyLimit),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CategoryBudget copyWith({
    int? id,
    String? category,
    double? monthlyLimit,
    DateTime? createdAt,
  }) => CategoryBudget(
    id: id ?? this.id,
    category: category ?? this.category,
    monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    createdAt: createdAt ?? this.createdAt,
  );
  CategoryBudget copyWithCompanion(CategoryBudgetsCompanion data) {
    return CategoryBudget(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      monthlyLimit: data.monthlyLimit.present
          ? data.monthlyLimit.value
          : this.monthlyLimit,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryBudget(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('monthlyLimit: $monthlyLimit, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, category, monthlyLimit, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryBudget &&
          other.id == this.id &&
          other.category == this.category &&
          other.monthlyLimit == this.monthlyLimit &&
          other.createdAt == this.createdAt);
}

class CategoryBudgetsCompanion extends UpdateCompanion<CategoryBudget> {
  final Value<int> id;
  final Value<String> category;
  final Value<double> monthlyLimit;
  final Value<DateTime> createdAt;
  const CategoryBudgetsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.monthlyLimit = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CategoryBudgetsCompanion.insert({
    this.id = const Value.absent(),
    required String category,
    required double monthlyLimit,
    this.createdAt = const Value.absent(),
  }) : category = Value(category),
       monthlyLimit = Value(monthlyLimit);
  static Insertable<CategoryBudget> custom({
    Expression<int>? id,
    Expression<String>? category,
    Expression<double>? monthlyLimit,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (monthlyLimit != null) 'monthly_limit': monthlyLimit,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CategoryBudgetsCompanion copyWith({
    Value<int>? id,
    Value<String>? category,
    Value<double>? monthlyLimit,
    Value<DateTime>? createdAt,
  }) {
    return CategoryBudgetsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (monthlyLimit.present) {
      map['monthly_limit'] = Variable<double>(monthlyLimit.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryBudgetsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('monthlyLimit: $monthlyLimit, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SavingsGoalsTable extends SavingsGoals
    with TableInfo<$SavingsGoalsTable, SavingsGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetAmountMeta = const VerificationMeta(
    'targetAmount',
  );
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
    'target_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentAmountMeta = const VerificationMeta(
    'currentAmount',
  );
  @override
  late final GeneratedColumn<double> currentAmount = GeneratedColumn<double>(
    'current_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _iconNameMeta = const VerificationMeta(
    'iconName',
  );
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
    'icon_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    targetAmount,
    currentAmount,
    iconName,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsGoal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
        _targetAmountMeta,
        targetAmount.isAcceptableOrUnknown(
          data['target_amount']!,
          _targetAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetAmountMeta);
    }
    if (data.containsKey('current_amount')) {
      context.handle(
        _currentAmountMeta,
        currentAmount.isAcceptableOrUnknown(
          data['current_amount']!,
          _currentAmountMeta,
        ),
      );
    }
    if (data.containsKey('icon_name')) {
      context.handle(
        _iconNameMeta,
        iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta),
      );
    } else if (isInserting) {
      context.missing(_iconNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsGoal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      targetAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_amount'],
      )!,
      currentAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_amount'],
      )!,
      iconName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SavingsGoalsTable createAlias(String alias) {
    return $SavingsGoalsTable(attachedDatabase, alias);
  }
}

class SavingsGoal extends DataClass implements Insertable<SavingsGoal> {
  final int id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String iconName;
  final DateTime createdAt;
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.iconName,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['target_amount'] = Variable<double>(targetAmount);
    map['current_amount'] = Variable<double>(currentAmount);
    map['icon_name'] = Variable<String>(iconName);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SavingsGoalsCompanion toCompanion(bool nullToAbsent) {
    return SavingsGoalsCompanion(
      id: Value(id),
      name: Value(name),
      targetAmount: Value(targetAmount),
      currentAmount: Value(currentAmount),
      iconName: Value(iconName),
      createdAt: Value(createdAt),
    );
  }

  factory SavingsGoal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsGoal(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetAmount: serializer.fromJson<double>(json['targetAmount']),
      currentAmount: serializer.fromJson<double>(json['currentAmount']),
      iconName: serializer.fromJson<String>(json['iconName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'targetAmount': serializer.toJson<double>(targetAmount),
      'currentAmount': serializer.toJson<double>(currentAmount),
      'iconName': serializer.toJson<String>(iconName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SavingsGoal copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? iconName,
    DateTime? createdAt,
  }) => SavingsGoal(
    id: id ?? this.id,
    name: name ?? this.name,
    targetAmount: targetAmount ?? this.targetAmount,
    currentAmount: currentAmount ?? this.currentAmount,
    iconName: iconName ?? this.iconName,
    createdAt: createdAt ?? this.createdAt,
  );
  SavingsGoal copyWithCompanion(SavingsGoalsCompanion data) {
    return SavingsGoal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      currentAmount: data.currentAmount.present
          ? data.currentAmount.value
          : this.currentAmount,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('currentAmount: $currentAmount, ')
          ..write('iconName: $iconName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, targetAmount, currentAmount, iconName, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsGoal &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetAmount == this.targetAmount &&
          other.currentAmount == this.currentAmount &&
          other.iconName == this.iconName &&
          other.createdAt == this.createdAt);
}

class SavingsGoalsCompanion extends UpdateCompanion<SavingsGoal> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> targetAmount;
  final Value<double> currentAmount;
  final Value<String> iconName;
  final Value<DateTime> createdAt;
  const SavingsGoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.currentAmount = const Value.absent(),
    this.iconName = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SavingsGoalsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double targetAmount,
    this.currentAmount = const Value.absent(),
    required String iconName,
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       targetAmount = Value(targetAmount),
       iconName = Value(iconName);
  static Insertable<SavingsGoal> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? targetAmount,
    Expression<double>? currentAmount,
    Expression<String>? iconName,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (currentAmount != null) 'current_amount': currentAmount,
      if (iconName != null) 'icon_name': iconName,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SavingsGoalsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? targetAmount,
    Value<double>? currentAmount,
    Value<String>? iconName,
    Value<DateTime>? createdAt,
  }) {
    return SavingsGoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<double>(targetAmount.value);
    }
    if (currentAmount.present) {
      map['current_amount'] = Variable<double>(currentAmount.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('currentAmount: $currentAmount, ')
          ..write('iconName: $iconName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}


abstract class _$SpendlerDatabase extends GeneratedDatabase {
  _$SpendlerDatabase(QueryExecutor e) : super(e);
  $SpendlerDatabaseManager get managers => $SpendlerDatabaseManager(this);
  late final $SpendlerTransactionsTable spendlerTransactions =
      $SpendlerTransactionsTable(this);
  late final $FamilyEntriesTable familyEntries = $FamilyEntriesTable(this);
  late final $WeeklyReflectionsTable weeklyReflections =
      $WeeklyReflectionsTable(this);
  late final $AppMetricsTable appMetrics = $AppMetricsTable(this);
  late final $AppNotificationsTable appNotifications = $AppNotificationsTable(
    this,
  );
  late final $FriendContactsTable friendContacts = $FriendContactsTable(this);
  late final $FriendSplitsTable friendSplits = $FriendSplitsTable(this);
  late final $SubscriptionsTable subscriptions = $SubscriptionsTable(this);
  late final $CategoryBudgetsTable categoryBudgets = $CategoryBudgetsTable(this);
  late final $SavingsGoalsTable savingsGoals = $SavingsGoalsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    spendlerTransactions,
    familyEntries,
    weeklyReflections,
    appMetrics,
    appNotifications,
    friendContacts,
    friendSplits,
    subscriptions,
    categoryBudgets,
    savingsGoals,
  ];
}

typedef $$SpendlerTransactionsTableCreateCompanionBuilder =
    SpendlerTransactionsCompanion Function({
      Value<int> id,
      required double amount,
      required String category,
      Value<String?> merchant,
      Value<String?> note,
      Value<DateTime> happenedAt,
      Value<String> source,
      Value<String> status,
      Value<bool> isSplit,
      Value<int?> splitCount,
      Value<double?> splitMyShare,
      Value<double?> splitPendingAmount,
      Value<bool> splitSettled,
      Value<String> ledgerType,
      Value<String?> syncId,
      Value<DateTime> createdAt,
    });
typedef $$SpendlerTransactionsTableUpdateCompanionBuilder =
    SpendlerTransactionsCompanion Function({
      Value<int> id,
      Value<double> amount,
      Value<String> category,
      Value<String?> merchant,
      Value<String?> note,
      Value<DateTime> happenedAt,
      Value<String> source,
      Value<String> status,
      Value<bool> isSplit,
      Value<int?> splitCount,
      Value<double?> splitMyShare,
      Value<double?> splitPendingAmount,
      Value<bool> splitSettled,
      Value<String> ledgerType,
      Value<String?> syncId,
      Value<DateTime> createdAt,
    });

class $$SpendlerTransactionsTableFilterComposer
    extends Composer<_$SpendlerDatabase, $SpendlerTransactionsTable> {
  $$SpendlerTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get happenedAt => $composableBuilder(
    column: $table.happenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSplit => $composableBuilder(
    column: $table.isSplit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get splitCount => $composableBuilder(
    column: $table.splitCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get splitMyShare => $composableBuilder(
    column: $table.splitMyShare,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get splitPendingAmount => $composableBuilder(
    column: $table.splitPendingAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get splitSettled => $composableBuilder(
    column: $table.splitSettled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ledgerType => $composableBuilder(
    column: $table.ledgerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SpendlerTransactionsTableOrderingComposer
    extends Composer<_$SpendlerDatabase, $SpendlerTransactionsTable> {
  $$SpendlerTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get happenedAt => $composableBuilder(
    column: $table.happenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSplit => $composableBuilder(
    column: $table.isSplit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get splitCount => $composableBuilder(
    column: $table.splitCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get splitMyShare => $composableBuilder(
    column: $table.splitMyShare,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get splitPendingAmount => $composableBuilder(
    column: $table.splitPendingAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get splitSettled => $composableBuilder(
    column: $table.splitSettled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ledgerType => $composableBuilder(
    column: $table.ledgerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SpendlerTransactionsTableAnnotationComposer
    extends Composer<_$SpendlerDatabase, $SpendlerTransactionsTable> {
  $$SpendlerTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get happenedAt => $composableBuilder(
    column: $table.happenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isSplit =>
      $composableBuilder(column: $table.isSplit, builder: (column) => column);

  GeneratedColumn<int> get splitCount => $composableBuilder(
    column: $table.splitCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get splitMyShare => $composableBuilder(
    column: $table.splitMyShare,
    builder: (column) => column,
  );

  GeneratedColumn<double> get splitPendingAmount => $composableBuilder(
    column: $table.splitPendingAmount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get splitSettled => $composableBuilder(
    column: $table.splitSettled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ledgerType => $composableBuilder(
    column: $table.ledgerType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SpendlerTransactionsTableTableManager
    extends
        RootTableManager<
          _$SpendlerDatabase,
          $SpendlerTransactionsTable,
          SpendlerTransaction,
          $$SpendlerTransactionsTableFilterComposer,
          $$SpendlerTransactionsTableOrderingComposer,
          $$SpendlerTransactionsTableAnnotationComposer,
          $$SpendlerTransactionsTableCreateCompanionBuilder,
          $$SpendlerTransactionsTableUpdateCompanionBuilder,
          (
            SpendlerTransaction,
            BaseReferences<
              _$SpendlerDatabase,
              $SpendlerTransactionsTable,
              SpendlerTransaction
            >,
          ),
          SpendlerTransaction,
          PrefetchHooks Function()
        > {
  $$SpendlerTransactionsTableTableManager(
    _$SpendlerDatabase db,
    $SpendlerTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpendlerTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpendlerTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpendlerTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> happenedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isSplit = const Value.absent(),
                Value<int?> splitCount = const Value.absent(),
                Value<double?> splitMyShare = const Value.absent(),
                Value<double?> splitPendingAmount = const Value.absent(),
                Value<bool> splitSettled = const Value.absent(),
                Value<String> ledgerType = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SpendlerTransactionsCompanion(
                id: id,
                amount: amount,
                category: category,
                merchant: merchant,
                note: note,
                happenedAt: happenedAt,
                source: source,
                status: status,
                isSplit: isSplit,
                splitCount: splitCount,
                splitMyShare: splitMyShare,
                splitPendingAmount: splitPendingAmount,
                splitSettled: splitSettled,
                ledgerType: ledgerType,
                syncId: syncId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double amount,
                required String category,
                Value<String?> merchant = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> happenedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isSplit = const Value.absent(),
                Value<int?> splitCount = const Value.absent(),
                Value<double?> splitMyShare = const Value.absent(),
                Value<double?> splitPendingAmount = const Value.absent(),
                Value<bool> splitSettled = const Value.absent(),
                Value<String> ledgerType = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SpendlerTransactionsCompanion.insert(
                id: id,
                amount: amount,
                category: category,
                merchant: merchant,
                note: note,
                happenedAt: happenedAt,
                source: source,
                status: status,
                isSplit: isSplit,
                splitCount: splitCount,
                splitMyShare: splitMyShare,
                splitPendingAmount: splitPendingAmount,
                splitSettled: splitSettled,
                ledgerType: ledgerType,
                syncId: syncId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SpendlerTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SpendlerDatabase,
      $SpendlerTransactionsTable,
      SpendlerTransaction,
      $$SpendlerTransactionsTableFilterComposer,
      $$SpendlerTransactionsTableOrderingComposer,
      $$SpendlerTransactionsTableAnnotationComposer,
      $$SpendlerTransactionsTableCreateCompanionBuilder,
      $$SpendlerTransactionsTableUpdateCompanionBuilder,
      (
        SpendlerTransaction,
        BaseReferences<
          _$SpendlerDatabase,
          $SpendlerTransactionsTable,
          SpendlerTransaction
        >,
      ),
      SpendlerTransaction,
      PrefetchHooks Function()
    >;
typedef $$FamilyEntriesTableCreateCompanionBuilder =
    FamilyEntriesCompanion Function({
      Value<int> id,
      required String type,
      required double amount,
      required String fromPerson,
      Value<String?> note,
      Value<DateTime> happenedAt,
      Value<String?> investmentType,
      Value<String?> syncId,
      Value<DateTime> createdAt,
    });
typedef $$FamilyEntriesTableUpdateCompanionBuilder =
    FamilyEntriesCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<double> amount,
      Value<String> fromPerson,
      Value<String?> note,
      Value<DateTime> happenedAt,
      Value<String?> investmentType,
      Value<String?> syncId,
      Value<DateTime> createdAt,
    });

class $$FamilyEntriesTableFilterComposer
    extends Composer<_$SpendlerDatabase, $FamilyEntriesTable> {
  $$FamilyEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromPerson => $composableBuilder(
    column: $table.fromPerson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get happenedAt => $composableBuilder(
    column: $table.happenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get investmentType => $composableBuilder(
    column: $table.investmentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FamilyEntriesTableOrderingComposer
    extends Composer<_$SpendlerDatabase, $FamilyEntriesTable> {
  $$FamilyEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromPerson => $composableBuilder(
    column: $table.fromPerson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get happenedAt => $composableBuilder(
    column: $table.happenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get investmentType => $composableBuilder(
    column: $table.investmentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FamilyEntriesTableAnnotationComposer
    extends Composer<_$SpendlerDatabase, $FamilyEntriesTable> {
  $$FamilyEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get fromPerson => $composableBuilder(
    column: $table.fromPerson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get happenedAt => $composableBuilder(
    column: $table.happenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get investmentType => $composableBuilder(
    column: $table.investmentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FamilyEntriesTableTableManager
    extends
        RootTableManager<
          _$SpendlerDatabase,
          $FamilyEntriesTable,
          FamilyEntry,
          $$FamilyEntriesTableFilterComposer,
          $$FamilyEntriesTableOrderingComposer,
          $$FamilyEntriesTableAnnotationComposer,
          $$FamilyEntriesTableCreateCompanionBuilder,
          $$FamilyEntriesTableUpdateCompanionBuilder,
          (
            FamilyEntry,
            BaseReferences<_$SpendlerDatabase, $FamilyEntriesTable, FamilyEntry>,
          ),
          FamilyEntry,
          PrefetchHooks Function()
        > {
  $$FamilyEntriesTableTableManager(
    _$SpendlerDatabase db,
    $FamilyEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamilyEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> fromPerson = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> happenedAt = const Value.absent(),
                Value<String?> investmentType = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FamilyEntriesCompanion(
                id: id,
                type: type,
                amount: amount,
                fromPerson: fromPerson,
                note: note,
                happenedAt: happenedAt,
                investmentType: investmentType,
                syncId: syncId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required double amount,
                required String fromPerson,
                Value<String?> note = const Value.absent(),
                Value<DateTime> happenedAt = const Value.absent(),
                Value<String?> investmentType = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FamilyEntriesCompanion.insert(
                id: id,
                type: type,
                amount: amount,
                fromPerson: fromPerson,
                note: note,
                happenedAt: happenedAt,
                investmentType: investmentType,
                syncId: syncId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FamilyEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$SpendlerDatabase,
      $FamilyEntriesTable,
      FamilyEntry,
      $$FamilyEntriesTableFilterComposer,
      $$FamilyEntriesTableOrderingComposer,
      $$FamilyEntriesTableAnnotationComposer,
      $$FamilyEntriesTableCreateCompanionBuilder,
      $$FamilyEntriesTableUpdateCompanionBuilder,
      (
        FamilyEntry,
        BaseReferences<_$SpendlerDatabase, $FamilyEntriesTable, FamilyEntry>,
      ),
      FamilyEntry,
      PrefetchHooks Function()
    >;
typedef $$WeeklyReflectionsTableCreateCompanionBuilder =
    WeeklyReflectionsCompanion Function({
      Value<int> id,
      required DateTime weekStartDate,
      required double totalSpent,
      required String topCategory,
      Value<DateTime?> openedAt,
      Value<DateTime?> llmReportGeneratedAt,
      Value<DateTime> createdAt,
    });
typedef $$WeeklyReflectionsTableUpdateCompanionBuilder =
    WeeklyReflectionsCompanion Function({
      Value<int> id,
      Value<DateTime> weekStartDate,
      Value<double> totalSpent,
      Value<String> topCategory,
      Value<DateTime?> openedAt,
      Value<DateTime?> llmReportGeneratedAt,
      Value<DateTime> createdAt,
    });

class $$WeeklyReflectionsTableFilterComposer
    extends Composer<_$SpendlerDatabase, $WeeklyReflectionsTable> {
  $$WeeklyReflectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get weekStartDate => $composableBuilder(
    column: $table.weekStartDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topCategory => $composableBuilder(
    column: $table.topCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get llmReportGeneratedAt => $composableBuilder(
    column: $table.llmReportGeneratedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeeklyReflectionsTableOrderingComposer
    extends Composer<_$SpendlerDatabase, $WeeklyReflectionsTable> {
  $$WeeklyReflectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get weekStartDate => $composableBuilder(
    column: $table.weekStartDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topCategory => $composableBuilder(
    column: $table.topCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get llmReportGeneratedAt => $composableBuilder(
    column: $table.llmReportGeneratedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeeklyReflectionsTableAnnotationComposer
    extends Composer<_$SpendlerDatabase, $WeeklyReflectionsTable> {
  $$WeeklyReflectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get weekStartDate => $composableBuilder(
    column: $table.weekStartDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get topCategory => $composableBuilder(
    column: $table.topCategory,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get llmReportGeneratedAt => $composableBuilder(
    column: $table.llmReportGeneratedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$WeeklyReflectionsTableTableManager
    extends
        RootTableManager<
          _$SpendlerDatabase,
          $WeeklyReflectionsTable,
          WeeklyReflection,
          $$WeeklyReflectionsTableFilterComposer,
          $$WeeklyReflectionsTableOrderingComposer,
          $$WeeklyReflectionsTableAnnotationComposer,
          $$WeeklyReflectionsTableCreateCompanionBuilder,
          $$WeeklyReflectionsTableUpdateCompanionBuilder,
          (
            WeeklyReflection,
            BaseReferences<
              _$SpendlerDatabase,
              $WeeklyReflectionsTable,
              WeeklyReflection
            >,
          ),
          WeeklyReflection,
          PrefetchHooks Function()
        > {
  $$WeeklyReflectionsTableTableManager(
    _$SpendlerDatabase db,
    $WeeklyReflectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklyReflectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeklyReflectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeeklyReflectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> weekStartDate = const Value.absent(),
                Value<double> totalSpent = const Value.absent(),
                Value<String> topCategory = const Value.absent(),
                Value<DateTime?> openedAt = const Value.absent(),
                Value<DateTime?> llmReportGeneratedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WeeklyReflectionsCompanion(
                id: id,
                weekStartDate: weekStartDate,
                totalSpent: totalSpent,
                topCategory: topCategory,
                openedAt: openedAt,
                llmReportGeneratedAt: llmReportGeneratedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime weekStartDate,
                required double totalSpent,
                required String topCategory,
                Value<DateTime?> openedAt = const Value.absent(),
                Value<DateTime?> llmReportGeneratedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WeeklyReflectionsCompanion.insert(
                id: id,
                weekStartDate: weekStartDate,
                totalSpent: totalSpent,
                topCategory: topCategory,
                openedAt: openedAt,
                llmReportGeneratedAt: llmReportGeneratedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeeklyReflectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SpendlerDatabase,
      $WeeklyReflectionsTable,
      WeeklyReflection,
      $$WeeklyReflectionsTableFilterComposer,
      $$WeeklyReflectionsTableOrderingComposer,
      $$WeeklyReflectionsTableAnnotationComposer,
      $$WeeklyReflectionsTableCreateCompanionBuilder,
      $$WeeklyReflectionsTableUpdateCompanionBuilder,
      (
        WeeklyReflection,
        BaseReferences<
          _$SpendlerDatabase,
          $WeeklyReflectionsTable,
          WeeklyReflection
        >,
      ),
      WeeklyReflection,
      PrefetchHooks Function()
    >;
typedef $$AppMetricsTableCreateCompanionBuilder =
    AppMetricsCompanion Function({
      Value<int> id,
      required String metricType,
      Value<DateTime> recordedAt,
      Value<String?> metadata,
    });
typedef $$AppMetricsTableUpdateCompanionBuilder =
    AppMetricsCompanion Function({
      Value<int> id,
      Value<String> metricType,
      Value<DateTime> recordedAt,
      Value<String?> metadata,
    });

class $$AppMetricsTableFilterComposer
    extends Composer<_$SpendlerDatabase, $AppMetricsTable> {
  $$AppMetricsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metricType => $composableBuilder(
    column: $table.metricType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetricsTableOrderingComposer
    extends Composer<_$SpendlerDatabase, $AppMetricsTable> {
  $$AppMetricsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metricType => $composableBuilder(
    column: $table.metricType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetricsTableAnnotationComposer
    extends Composer<_$SpendlerDatabase, $AppMetricsTable> {
  $$AppMetricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get metricType => $composableBuilder(
    column: $table.metricType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);
}

class $$AppMetricsTableTableManager
    extends
        RootTableManager<
          _$SpendlerDatabase,
          $AppMetricsTable,
          AppMetric,
          $$AppMetricsTableFilterComposer,
          $$AppMetricsTableOrderingComposer,
          $$AppMetricsTableAnnotationComposer,
          $$AppMetricsTableCreateCompanionBuilder,
          $$AppMetricsTableUpdateCompanionBuilder,
          (
            AppMetric,
            BaseReferences<_$SpendlerDatabase, $AppMetricsTable, AppMetric>,
          ),
          AppMetric,
          PrefetchHooks Function()
        > {
  $$AppMetricsTableTableManager(_$SpendlerDatabase db, $AppMetricsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> metricType = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
              }) => AppMetricsCompanion(
                id: id,
                metricType: metricType,
                recordedAt: recordedAt,
                metadata: metadata,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String metricType,
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
              }) => AppMetricsCompanion.insert(
                id: id,
                metricType: metricType,
                recordedAt: recordedAt,
                metadata: metadata,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetricsTableProcessedTableManager =
    ProcessedTableManager<
      _$SpendlerDatabase,
      $AppMetricsTable,
      AppMetric,
      $$AppMetricsTableFilterComposer,
      $$AppMetricsTableOrderingComposer,
      $$AppMetricsTableAnnotationComposer,
      $$AppMetricsTableCreateCompanionBuilder,
      $$AppMetricsTableUpdateCompanionBuilder,
      (AppMetric, BaseReferences<_$SpendlerDatabase, $AppMetricsTable, AppMetric>),
      AppMetric,
      PrefetchHooks Function()
    >;
typedef $$AppNotificationsTableCreateCompanionBuilder =
    AppNotificationsCompanion Function({
      Value<int> id,
      required String type,
      required String title,
      required String body,
      Value<DateTime> sentAt,
      Value<bool> isRead,
    });
typedef $$AppNotificationsTableUpdateCompanionBuilder =
    AppNotificationsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> title,
      Value<String> body,
      Value<DateTime> sentAt,
      Value<bool> isRead,
    });

class $$AppNotificationsTableFilterComposer
    extends Composer<_$SpendlerDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppNotificationsTableOrderingComposer
    extends Composer<_$SpendlerDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppNotificationsTableAnnotationComposer
    extends Composer<_$SpendlerDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);
}

class $$AppNotificationsTableTableManager
    extends
        RootTableManager<
          _$SpendlerDatabase,
          $AppNotificationsTable,
          AppNotification,
          $$AppNotificationsTableFilterComposer,
          $$AppNotificationsTableOrderingComposer,
          $$AppNotificationsTableAnnotationComposer,
          $$AppNotificationsTableCreateCompanionBuilder,
          $$AppNotificationsTableUpdateCompanionBuilder,
          (
            AppNotification,
            BaseReferences<
              _$SpendlerDatabase,
              $AppNotificationsTable,
              AppNotification
            >,
          ),
          AppNotification,
          PrefetchHooks Function()
        > {
  $$AppNotificationsTableTableManager(
    _$SpendlerDatabase db,
    $AppNotificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppNotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppNotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
              }) => AppNotificationsCompanion(
                id: id,
                type: type,
                title: title,
                body: body,
                sentAt: sentAt,
                isRead: isRead,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required String title,
                required String body,
                Value<DateTime> sentAt = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
              }) => AppNotificationsCompanion.insert(
                id: id,
                type: type,
                title: title,
                body: body,
                sentAt: sentAt,
                isRead: isRead,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$SpendlerDatabase,
      $AppNotificationsTable,
      AppNotification,
      $$AppNotificationsTableFilterComposer,
      $$AppNotificationsTableOrderingComposer,
      $$AppNotificationsTableAnnotationComposer,
      $$AppNotificationsTableCreateCompanionBuilder,
      $$AppNotificationsTableUpdateCompanionBuilder,
      (
        AppNotification,
        BaseReferences<
          _$SpendlerDatabase,
          $AppNotificationsTable,
          AppNotification
        >,
      ),
      AppNotification,
      PrefetchHooks Function()
    >;
typedef $$FriendContactsTableCreateCompanionBuilder =
    FriendContactsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> note,
      required String avatarColour,
      Value<DateTime> createdAt,
    });
typedef $$FriendContactsTableUpdateCompanionBuilder =
    FriendContactsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> note,
      Value<String> avatarColour,
      Value<DateTime> createdAt,
    });

class $$FriendContactsTableFilterComposer
    extends Composer<_$SpendlerDatabase, $FriendContactsTable> {
  $$FriendContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarColour => $composableBuilder(
    column: $table.avatarColour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FriendContactsTableOrderingComposer
    extends Composer<_$SpendlerDatabase, $FriendContactsTable> {
  $$FriendContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarColour => $composableBuilder(
    column: $table.avatarColour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FriendContactsTableAnnotationComposer
    extends Composer<_$SpendlerDatabase, $FriendContactsTable> {
  $$FriendContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get avatarColour => $composableBuilder(
    column: $table.avatarColour,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FriendContactsTableTableManager
    extends
        RootTableManager<
          _$SpendlerDatabase,
          $FriendContactsTable,
          FriendContact,
          $$FriendContactsTableFilterComposer,
          $$FriendContactsTableOrderingComposer,
          $$FriendContactsTableAnnotationComposer,
          $$FriendContactsTableCreateCompanionBuilder,
          $$FriendContactsTableUpdateCompanionBuilder,
          (
            FriendContact,
            BaseReferences<
              _$SpendlerDatabase,
              $FriendContactsTable,
              FriendContact
            >,
          ),
          FriendContact,
          PrefetchHooks Function()
        > {
  $$FriendContactsTableTableManager(
    _$SpendlerDatabase db,
    $FriendContactsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FriendContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FriendContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FriendContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> avatarColour = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FriendContactsCompanion(
                id: id,
                name: name,
                note: note,
                avatarColour: avatarColour,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> note = const Value.absent(),
                required String avatarColour,
                Value<DateTime> createdAt = const Value.absent(),
              }) => FriendContactsCompanion.insert(
                id: id,
                name: name,
                note: note,
                avatarColour: avatarColour,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FriendContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$SpendlerDatabase,
      $FriendContactsTable,
      FriendContact,
      $$FriendContactsTableFilterComposer,
      $$FriendContactsTableOrderingComposer,
      $$FriendContactsTableAnnotationComposer,
      $$FriendContactsTableCreateCompanionBuilder,
      $$FriendContactsTableUpdateCompanionBuilder,
      (
        FriendContact,
        BaseReferences<_$SpendlerDatabase, $FriendContactsTable, FriendContact>,
      ),
      FriendContact,
      PrefetchHooks Function()
    >;
typedef $$FriendSplitsTableCreateCompanionBuilder =
    FriendSplitsCompanion Function({
      Value<int> id,
      required int transactionId,
      required int friendContactId,
      required double amount,
      required String direction,
      Value<bool> isSettled,
      Value<bool> isWrittenOff,
      Value<DateTime?> settledAt,
      Value<String?> settlementMethod,
      Value<DateTime> createdAt,
    });
typedef $$FriendSplitsTableUpdateCompanionBuilder =
    FriendSplitsCompanion Function({
      Value<int> id,
      Value<int> transactionId,
      Value<int> friendContactId,
      Value<double> amount,
      Value<String> direction,
      Value<bool> isSettled,
      Value<bool> isWrittenOff,
      Value<DateTime?> settledAt,
      Value<String?> settlementMethod,
      Value<DateTime> createdAt,
    });

class $$FriendSplitsTableFilterComposer
    extends Composer<_$SpendlerDatabase, $FriendSplitsTable> {
  $$FriendSplitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get friendContactId => $composableBuilder(
    column: $table.friendContactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWrittenOff => $composableBuilder(
    column: $table.isWrittenOff,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settlementMethod => $composableBuilder(
    column: $table.settlementMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FriendSplitsTableOrderingComposer
    extends Composer<_$SpendlerDatabase, $FriendSplitsTable> {
  $$FriendSplitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get friendContactId => $composableBuilder(
    column: $table.friendContactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWrittenOff => $composableBuilder(
    column: $table.isWrittenOff,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settlementMethod => $composableBuilder(
    column: $table.settlementMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FriendSplitsTableAnnotationComposer
    extends Composer<_$SpendlerDatabase, $FriendSplitsTable> {
  $$FriendSplitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get friendContactId => $composableBuilder(
    column: $table.friendContactId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<bool> get isSettled =>
      $composableBuilder(column: $table.isSettled, builder: (column) => column);

  GeneratedColumn<bool> get isWrittenOff => $composableBuilder(
    column: $table.isWrittenOff,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get settledAt =>
      $composableBuilder(column: $table.settledAt, builder: (column) => column);

  GeneratedColumn<String> get settlementMethod => $composableBuilder(
    column: $table.settlementMethod,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FriendSplitsTableTableManager
    extends
        RootTableManager<
          _$SpendlerDatabase,
          $FriendSplitsTable,
          FriendSplit,
          $$FriendSplitsTableFilterComposer,
          $$FriendSplitsTableOrderingComposer,
          $$FriendSplitsTableAnnotationComposer,
          $$FriendSplitsTableCreateCompanionBuilder,
          $$FriendSplitsTableUpdateCompanionBuilder,
          (
            FriendSplit,
            BaseReferences<_$SpendlerDatabase, $FriendSplitsTable, FriendSplit>,
          ),
          FriendSplit,
          PrefetchHooks Function()
        > {
  $$FriendSplitsTableTableManager(_$SpendlerDatabase db, $FriendSplitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FriendSplitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FriendSplitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FriendSplitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> transactionId = const Value.absent(),
                Value<int> friendContactId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<bool> isSettled = const Value.absent(),
                Value<bool> isWrittenOff = const Value.absent(),
                Value<DateTime?> settledAt = const Value.absent(),
                Value<String?> settlementMethod = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FriendSplitsCompanion(
                id: id,
                transactionId: transactionId,
                friendContactId: friendContactId,
                amount: amount,
                direction: direction,
                isSettled: isSettled,
                isWrittenOff: isWrittenOff,
                settledAt: settledAt,
                settlementMethod: settlementMethod,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int transactionId,
                required int friendContactId,
                required double amount,
                required String direction,
                Value<bool> isSettled = const Value.absent(),
                Value<bool> isWrittenOff = const Value.absent(),
                Value<DateTime?> settledAt = const Value.absent(),
                Value<String?> settlementMethod = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FriendSplitsCompanion.insert(
                id: id,
                transactionId: transactionId,
                friendContactId: friendContactId,
                amount: amount,
                direction: direction,
                isSettled: isSettled,
                isWrittenOff: isWrittenOff,
                settledAt: settledAt,
                settlementMethod: settlementMethod,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FriendSplitsTableProcessedTableManager =
    ProcessedTableManager<
      _$SpendlerDatabase,
      $FriendSplitsTable,
      FriendSplit,
      $$FriendSplitsTableFilterComposer,
      $$FriendSplitsTableOrderingComposer,
      $$FriendSplitsTableAnnotationComposer,
      $$FriendSplitsTableCreateCompanionBuilder,
      $$FriendSplitsTableUpdateCompanionBuilder,
      (
        FriendSplit,
        BaseReferences<_$SpendlerDatabase, $FriendSplitsTable, FriendSplit>,
      ),
      FriendSplit,
      PrefetchHooks Function()
    >;
typedef $$SubscriptionsTableCreateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<int> id,
      required String name,
      required double amount,
      required String billingCycle,
      required DateTime nextBillingDate,
      required String category,
      Value<bool> isActive,
      Value<DateTime> createdAt,
    });
typedef $$SubscriptionsTableUpdateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> amount,
      Value<String> billingCycle,
      Value<DateTime> nextBillingDate,
      Value<String> category,
      Value<bool> isActive,
      Value<DateTime> createdAt,
    });

class $$SubscriptionsTableFilterComposer
    extends Composer<_$SpendlerDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billingCycle => $composableBuilder(
    column: $table.billingCycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextBillingDate => $composableBuilder(
    column: $table.nextBillingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubscriptionsTableOrderingComposer
    extends Composer<_$SpendlerDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billingCycle => $composableBuilder(
    column: $table.billingCycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextBillingDate => $composableBuilder(
    column: $table.nextBillingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubscriptionsTableAnnotationComposer
    extends Composer<_$SpendlerDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get billingCycle => $composableBuilder(
    column: $table.billingCycle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextBillingDate => $composableBuilder(
    column: $table.nextBillingDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SubscriptionsTableTableManager
    extends
        RootTableManager<
          _$SpendlerDatabase,
          $SubscriptionsTable,
          Subscription,
          $$SubscriptionsTableFilterComposer,
          $$SubscriptionsTableOrderingComposer,
          $$SubscriptionsTableAnnotationComposer,
          $$SubscriptionsTableCreateCompanionBuilder,
          $$SubscriptionsTableUpdateCompanionBuilder,
          (
            Subscription,
            BaseReferences<_$SpendlerDatabase, $SubscriptionsTable, Subscription>,
          ),
          Subscription,
          PrefetchHooks Function()
        > {
  $$SubscriptionsTableTableManager(
    _$SpendlerDatabase db,
    $SubscriptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> billingCycle = const Value.absent(),
                Value<DateTime> nextBillingDate = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SubscriptionsCompanion(
                id: id,
                name: name,
                amount: amount,
                billingCycle: billingCycle,
                nextBillingDate: nextBillingDate,
                category: category,
                isActive: isActive,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double amount,
                required String billingCycle,
                required DateTime nextBillingDate,
                required String category,
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SubscriptionsCompanion.insert(
                id: id,
                name: name,
                amount: amount,
                billingCycle: billingCycle,
                nextBillingDate: nextBillingDate,
                category: category,
                isActive: isActive,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SpendlerDatabase,
      $SubscriptionsTable,
      Subscription,
      $$SubscriptionsTableFilterComposer,
      $$SubscriptionsTableOrderingComposer,
      $$SubscriptionsTableAnnotationComposer,
      $$SubscriptionsTableCreateCompanionBuilder,
      $$SubscriptionsTableUpdateCompanionBuilder,
      (
        Subscription,
        BaseReferences<_$SpendlerDatabase, $SubscriptionsTable, Subscription>,
      ),
      Subscription,
      PrefetchHooks Function()
    >;

typedef $$CategoryBudgetsTableCreateCompanionBuilder =
    CategoryBudgetsCompanion Function({
      Value<int> id,
      required String category,
      required double monthlyLimit,
      Value<DateTime> createdAt,
    });
typedef $$CategoryBudgetsTableUpdateCompanionBuilder =
    CategoryBudgetsCompanion Function({
      Value<int> id,
      Value<String> category,
      Value<double> monthlyLimit,
      Value<DateTime> createdAt,
    });

class $$CategoryBudgetsTableFilterComposer
    extends Composer<_$SpendlerDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlyLimit => $composableBuilder(
    column: $table.monthlyLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoryBudgetsTableOrderingComposer
    extends Composer<_$SpendlerDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlyLimit => $composableBuilder(
    column: $table.monthlyLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryBudgetsTableAnnotationComposer
    extends Composer<_$SpendlerDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get monthlyLimit => $composableBuilder(
    column: $table.monthlyLimit,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CategoryBudgetsTableTableManager
    extends
        RootTableManager<
          _$SpendlerDatabase,
          $CategoryBudgetsTable,
          CategoryBudget,
          $$CategoryBudgetsTableFilterComposer,
          $$CategoryBudgetsTableOrderingComposer,
          $$CategoryBudgetsTableAnnotationComposer,
          $$CategoryBudgetsTableCreateCompanionBuilder,
          $$CategoryBudgetsTableUpdateCompanionBuilder,
          (
            CategoryBudget,
            BaseReferences<
              _$SpendlerDatabase,
              $CategoryBudgetsTable,
              CategoryBudget
            >,
          ),
          CategoryBudget,
          PrefetchHooks Function()
        > {
  $$CategoryBudgetsTableTableManager(
    _$SpendlerDatabase db,
    $CategoryBudgetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryBudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryBudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryBudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> monthlyLimit = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CategoryBudgetsCompanion(
                id: id,
                category: category,
                monthlyLimit: monthlyLimit,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String category,
                required double monthlyLimit,
                Value<DateTime> createdAt = const Value.absent(),
              }) => CategoryBudgetsCompanion.insert(
                id: id,
                category: category,
                monthlyLimit: monthlyLimit,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryBudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$SpendlerDatabase,
      $CategoryBudgetsTable,
      CategoryBudget,
      $$CategoryBudgetsTableFilterComposer,
      $$CategoryBudgetsTableOrderingComposer,
      $$CategoryBudgetsTableAnnotationComposer,
      $$CategoryBudgetsTableCreateCompanionBuilder,
      $$CategoryBudgetsTableUpdateCompanionBuilder,
      (
        CategoryBudget,
        BaseReferences<_$SpendlerDatabase, $CategoryBudgetsTable, CategoryBudget>,
      ),
      CategoryBudget,
      PrefetchHooks Function()
    >;
typedef $$SavingsGoalsTableCreateCompanionBuilder =
    SavingsGoalsCompanion Function({
      Value<int> id,
      required String name,
      required double targetAmount,
      Value<double> currentAmount,
      required String iconName,
      Value<DateTime> createdAt,
    });
typedef $$SavingsGoalsTableUpdateCompanionBuilder =
    SavingsGoalsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> targetAmount,
      Value<double> currentAmount,
      Value<String> iconName,
      Value<DateTime> createdAt,
    });

class $$SavingsGoalsTableFilterComposer
    extends Composer<_$SpendlerDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentAmount => $composableBuilder(
    column: $table.currentAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavingsGoalsTableOrderingComposer
    extends Composer<_$SpendlerDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentAmount => $composableBuilder(
    column: $table.currentAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavingsGoalsTableAnnotationComposer
    extends Composer<_$SpendlerDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentAmount => $composableBuilder(
    column: $table.currentAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SavingsGoalsTableTableManager
    extends
        RootTableManager<
          _$SpendlerDatabase,
          $SavingsGoalsTable,
          SavingsGoal,
          $$SavingsGoalsTableFilterComposer,
          $$SavingsGoalsTableOrderingComposer,
          $$SavingsGoalsTableAnnotationComposer,
          $$SavingsGoalsTableCreateCompanionBuilder,
          $$SavingsGoalsTableUpdateCompanionBuilder,
          (
            SavingsGoal,
            BaseReferences<_$SpendlerDatabase, $SavingsGoalsTable, SavingsGoal>,
          ),
          SavingsGoal,
          PrefetchHooks Function()
        > {
  $$SavingsGoalsTableTableManager(_$SpendlerDatabase db, $SavingsGoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> targetAmount = const Value.absent(),
                Value<double> currentAmount = const Value.absent(),
                Value<String> iconName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SavingsGoalsCompanion(
                id: id,
                name: name,
                targetAmount: targetAmount,
                currentAmount: currentAmount,
                iconName: iconName,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double targetAmount,
                Value<double> currentAmount = const Value.absent(),
                required String iconName,
                Value<DateTime> createdAt = const Value.absent(),
              }) => SavingsGoalsCompanion.insert(
                id: id,
                name: name,
                targetAmount: targetAmount,
                currentAmount: currentAmount,
                iconName: iconName,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavingsGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$SpendlerDatabase,
      $SavingsGoalsTable,
      SavingsGoal,
      $$SavingsGoalsTableFilterComposer,
      $$SavingsGoalsTableOrderingComposer,
      $$SavingsGoalsTableAnnotationComposer,
      $$SavingsGoalsTableCreateCompanionBuilder,
      $$SavingsGoalsTableUpdateCompanionBuilder,
      (
        SavingsGoal,
        BaseReferences<_$SpendlerDatabase, $SavingsGoalsTable, SavingsGoal>,
      ),
      SavingsGoal,
      PrefetchHooks Function()
    >;


class $SpendlerDatabaseManager {
  final _$SpendlerDatabase _db;
  $SpendlerDatabaseManager(this._db);
  $$SpendlerTransactionsTableTableManager get spendlerTransactions =>
      $$SpendlerTransactionsTableTableManager(_db, _db.spendlerTransactions);
  $$FamilyEntriesTableTableManager get familyEntries =>
      $$FamilyEntriesTableTableManager(_db, _db.familyEntries);
  $$WeeklyReflectionsTableTableManager get weeklyReflections =>
      $$WeeklyReflectionsTableTableManager(_db, _db.weeklyReflections);
  $$AppMetricsTableTableManager get appMetrics =>
      $$AppMetricsTableTableManager(_db, _db.appMetrics);
  $$AppNotificationsTableTableManager get appNotifications =>
      $$AppNotificationsTableTableManager(_db, _db.appNotifications);
  $$FriendContactsTableTableManager get friendContacts =>
      $$FriendContactsTableTableManager(_db, _db.friendContacts);
  $$FriendSplitsTableTableManager get friendSplits =>
      $$FriendSplitsTableTableManager(_db, _db.friendSplits);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db, _db.subscriptions);
  $$CategoryBudgetsTableTableManager get categoryBudgets =>
      $$CategoryBudgetsTableTableManager(_db, _db.categoryBudgets);
  $$SavingsGoalsTableTableManager get savingsGoals =>
      $$SavingsGoalsTableTableManager(_db, _db.savingsGoals);
}

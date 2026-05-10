import 'package:flutter/material.dart';

enum PaymentFrequency { weekly, monthly, yearly }

enum PaymentHealth { onTrack, atRisk, behind }

class RecurringPaymentModel {
  final String id;
  final String name;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final int amount;
  final PaymentFrequency frequency;
  final int dueDayOfMonth;
  final String accountId;
  final DateTime? lastPaidDate;
  final DateTime createdAt;

  const RecurringPaymentModel({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.amount,
    required this.frequency,
    required this.dueDayOfMonth,
    required this.accountId,
    this.lastPaidDate,
    required this.createdAt,
  });

  PaymentHealth get health {
    final now = DateTime.now();
    final dueThisMonth = DateTime(now.year, now.month, dueDayOfMonth);

    final paidThisCycle = lastPaidDate != null &&
        lastPaidDate!.year == now.year &&
        lastPaidDate!.month == now.month;

    if (paidThisCycle) return PaymentHealth.onTrack;
    if (now.isAfter(dueThisMonth)) return PaymentHealth.behind;
    if (dueThisMonth.difference(now).inDays <= 3) return PaymentHealth.atRisk;
    return PaymentHealth.onTrack;
  }

  String get frequencyLabel {
    switch (frequency) {
      case PaymentFrequency.weekly:
        return '/wk';
      case PaymentFrequency.monthly:
        return '/mo';
      case PaymentFrequency.yearly:
        return '/yr';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryName': categoryName,
        'categoryIconCodePoint': categoryIcon.codePoint,
        'categoryColorValue': categoryColor.toARGB32(),
        'amount': amount,
        'frequency': frequency.name,
        'dueDayOfMonth': dueDayOfMonth,
        'accountId': accountId,
        'lastPaidDate': lastPaidDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory RecurringPaymentModel.fromJson(Map<String, dynamic> json) =>
      RecurringPaymentModel(
        id: json['id'] as String,
        name: json['name'] as String,
        categoryName: json['categoryName'] as String,
        categoryIcon: IconData(json['categoryIconCodePoint'] as int,
            fontFamily: 'MaterialIcons'),
        categoryColor: Color(json['categoryColorValue'] as int),
        amount: json['amount'] as int,
        frequency: PaymentFrequency.values.byName(json['frequency'] as String),
        dueDayOfMonth: json['dueDayOfMonth'] as int,
        accountId: json['accountId'] as String,
        lastPaidDate: json['lastPaidDate'] != null
            ? DateTime.parse(json['lastPaidDate'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

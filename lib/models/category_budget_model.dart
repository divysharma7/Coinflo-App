import 'package:flutter/material.dart';

enum CategoryGroup {
  foodAndDrink,
  transport,
  shopping,
  billsAndUtilities,
  healthAndWellness,
  entertainment,
  personalCare,
  education,
  travel,
  other,
}

extension CategoryGroupExtension on CategoryGroup {
  String get label {
    switch (this) {
      case CategoryGroup.foodAndDrink:
        return 'Food & Drink';
      case CategoryGroup.transport:
        return 'Transport';
      case CategoryGroup.shopping:
        return 'Shopping';
      case CategoryGroup.billsAndUtilities:
        return 'Bills & Utilities';
      case CategoryGroup.healthAndWellness:
        return 'Health & Wellness';
      case CategoryGroup.entertainment:
        return 'Entertainment';
      case CategoryGroup.personalCare:
        return 'Personal Care';
      case CategoryGroup.education:
        return 'Education';
      case CategoryGroup.travel:
        return 'Travel';
      case CategoryGroup.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case CategoryGroup.foodAndDrink:
        return Icons.coffee_outlined;
      case CategoryGroup.transport:
        return Icons.near_me_outlined;
      case CategoryGroup.shopping:
        return Icons.local_offer_outlined;
      case CategoryGroup.billsAndUtilities:
        return Icons.home_outlined;
      case CategoryGroup.healthAndWellness:
        return Icons.monitor_heart_outlined;
      case CategoryGroup.entertainment:
        return Icons.grid_view_outlined;
      case CategoryGroup.personalCare:
        return Icons.content_cut_outlined;
      case CategoryGroup.education:
        return Icons.menu_book_outlined;
      case CategoryGroup.travel:
        return Icons.near_me_outlined;
      case CategoryGroup.other:
        return Icons.more_horiz;
    }
  }

  Color get iconColor {
    switch (this) {
      case CategoryGroup.foodAndDrink:
        return const Color(0xFFEA580C);
      case CategoryGroup.transport:
        return const Color(0xFF3B82F6);
      case CategoryGroup.shopping:
        return const Color(0xFF8B5CF6);
      case CategoryGroup.billsAndUtilities:
        return const Color(0xFFF59E0B);
      case CategoryGroup.healthAndWellness:
        return const Color(0xFF22C55E);
      case CategoryGroup.entertainment:
        return const Color(0xFFEC4899);
      case CategoryGroup.personalCare:
        return const Color(0xFFEC4899);
      case CategoryGroup.education:
        return const Color(0xFF6366F1);
      case CategoryGroup.travel:
        return const Color(0xFF14B8A6);
      case CategoryGroup.other:
        return const Color(0xFF9CA3AF);
    }
  }
}

class CategoryBudgetModel {
  final String id;
  final CategoryGroup group;
  final int monthlyLimit;

  const CategoryBudgetModel({
    required this.id,
    required this.group,
    required this.monthlyLimit,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'group': group.name,
        'monthlyLimit': monthlyLimit,
      };

  factory CategoryBudgetModel.fromJson(Map<String, dynamic> json) =>
      CategoryBudgetModel(
        id: json['id'] as String,
        group: CategoryGroup.values.byName(json['group'] as String),
        monthlyLimit: json['monthlyLimit'] as int,
      );
}

import 'package:flutter/material.dart';

class SmartRuleModel {
  final String id;
  final String keyword;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final DateTime createdAt;

  const SmartRuleModel({
    required this.id,
    required this.keyword,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'keyword': keyword,
        'categoryName': categoryName,
        'categoryIconCodePoint': categoryIcon.codePoint,
        'categoryColorValue': categoryColor.toARGB32(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SmartRuleModel.fromJson(Map<String, dynamic> json) =>
      SmartRuleModel(
        id: json['id'] as String,
        keyword: json['keyword'] as String,
        categoryName: json['categoryName'] as String,
        categoryIcon:
            IconData(json['categoryIconCodePoint'] as int, fontFamily: 'MaterialIcons'),
        categoryColor: Color(json['categoryColorValue'] as int),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

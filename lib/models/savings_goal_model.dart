class SavingsGoalModel {
  final String id;
  final String name;
  final String iconAsset;
  final int targetAmount;
  final int monthlyTarget;
  final DateTime? targetDate;
  final int savedAmount;
  final DateTime createdAt;
  final DateTime? lastContributionDate;

  const SavingsGoalModel({
    required this.id,
    required this.name,
    required this.iconAsset,
    required this.targetAmount,
    required this.monthlyTarget,
    this.targetDate,
    this.savedAmount = 0,
    required this.createdAt,
    this.lastContributionDate,
  });

  GoalHealth get health {
    if (savedAmount >= targetAmount) return GoalHealth.completed;

    final now = DateTime.now();
    final dayOfMonth = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final monthProgress = dayOfMonth / daysInMonth;

    final contributedThisMonth = lastContributionDate != null &&
        lastContributionDate!.year == now.year &&
        lastContributionDate!.month == now.month;

    if (contributedThisMonth) return GoalHealth.onTrack;
    if (monthProgress >= 0.5) return GoalHealth.atRisk;
    return GoalHealth.behind;
  }

  int get monthsRemaining {
    final remaining = targetAmount - savedAmount;
    if (monthlyTarget <= 0) return 0;
    return (remaining / monthlyTarget).ceil();
  }

  double get progress => (savedAmount / targetAmount).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconAsset': iconAsset,
        'targetAmount': targetAmount,
        'monthlyTarget': monthlyTarget,
        'targetDate': targetDate?.toIso8601String(),
        'savedAmount': savedAmount,
        'createdAt': createdAt.toIso8601String(),
        'lastContributionDate': lastContributionDate?.toIso8601String(),
      };

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) =>
      SavingsGoalModel(
        id: json['id'] as String,
        name: json['name'] as String,
        iconAsset: json['iconAsset'] as String,
        targetAmount: json['targetAmount'] as int,
        monthlyTarget: json['monthlyTarget'] as int,
        targetDate: json['targetDate'] != null
            ? DateTime.parse(json['targetDate'] as String)
            : null,
        savedAmount: (json['savedAmount'] as int?) ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastContributionDate: json['lastContributionDate'] != null
            ? DateTime.parse(json['lastContributionDate'] as String)
            : null,
      );
}

enum GoalHealth { onTrack, atRisk, behind, completed }

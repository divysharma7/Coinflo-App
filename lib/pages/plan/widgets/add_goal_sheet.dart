import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';

class AddGoalSheet extends ConsumerStatefulWidget {
  const AddGoalSheet({super.key, this.existingGoal});
  final SavingsGoal? existingGoal;

  @override
  ConsumerState<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<AddGoalSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedIcon = 'piggyBank';
  bool get _isEditing => widget.existingGoal != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingGoal;
    if (existing != null) {
      _nameCtrl.text = existing.name;
      _amountCtrl.text = existing.targetAmount.toStringAsFixed(0);
      _selectedIcon = existing.iconName;
    }
  }

  static const _iconOptions = [
    ('piggyBank', 'Savings'),
    ('airplane', 'Travel'),
    ('car', 'Car'),
    ('house', 'Home'),
    ('graduationCap', 'Education'),
    ('heartbeat', 'Health'),
    ('laptop', 'Tech'),
    ('gift', 'Gift'),
  ];

  IconData _resolveIcon(String name) {
    switch (name) {
      case 'airplane':
        return PhosphorIcons.airplane();
      case 'car':
        return PhosphorIcons.car();
      case 'house':
        return PhosphorIcons.house();
      case 'graduationCap':
        return PhosphorIcons.graduationCap();
      case 'heartbeat':
        return PhosphorIcons.heartbeat();
      case 'laptop':
        return PhosphorIcons.laptop();
      case 'gift':
        return PhosphorIcons.gift();
      case 'piggyBank':
        return PhosphorIcons.piggyBank();
      default:
        return PhosphorIcons.star();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing ? 'Edit Goal' : 'New Goal',
            style: AppTextStyles.headingM.copyWith(
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Icon picker
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _iconOptions.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (_, i) {
                final (iconName, label) = _iconOptions[i];
                final isSelected = iconName == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconName),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.black.withValues(alpha: 0.15)
                              : AppColors.gray200,
                          borderRadius: AppRadius.sm,
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.black, width: 1.5)
                              : null,
                        ),
                        child: Center(
                          child: PhosphorIcon(
                            _resolveIcon(iconName),
                            size: 20,
                            color: isSelected
                                ? AppColors.black
                                : AppColors.gray500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: AppTextStyles.labelS.copyWith(
                          fontSize: 9,
                          color: isSelected
                              ? AppColors.black
                              : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Name field
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Goal name',
              labelStyle: TextStyle(color: AppColors.gray500),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.sm,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.sm,
                borderSide: BorderSide(color: AppColors.black, width: 1.5),
              ),
            ),
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Target amount field
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              labelText: 'Target amount (₹)',
              labelStyle: TextStyle(color: AppColors.gray500),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.sm,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.sm,
                borderSide: BorderSide(color: AppColors.black, width: 1.5),
              ),
            ),
            style: AppTextStyles.headingS.copyWith(
              color: AppColors.black,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: _isEditing ? 'Update Goal' : 'Create Goal',
            onTap: _save,
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final target = double.tryParse(_amountCtrl.text.trim());
    if (name.isEmpty || target == null || target <= 0) return;

    if (_isEditing) {
      await updateGoal(
        ref.read(repositoryProvider),
        id: widget.existingGoal!.id,
        name: name,
        targetAmount: target,
        iconName: _selectedIcon,
      );
    } else {
      await insertGoal(
        ref.read(repositoryProvider),
        name: name,
        targetAmount: target,
        iconName: _selectedIcon,
      );
    }
    invalidateAnalytics(ref);

    if (mounted) Navigator.pop(context);
  }
}

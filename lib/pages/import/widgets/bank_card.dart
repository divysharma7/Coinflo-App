import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

class BankCard extends StatelessWidget {
  const BankCard({
    super.key,
    required this.bankType,
    required this.isSelected,
    this.isDisabled = false,
    this.onTap,
  });

  final BankType bankType;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  static const Map<BankType, Color> _bankColors = {
    BankType.hdfc: Color(0xFF004C8F),
    BankType.icici: Color(0xFFF37021),
    BankType.sbi: Color(0xFF2B5BA5),
    BankType.axis: Color(0xFF800020),
    BankType.kotak: Color(0xFFED1C24),
    BankType.unknown: Color(0xFF6E6E6E),
  };

  @override
  Widget build(BuildContext context) {
    final bankColor = _bankColors[bankType] ?? AppColors.gray500;

    Widget card = GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.xl,
          border: isSelected
              ? Border.all(color: AppColors.black, width: 2)
              : Border.all(color: AppColors.gray200, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.bank(),
              size: 28,
              color: bankColor,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              bankType.shortLabel,
              style: AppTextStyles.bodyL.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    if (isDisabled) {
      card = IgnorePointer(
        child: Opacity(
          opacity: 0.5,
          child: card,
        ),
      );
    }

    return card;
  }
}

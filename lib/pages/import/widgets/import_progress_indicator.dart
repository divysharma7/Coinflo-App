import 'package:flutter/material.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';

class ImportProgressIndicator extends StatelessWidget {
  const ImportProgressIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        return Container(
          width: 24,
          height: 3,
          margin: EdgeInsets.only(
            right: index < totalSteps - 1 ? AppSpacing.xs : 0,
          ),
          decoration: BoxDecoration(
            color: index < currentStep ? AppColors.black : AppColors.gray200,
            borderRadius: AppRadius.full,
          ),
        );
      }),
    );
  }
}

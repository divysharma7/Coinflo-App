import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';

import 'package:finance_buddy_app/pages/report/widgets/report_scope.dart';

// ---------------------------------------------------------------------------
// Period Selector
// ---------------------------------------------------------------------------

class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reportScopeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: AppRadius.xxl,
        ),
        child: Row(
          children: ReportScope.values.map((scope) {
            final isSel = scope == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(reportScopeProvider.notifier).state = scope;
                },
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.black : Colors.transparent,
                    borderRadius: AppRadius.xlSm,
                  ),
                  child: Center(
                    child: Text(
                      scope.name[0].toUpperCase() + scope.name.substring(1),
                      style: AppTextStyles.bodyS.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSel ? AppColors.white : AppColors.gray500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

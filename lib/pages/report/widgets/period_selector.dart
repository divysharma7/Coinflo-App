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
    final segments = ReportScope.values
        .map((s) => s.name[0].toUpperCase() + s.name.substring(1))
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppSegmentedControl(
        segments: segments,
        selectedIndex: ReportScope.values.indexOf(selected),
        onChanged: (i) {
          HapticFeedback.selectionClick();
          ref.read(reportScopeProvider.notifier).state =
              ReportScope.values[i];
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

/// Shows a consistent Spendler bottom sheet with drag handle, dark surface,
/// and correct animation timing.
///
/// Use this for ALL short interactions: mark-as-split, pick-category,
/// add-family-entry, confirm-settlement, quick-add.
Future<T?> showSpendlerSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.md,
        ),
        child: builder(ctx),
      );
    },
  );
}

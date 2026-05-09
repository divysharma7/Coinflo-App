import 'package:flutter/material.dart';
import 'package:finance_buddy_app/core/tokens.dart';

/// Shows a consistent Pulse bottom sheet with drag handle, dark surface,
/// and correct animation timing.
///
/// Use this for ALL short interactions: mark-as-split, pick-category,
/// add-family-entry, confirm-settlement, quick-add.
Future<T?> showPaisaSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    backgroundColor: PaisaColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(PaisaRadii.sheet),
      ),
    ),
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: PaisaSpacing.screenH,
          right: PaisaSpacing.screenH,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + PaisaSpacing.md,
        ),
        child: builder(ctx),
      );
    },
  );
}

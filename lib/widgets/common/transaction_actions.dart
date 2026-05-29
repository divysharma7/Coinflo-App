import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

/// Long-press action sheet for any transaction tile. Shows identity confirmation
/// (merchant, amount, date) then Edit and Delete options.
void showTransactionActions(
  BuildContext context,
  WidgetRef ref,
  SpendlerTransaction t,
  String sym,
) {
  HapticFeedback.mediumImpact();
  final cat = TransactionCategory.values.firstWhere(
    (c) => c.name == t.category,
    orElse: () => TransactionCategory.foodAndDrink,
  );
  showSpendlerSheet<void>(
    context: context,
    isScrollControlled: false,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                Text(t.merchant ?? cat.label, style: AppTextStyles.headingS),
                const SizedBox(height: 2),
                Text(
                  '$sym${t.amount.abs().toStringAsFixed(0)}  ·  ${DateFormat('d MMM').format(t.happenedAt)}',
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500),
                ),
              ],
            ),
          ),
          ListTile(
            leading: PhosphorIcon(PhosphorIcons.pencilSimple(),
                color: AppColors.black),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/transaction/${t.id}',
                  extra: const {'startInEditMode': true});
            },
          ),
          ListTile(
            leading:
                PhosphorIcon(PhosphorIcons.trash(), color: AppColors.red),
            title: Text('Delete', style: TextStyle(color: AppColors.red)),
            onTap: () {
              Navigator.pop(ctx);
              confirmDeleteTransaction(context, ref, t);
            },
          ),
        ],
      ),
    ),
  );
}

/// Confirmation dialog for deleting a transaction.
Future<void> confirmDeleteTransaction(
  BuildContext context,
  WidgetRef ref,
  SpendlerTransaction t,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete this transaction?'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    final repo = ref.read(repositoryProvider);
    await repo.deleteTransaction(t.id);
  }
}

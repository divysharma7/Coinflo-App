import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/pages/import/widgets/import_history_tile.dart';
import 'package:finance_buddy_app/providers/import_history_provider.dart';
import 'package:finance_buddy_app/providers/import_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ImportHistoryPage extends ConsumerWidget {
  const ImportHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(importHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              AppBackButton(onTap: () => context.pop()),
              const SizedBox(height: AppSpacing.lg),
              const Text('Import history', style: AppTextStyles.headingL),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: historyAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (batches) {
                    if (batches.isEmpty) return _buildEmpty(context, ref);
                    return ListView.separated(
                      itemCount: batches.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final batch = batches[index];
                        return ImportHistoryTile(
                          bankName: batch.bankName,
                          fileName: batch.fileName,
                          importedAt: batch.importedAt,
                          transactionCount: batch.transactionCount,
                          uncategorizedCount: batch.uncategorizedCount,
                          status: batch.status,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.fileArrowUp(), size: 48, color: AppColors.gray400),
          const SizedBox(height: AppSpacing.md),
          const Text('No imports yet', style: AppTextStyles.bodyL),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Import a statement',
            onTap: () {
              ref.read(importFlowControllerProvider.notifier).setSource(ImportSource.importHistory);
              context.push('/import');
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/pages/import/widgets/category_picker_sheet.dart';
import 'package:finance_buddy_app/pages/import/widgets/import_progress_indicator.dart';
import 'package:finance_buddy_app/pages/import/widgets/uncategorized_txn_tile.dart';
import 'package:finance_buddy_app/providers/import_provider.dart';

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _listFade;
  int _reviewed = 0;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: AppDurations.entrance,
    );
    _listFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _onPickCategory(int index) async {
    final state = ref.read(importFlowControllerProvider);
    if (index >= state.uncategorized.length) return;

    final txn = state.uncategorized[index];
    final category = await showCategoryPicker(context);
    if (category == null || !mounted) return;

    final controller = ref.read(importFlowControllerProvider.notifier);
    final dbId = txn.dbId ?? 0;
    await controller.correctCategory(dbId, txn.merchantToken, category);

    setState(() => _reviewed++);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied to ${txn.merchantToken} transactions'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onDone() {
    ref.read(importFlowControllerProvider.notifier).finishReview();
    context.go('/import/summary');
  }

  Future<bool> _onBack() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip review?'),
        content: const Text('Uncategorized transactions stay uncategorized.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Skip')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(importFlowControllerProvider.notifier).finishReview();
      context.go('/import/summary');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importFlowControllerProvider);
    final total = state.uncategorized.length + _reviewed;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              const ImportProgressIndicator(currentStep: 4),
              const SizedBox(height: AppSpacing.md),
              AppBackButton(onTap: _onBack),
              const SizedBox(height: AppSpacing.xl),
              const Text('Help us learn', style: AppTextStyles.headingL),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${state.uncategorized.length} transactions need a category',
                style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  '$_reviewed of $total reviewed',
                  style: AppTextStyles.labelM,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: FadeTransition(
                  opacity: _listFade,
                  child: ListView.separated(
                    itemCount: state.uncategorized.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final txn = state.uncategorized[index];
                      return UncategorizedTxnTile(
                        merchantToken: txn.merchantToken,
                        amount: txn.amount,
                        date: txn.date,
                        onPickCategory: () => _onPickCategory(index),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(label: 'Done', onTap: _onDone),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

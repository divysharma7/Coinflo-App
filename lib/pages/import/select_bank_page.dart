import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/pages/import/widgets/bank_card.dart';
import 'package:finance_buddy_app/pages/import/widgets/import_progress_indicator.dart';
import 'package:finance_buddy_app/providers/import_provider.dart';

class SelectBankPage extends ConsumerStatefulWidget {
  const SelectBankPage({super.key});

  @override
  ConsumerState<SelectBankPage> createState() => _SelectBankPageState();
}

class _SelectBankPageState extends ConsumerState<SelectBankPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _gridFade;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: AppDurations.entrance,
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _enterController, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _gridFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  void _onBankSelected(BankType bank) {
    ref.read(importFlowControllerProvider.notifier).selectBank(bank);
    context.push('/import/upload');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importFlowControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              const ImportProgressIndicator(currentStep: 1),
              const SizedBox(height: AppSpacing.md),
              AppBackButton(onTap: () => context.pop()),
              const SizedBox(height: AppSpacing.xl),
              SlideTransition(
                position: _titleSlide,
                child: FadeTransition(
                  opacity: _titleFade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Which bank's statement?", style: AppTextStyles.headingL),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        "We'll auto-detect from your file too",
                        style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: FadeTransition(
                  opacity: _gridFade,
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.4,
                    children: [
                      for (final bank in BankType.values)
                        BankCard(
                          bankType: bank,
                          isSelected: state.selectedBank == bank,
                          isDisabled: bank == BankType.unknown,
                          onTap: bank == BankType.unknown ? null : () => _onBankSelected(bank),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

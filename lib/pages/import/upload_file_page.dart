import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/pages/import/widgets/bank_instructions_sheet.dart';
import 'package:finance_buddy_app/pages/import/widgets/import_progress_indicator.dart';
import 'package:finance_buddy_app/providers/import_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UploadFilePage extends ConsumerStatefulWidget {
  const UploadFilePage({super.key});

  @override
  ConsumerState<UploadFilePage> createState() => _UploadFilePageState();
}

class _UploadFilePageState extends ConsumerState<UploadFilePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: AppDurations.entrance,
    );
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'pdf'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.first.path!);
    final sizeBytes = await file.length();

    if (sizeBytes > 20 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large. Max 20 MB.')),
        );
      }
      return;
    }

    ref.read(importFlowControllerProvider.notifier).selectFile(file);
  }

  Future<void> _startImport() async {
    unawaited(ref.read(importFlowControllerProvider.notifier).startImport());
    if (mounted) unawaited(context.push('/import/processing'));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importFlowControllerProvider);
    final hasFile = state.selectedFile != null;
    final bankLabel = state.selectedBank?.label ?? 'your bank';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              const ImportProgressIndicator(currentStep: 2),
              const SizedBox(height: AppSpacing.md),
              AppBackButton(onTap: () => context.pop()),
              const SizedBox(height: AppSpacing.xl),
              FadeTransition(
                opacity: _contentFade,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Upload your statement', style: AppTextStyles.headingL),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'CSV file from $bankLabel',
                      style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: FadeTransition(
                  opacity: _contentFade,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: hasFile ? AppColors.black : AppColors.gray300,
                              width: hasFile ? 2 : 1.5,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                            borderRadius: AppRadius.xl,
                            color: AppColors.white,
                          ),
                          child: hasFile
                              ? _buildFileSelected(state.selectedFile!)
                              : _buildFileEmpty(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GestureDetector(
                        onTap: () {
                          if (state.selectedBank != null) {
                            showBankInstructions(context, state.selectedBank!);
                          }
                        },
                        child: Text(
                          'How to download from $bankLabel?',
                          style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.gray500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text(
                            state.error!,
                            style: AppTextStyles.bodyS.copyWith(color: AppColors.red),
                          ),
                        ),
                      AppButton(
                        label: 'Import',
                        onTap: hasFile ? () => _startImport() : () {},
                        disabled: !hasFile,
                      ),
                      const SizedBox(height: AppSpacing.xl),
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

  Widget _buildFileEmpty() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(PhosphorIcons.cloudArrowUp(), size: 40, color: AppColors.gray400),
        const SizedBox(height: AppSpacing.sm),
        const Text('Tap to choose file', style: AppTextStyles.bodyL),
        const SizedBox(height: AppSpacing.xxs),
        Text('.csv or .pdf files', style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500)),
      ],
    );
  }

  Widget _buildFileSelected(File file) {
    final name = file.uri.pathSegments.last;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(PhosphorIcons.file(), size: 36, color: AppColors.black),
        const SizedBox(height: AppSpacing.sm),
        Text(name, style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xxs),
        Text('Tap to change', style: AppTextStyles.bodyS.copyWith(color: AppColors.gray500)),
      ],
    );
  }
}

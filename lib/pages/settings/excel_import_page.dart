import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/services/excel_import_service.dart';

class ExcelImportPage extends ConsumerStatefulWidget {
  const ExcelImportPage({super.key});

  @override
  ConsumerState<ExcelImportPage> createState() => _ExcelImportPageState();
}

class _ExcelImportPageState extends ConsumerState<ExcelImportPage> {
  final _service = ExcelImportService();

  ExcelParseResult? _result;
  String? _fileName;
  bool _importing = false;
  int? _importedCount;

  // ─── Pick file ─────────────────────────────────────────

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (picked == null || picked.files.single.path == null) return;

    final file = File(picked.files.single.path!);
    final result = _service.parseFile(file);

    if (!mounted) return;
    setState(() {
      _fileName = picked.files.single.name;
      _result = result;
      _importedCount = null;
    });
  }

  // ─── Import ────────────────────────────────────────────

  Future<void> _confirmImport() async {
    if (_result == null || _result!.rows.isEmpty) return;
    setState(() => _importing = true);

    final repo = ref.read(repositoryProvider);
    final count = await _service.bulkInsert(_result!.rows, repo);

    if (!mounted) return;
    setState(() {
      _importing = false;
      _importedCount = count;
    });
  }

  // ─── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 24, AppSpacing.lg, 0),
                  child: Row(
                    children: [
                      const AppBackButton(),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Import from Excel',
                          style: AppTextStyles.headingL
                              .copyWith(color: AppColors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    children: [
                      // Pick file card
                      GestureDetector(
                        onTap: _importing ? null : _pickFile,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            borderRadius: AppRadius.xl,
                            boxShadow: AppShadows.sm,
                          ),
                          child: Column(
                            children: [
                              PhosphorIcon(PhosphorIcons.fileXls(),
                                  size: 40, color: AppColors.gray500),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _fileName ?? 'Tap to select .xlsx file',
                                style: AppTextStyles.bodyM.copyWith(
                                    color: _fileName != null
                                        ? AppColors.black
                                        : AppColors.gray500),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Expected columns: Date | Amount | Type | Category | Source | Note',
                                style: AppTextStyles.labelS
                                    .copyWith(color: AppColors.gray500),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Success summary
                      if (_importedCount != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.1),
                            borderRadius: AppRadius.xl,
                          ),
                          child: Row(
                            children: [
                              PhosphorIcon(PhosphorIcons.checkCircle(),
                                  color: AppColors.green, size: 22),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  '$_importedCount transactions imported successfully.',
                                  style: AppTextStyles.bodyM
                                      .copyWith(color: AppColors.green),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Validation errors
                      if (_result != null && _result!.errors.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text('Errors',
                            style: AppTextStyles.labelM
                                .copyWith(color: AppColors.red)),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            borderRadius: AppRadius.xl,
                          ),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _result!.errors.map((e) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xs),
                                child: Text(
                                  'Row ${e.row}: ${e.message}',
                                  style: AppTextStyles.bodyS
                                      .copyWith(color: AppColors.red),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      // Preview table
                      if (_result != null &&
                          _result!.rows.isNotEmpty &&
                          _importedCount == null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          '${_result!.rows.length} rows ready to import',
                          style: AppTextStyles.labelM
                              .copyWith(color: AppColors.gray500),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            borderRadius: AppRadius.xl,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor:
                                  WidgetStateProperty.all(AppColors.gray100),
                              dataRowMinHeight: 40,
                              dataRowMaxHeight: 48,
                              columnSpacing: 16,
                              columns: const [
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Amount')),
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Category')),
                                DataColumn(label: Text('Source')),
                                DataColumn(label: Text('Note')),
                              ],
                              rows: _result!.rows.take(50).map((r) {
                                return DataRow(cells: [
                                  DataCell(Text(
                                      DateFormat('dd/MM/yyyy').format(r.date),
                                      style: AppTextStyles.bodyS)),
                                  DataCell(Text(r.amount.toStringAsFixed(2),
                                      style: AppTextStyles.bodyS)),
                                  DataCell(Text(r.type,
                                      style: AppTextStyles.bodyS)),
                                  DataCell(Text(r.category,
                                      style: AppTextStyles.bodyS)),
                                  DataCell(Text(r.source ?? '',
                                      style: AppTextStyles.bodyS)),
                                  DataCell(Text(r.note ?? '',
                                      style: AppTextStyles.bodyS)),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                        if (_result!.rows.length > 50)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              'Showing first 50 of ${_result!.rows.length} rows',
                              style: AppTextStyles.labelS
                                  .copyWith(color: AppColors.gray500),
                            ),
                          ),

                        // Confirm button
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: _importing
                                ? 'Importing...'
                                : 'Confirm Import',
                            onTap: () => _confirmImport(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

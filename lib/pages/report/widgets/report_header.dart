import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/providers.dart';
import 'package:finance_buddy_app/services/export/csv_exporter.dart';

import 'package:finance_buddy_app/pages/report/widgets/report_scope.dart';

// ─── Header with Export ─────────────────────────────────

class ReportHeader extends ConsumerStatefulWidget {
  const ReportHeader({super.key});

  @override
  ConsumerState<ReportHeader> createState() => _ReportHeaderState();
}

class _ReportHeaderState extends ConsumerState<ReportHeader> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Report',
              style: AppTextStyles.headingL.copyWith(color: AppColors.black)),
          GestureDetector(
            onTap: () => _showExportConfirmation(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.base,
              ),
              child: Icon(PhosphorIcons.export(), color: AppColors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportConfirmation() {
    final month = ref.read(reportMonthProvider);
    final label = DateFormat('MMMM yyyy').format(month);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('Export Report',
            style: AppTextStyles.headingS.copyWith(color: AppColors.black)),
        content: Text(
          'Export your $label spending report as CSV? This will include every transaction with date, merchant, category, amount, note, and type.',
          style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.bodyM.copyWith(color: AppColors.gray500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _exportCsv(month, label);
            },
            child: Text('Export',
                style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.black, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(DateTime month, String label) async {
    try {
      final repo = ref.read(repositoryProvider);
      final transactions = await repo.getTransactionsForMonth(month);
      if (transactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nothing to export this month.')),
          );
        }
        return;
      }
      await CsvExporter.exportAndShare(transactions, label);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

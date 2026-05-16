import 'package:flutter/material.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

void showBankInstructions(BuildContext context, BankType bank) {
  showSpendlerSheet<void>(
    context: context,
    builder: (ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Download statement from ${bank.label}',
            style: AppTextStyles.headingS,
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._instructionsFor(bank).asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${entry.key + 1}.',
                      style: AppTextStyles.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: AppTextStyles.bodyM.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Got it',
            onTap: () => Navigator.pop(ctx),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      );
    },
  );
}

List<String> _instructionsFor(BankType bank) {
  switch (bank) {
    case BankType.hdfc:
      return [
        'Log in to HDFC NetBanking or the HDFC Mobile App.',
        'Go to Accounts > Statement of Account > Select date range (last 6 months).',
        'Choose "Download as CSV" and save the file.',
        'Upload the downloaded CSV file here.',
      ];
    case BankType.icici:
      return [
        'Log in to ICICI Internet Banking or iMobile Pay.',
        'Navigate to Accounts & Deposits > Account Statement.',
        'Select date range, choose CSV format, and download.',
        'Upload the downloaded CSV file here.',
      ];
    case BankType.sbi:
      return [
        'Log in to SBI Online or YONO App.',
        'Go to My Accounts > Account Statement.',
        'Select the date range and download as CSV/Excel.',
        'Upload the downloaded file here.',
      ];
    case BankType.axis:
      return [
        'Log in to Axis Internet Banking or Axis Mobile App.',
        'Navigate to My Accounts > Statement Download.',
        'Select date range, format as CSV, and download.',
        'Upload the downloaded CSV file here.',
      ];
    case BankType.kotak:
      return [
        'Log in to Kotak NetBanking or Kotak Mobile Banking.',
        'Go to Bank Accounts > View Statement.',
        'Select date range and download in CSV format.',
        'Upload the downloaded CSV file here.',
      ];
    case BankType.unknown:
      return [
        'Log in to your bank\'s internet banking or mobile app.',
        'Navigate to Account Statement or Transaction History.',
        'Download the statement as a CSV file for the last 6 months.',
        'Upload the downloaded CSV file here.',
      ];
  }
}

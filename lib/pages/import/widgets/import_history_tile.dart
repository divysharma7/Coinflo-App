import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';

class ImportHistoryTile extends StatelessWidget {
  const ImportHistoryTile({
    super.key,
    required this.bankName,
    required this.fileName,
    required this.importedAt,
    required this.transactionCount,
    required this.uncategorizedCount,
    required this.status,
    this.onTap,
  });

  final String bankName;
  final String fileName;
  final DateTime importedAt;
  final int transactionCount;
  final int uncategorizedCount;
  final String status;
  final VoidCallback? onTap;

  Color get _statusColor {
    switch (status) {
      case 'completed':
        return AppColors.green;
      case 'pendingReview':
        return AppColors.orange;
      case 'failed':
        return AppColors.red;
      default:
        return AppColors.gray400;
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(importedAt);
    if (diff.inDays > 365) {
      final years = (diff.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} ${diff.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        child: Row(
          children: [
            // Bank icon
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.sm,
              ),
              child: const Icon(
                PhosphorIconsRegular.bank,
                size: 20,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        bankName,
                        style: AppTextStyles.bodyM.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Status indicator dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fileName,
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.gray500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_timeAgo \u2022 $transactionCount txns${uncategorizedCount > 0 ? ' \u2022 $uncategorizedCount uncategorized' : ''}',
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron
            Icon(
              PhosphorIcons.caretRight(),
              size: 18,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}

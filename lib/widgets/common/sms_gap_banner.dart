import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';

/// Dismissible banner that educates users about the SBI low-value SMS gap.
/// Shows when auto-captured transactions are lower than expected.
class SmsGapBanner extends StatefulWidget {
  final VoidCallback onAddTap;

  const SmsGapBanner({super.key, required this.onAddTap});

  @override
  State<SmsGapBanner> createState() => _SmsGapBannerState();
}

class _SmsGapBannerState extends State<SmsGapBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpendlerSpacing.screenH,
        vertical: SpendlerSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(SpendlerSpacing.cardPadding),
        decoration: BoxDecoration(
          color: SpendlerColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(SpendlerRadii.button),
          border: Border.all(color: SpendlerColors.warning.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhosphorIcon(
                  PhosphorIcons.info(),
                  color: SpendlerColors.warning,
                  size: 18,
                ),
                const SizedBox(width: SpendlerSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Some small transactions won\'t appear via SMS.',
                        style: TextStyle(
                          color: SpendlerColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Under \$500? Add it manually — takes 3 taps.',
                        style: TextStyle(
                          color: SpendlerColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: SpendlerSpacing.sm),
                      GestureDetector(
                        onTap: widget.onAddTap,
                        child: const Text(
                          'Add now →',
                          style: TextStyle(
                            color: SpendlerColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _dismissed = true),
                  child: PhosphorIcon(
                    PhosphorIcons.x(),
                    color: SpendlerColors.textTertiary,
                    size: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

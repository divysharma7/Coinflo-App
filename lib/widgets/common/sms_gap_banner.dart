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
        horizontal: PaisaSpacing.screenH,
        vertical: PaisaSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(PaisaSpacing.cardPadding),
        decoration: BoxDecoration(
          color: PaisaColors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(PaisaRadii.button),
          border: Border.all(color: PaisaColors.amber.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhosphorIcon(
                  PhosphorIcons.info(),
                  color: PaisaColors.amber,
                  size: 18,
                ),
                const SizedBox(width: PaisaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Some small transactions won\'t appear via SMS.',
                        style: TextStyle(
                          color: PaisaColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Under ₹500? Add it manually — takes 3 taps.',
                        style: TextStyle(
                          color: PaisaColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: PaisaSpacing.sm),
                      GestureDetector(
                        onTap: widget.onAddTap,
                        child: const Text(
                          'Add now →',
                          style: TextStyle(
                            color: PaisaColors.yellow,
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
                    color: PaisaColors.textTertiary,
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

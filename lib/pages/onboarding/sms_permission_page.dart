import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/widgets/common/neo_pop_button.dart';

/// Full-screen rationale page shown before requesting SMS permission.
/// Handles: granted, denied, permanently denied, and Samsung edge cases.
class SmsPermissionPage extends StatefulWidget {
  final VoidCallback onComplete;

  const SmsPermissionPage({super.key, required this.onComplete});

  @override
  State<SmsPermissionPage> createState() => _SmsPermissionPageState();
}

class _SmsPermissionPageState extends State<SmsPermissionPage> {
  bool _requesting = false;

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);

    final status = await Permission.sms.request();

    if (!mounted) return;
    setState(() => _requesting = false);

    if (status.isGranted) {
      widget.onComplete();
      return;
    }

    if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedSheet();
      return;
    }

    // Denied once — show a gentle nudge
    _showDeniedOnceSheet();
  }

  void _showDeniedOnceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: SpendlerColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SpendlerRadii.sheet)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(SpendlerSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SMS access is needed',
              style: SpendlerTextStyles.onboardingHeadline,
            ),
            const SizedBox(height: SpendlerSpacing.sm),
            const Text(
              'Without it, transactions won\'t be captured automatically. '
              'You can still add them manually.',
              style: SpendlerTextStyles.onboardingBody,
            ),
            const SizedBox(height: SpendlerSpacing.lg),
            NeoPOPButton(
              label: 'Try Again',
              onTap: () {
                Navigator.pop(context);
                _requestPermission();
              },
            ),
            const SizedBox(height: SpendlerSpacing.md),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onComplete(); // proceed without SMS
                },
                child: const Text(
                  'Continue without SMS',
                  style: TextStyle(color: SpendlerColors.textSecondary, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: SpendlerSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showPermanentlyDeniedSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: SpendlerColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SpendlerRadii.sheet)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(SpendlerSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SMS access was blocked',
              style: SpendlerTextStyles.onboardingHeadline,
            ),
            const SizedBox(height: SpendlerSpacing.sm),
            const Text(
              'You\'ll need to enable it manually in Settings.',
              style: SpendlerTextStyles.onboardingBody,
            ),
            const SizedBox(height: SpendlerSpacing.md),
            // Step-by-step instructions.
            // These steps are intentionally generic so they work across all
            // Android OEMs including Samsung (One UI), Xiaomi (MIUI), etc.
            // Samsung path: Settings → Apps → Pulse → Permissions → SMS → Allow
            // which matches the wording below.
            Container(
              padding: const EdgeInsets.all(SpendlerSpacing.cardPadding),
              decoration: BoxDecoration(
                color: SpendlerColors.surface,
                borderRadius: BorderRadius.circular(SpendlerRadii.button),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Open Settings', style: TextStyle(color: SpendlerColors.textPrimary, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('2. Apps → Pulse → Permissions', style: TextStyle(color: SpendlerColors.textPrimary, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('3. SMS → Allow', style: TextStyle(color: SpendlerColors.textPrimary, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: SpendlerSpacing.lg),
            NeoPOPButton(
              label: 'Open Settings',
              onTap: () {
                openAppSettings();
              },
            ),
            const SizedBox(height: SpendlerSpacing.md),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onComplete();
                },
                child: const Text(
                  'Continue without SMS',
                  style: TextStyle(color: SpendlerColors.textSecondary, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: SpendlerSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpendlerColors.scaffold,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
          padding: const EdgeInsets.all(SpendlerSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // What we read
              PhosphorIcon(PhosphorIcons.shieldCheck(), color: SpendlerColors.primary, size: 48),
              const SizedBox(height: SpendlerSpacing.lg),
              const Text(
                'What Pulse reads\nfrom your SMS',
                style: SpendlerTextStyles.onboardingHeadline,
              ),
              const SizedBox(height: SpendlerSpacing.lg),

              _BulletRow(
                icon: PhosphorIcons.check(),
                color: SpendlerColors.income,
                text: 'SBI bank transaction alerts',
              ),
              const SizedBox(height: SpendlerSpacing.cardGap),
              _BulletRow(
                icon: PhosphorIcons.check(),
                color: SpendlerColors.income,
                text: 'UPI payment confirmations',
              ),
              const SizedBox(height: SpendlerSpacing.lg),
              _BulletRow(
                icon: PhosphorIcons.x(),
                color: SpendlerColors.expense,
                text: 'Personal messages — never read',
              ),
              const SizedBox(height: SpendlerSpacing.cardGap),
              _BulletRow(
                icon: PhosphorIcons.x(),
                color: SpendlerColors.expense,
                text: 'OTPs — ignored completely',
              ),
              const SizedBox(height: SpendlerSpacing.cardGap),
              _BulletRow(
                icon: PhosphorIcons.x(),
                color: SpendlerColors.expense,
                text: 'Non-bank SMS — filtered out',
              ),

              const SizedBox(height: SpendlerSpacing.md),
              const Text(
                'All data stays on your device. Nothing leaves your phone.',
                style: TextStyle(color: SpendlerColors.textTertiary, fontSize: 12),
              ),

              const Spacer(),

              // CTA
              if (_requesting)
                const Center(
                  child: CircularProgressIndicator(color: SpendlerColors.primary),
                )
              else
                NeoPOPButton(
                  label: 'Allow SMS Access',
                  onTap: _requestPermission,
                ),
              const SizedBox(height: SpendlerSpacing.md),
              Center(
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: const Text(
                    'I\'ll add manually',
                    style: TextStyle(color: SpendlerColors.textSecondary, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: SpendlerSpacing.md),
            ],
          ),
          ),
          ),
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(icon, color: color, size: 18),
        const SizedBox(width: SpendlerSpacing.cardGap),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: SpendlerColors.textPrimary, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

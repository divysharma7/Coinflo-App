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
      backgroundColor: PaisaColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PaisaRadii.sheet)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(PaisaSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SMS access is needed',
              style: PaisaTextStyles.onboardingHeadline,
            ),
            const SizedBox(height: PaisaSpacing.sm),
            const Text(
              'Without it, transactions won\'t be captured automatically. '
              'You can still add them manually.',
              style: PaisaTextStyles.onboardingBody,
            ),
            const SizedBox(height: PaisaSpacing.lg),
            NeoPOPButton(
              label: 'Try Again',
              onTap: () {
                Navigator.pop(context);
                _requestPermission();
              },
            ),
            const SizedBox(height: PaisaSpacing.md),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onComplete(); // proceed without SMS
                },
                child: const Text(
                  'Continue without SMS',
                  style: TextStyle(color: PaisaColors.textSecondary, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: PaisaSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showPermanentlyDeniedSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PaisaColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PaisaRadii.sheet)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(PaisaSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SMS access was blocked',
              style: PaisaTextStyles.onboardingHeadline,
            ),
            const SizedBox(height: PaisaSpacing.sm),
            const Text(
              'You\'ll need to enable it manually in Settings.',
              style: PaisaTextStyles.onboardingBody,
            ),
            const SizedBox(height: PaisaSpacing.md),
            // Step-by-step instructions.
            // These steps are intentionally generic so they work across all
            // Android OEMs including Samsung (One UI), Xiaomi (MIUI), etc.
            // Samsung path: Settings → Apps → Pulse → Permissions → SMS → Allow
            // which matches the wording below.
            Container(
              padding: const EdgeInsets.all(PaisaSpacing.cardPadding),
              decoration: BoxDecoration(
                color: PaisaColors.surface,
                borderRadius: BorderRadius.circular(PaisaRadii.button),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Open Settings', style: TextStyle(color: PaisaColors.textPrimary, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('2. Apps → Pulse → Permissions', style: TextStyle(color: PaisaColors.textPrimary, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('3. SMS → Allow', style: TextStyle(color: PaisaColors.textPrimary, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: PaisaSpacing.lg),
            NeoPOPButton(
              label: 'Open Settings',
              onTap: () {
                openAppSettings();
              },
            ),
            const SizedBox(height: PaisaSpacing.md),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onComplete();
                },
                child: const Text(
                  'Continue without SMS',
                  style: TextStyle(color: PaisaColors.textSecondary, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: PaisaSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaisaColors.scaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PaisaSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // What we read
              PhosphorIcon(PhosphorIcons.shieldCheck(), color: PaisaColors.yellow, size: 48),
              const SizedBox(height: PaisaSpacing.lg),
              const Text(
                'What Pulse reads\nfrom your SMS',
                style: PaisaTextStyles.onboardingHeadline,
              ),
              const SizedBox(height: PaisaSpacing.lg),

              _BulletRow(
                icon: PhosphorIcons.check(),
                color: PaisaColors.income,
                text: 'SBI bank transaction alerts',
              ),
              const SizedBox(height: PaisaSpacing.cardGap),
              _BulletRow(
                icon: PhosphorIcons.check(),
                color: PaisaColors.income,
                text: 'UPI payment confirmations',
              ),
              const SizedBox(height: PaisaSpacing.lg),
              _BulletRow(
                icon: PhosphorIcons.x(),
                color: PaisaColors.expense,
                text: 'Personal messages — never read',
              ),
              const SizedBox(height: PaisaSpacing.cardGap),
              _BulletRow(
                icon: PhosphorIcons.x(),
                color: PaisaColors.expense,
                text: 'OTPs — ignored completely',
              ),
              const SizedBox(height: PaisaSpacing.cardGap),
              _BulletRow(
                icon: PhosphorIcons.x(),
                color: PaisaColors.expense,
                text: 'Non-bank SMS — filtered out',
              ),

              const SizedBox(height: PaisaSpacing.md),
              const Text(
                'All data stays on your device. Nothing leaves your phone.',
                style: TextStyle(color: PaisaColors.textTertiary, fontSize: 12),
              ),

              const Spacer(),

              // CTA
              if (_requesting)
                const Center(
                  child: CircularProgressIndicator(color: PaisaColors.yellow),
                )
              else
                NeoPOPButton(
                  label: 'Allow SMS Access',
                  onTap: _requestPermission,
                ),
              const SizedBox(height: PaisaSpacing.md),
              Center(
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: const Text(
                    'I\'ll add manually',
                    style: TextStyle(color: PaisaColors.textSecondary, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: PaisaSpacing.md),
            ],
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
        const SizedBox(width: PaisaSpacing.cardGap),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: PaisaColors.textPrimary, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

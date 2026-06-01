import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/constants/faqs.dart';
import 'package:finance_buddy_app/pages/settings/widgets/settings_report_bug_dialog.dart';

// ---------------------------------------------------------------------------
// Help & Support Sheet
// ---------------------------------------------------------------------------

class SettingsHelpSupportSheet extends StatefulWidget {
  const SettingsHelpSupportSheet({super.key});

  @override
  State<SettingsHelpSupportSheet> createState() => _SettingsHelpSupportSheetState();
}

class _SettingsHelpSupportSheetState extends State<SettingsHelpSupportSheet> {
  int? _expandedFaq;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Help & Support',
                    style: AppTextStyles.headingS
                        .copyWith(color: AppColors.black)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                children: [
                  // Email Us
                  _helpTile(
                    icon: PhosphorIcons.envelope(),
                    title: 'Email Us',
                    subtitle: 'divysharma029@gmail.com',
                    onTap: () {
                      launchUrl(
                        Uri.parse(
                            'mailto:divysharma029@gmail.com?subject=CoinFlo%20Support'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Report a Bug
                  _helpTile(
                    icon: PhosphorIcons.bug(),
                    title: 'Report a Bug',
                    subtitle: 'Help us improve CoinFlo',
                    onTap: () {
                      Navigator.pop(context);
                      showDialog<void>(
                        context: context,
                        builder: (_) => const SettingsReportBugDialog(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // FAQ section
                  Text('FAQ',
                      style: AppTextStyles.labelM
                          .copyWith(color: AppColors.gray500)),
                  const SizedBox(height: AppSpacing.sm),

                  ...List.generate(kFaqs.length, (i) {
                    final faq = kFaqs[i];
                    final expanded = _expandedFaq == i;
                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadius.base,
                        border: Border.all(
                          color: expanded
                              ? AppColors.black
                              : AppColors.gray200,
                        ),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() {
                              _expandedFaq = expanded ? null : i;
                            }),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      faq['q']!,
                                      style: AppTextStyles.bodyM.copyWith(
                                        color: AppColors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    expanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: AppColors.gray500,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (expanded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  0,
                                  AppSpacing.md,
                                  AppSpacing.md),
                              child: Text(
                                faq['a']!,
                                style: AppTextStyles.bodyS
                                    .copyWith(color: AppColors.gray500),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Text('CoinFlo v1.0.2',
                        style: AppTextStyles.bodyS
                            .copyWith(color: AppColors.gray300)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _helpTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: AppRadius.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, size: 20, color: AppColors.gray600),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyM
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.gray500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.gray500, size: 20),
          ],
        ),
      ),
    );
  }
}

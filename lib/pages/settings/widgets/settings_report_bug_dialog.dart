import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

// ---------------------------------------------------------------------------
// Report a Bug Dialog
// ---------------------------------------------------------------------------

class SettingsReportBugDialog extends StatefulWidget {
  const SettingsReportBugDialog({super.key});

  @override
  State<SettingsReportBugDialog> createState() => _SettingsReportBugDialogState();
}

class _SettingsReportBugDialogState extends State<SettingsReportBugDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: AppRadius.sm,
                  ),
                  child: const Icon(Icons.bug_report_outlined,
                      color: AppColors.red, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Report a Bug',
                    style: AppTextStyles.headingS
                        .copyWith(color: AppColors.black)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _titleCtrl,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
              decoration: InputDecoration(
                hintText: 'Brief title',
                hintStyle:
                    AppTextStyles.bodyM.copyWith(color: AppColors.gray300),
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.base,
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _descCtrl,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.black),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe what happened...',
                hintStyle:
                    AppTextStyles.bodyM.copyWith(color: AppColors.gray300),
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.base,
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: AppRadius.base,
                      ),
                      alignment: Alignment.center,
                      child: Text('Cancel',
                          style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.gray500,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GestureDetector(
                    onTap: _sending ? null : _submit,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: AppRadius.base,
                      ),
                      alignment: Alignment.center,
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white))
                          : Text('Submit',
                              style: AppTextStyles.bodyM.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (title.isEmpty && desc.isEmpty) return;

    setState(() => _sending = true);

    // Store in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('bug_reports') ?? '[]';
    final reports = List<dynamic>.from(jsonDecode(existing) as List);
    reports.add({
      'title': title,
      'description': desc,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await prefs.setString('bug_reports', jsonEncode(reports));

    // Open email client
    final subject = Uri.encodeComponent('Bug Report: $title');
    final body = Uri.encodeComponent(
        'Title: $title\n\nDescription:\n$desc\n\nReported at: ${DateTime.now()}');
    await launchUrl(
      Uri.parse(
          'mailto:divysharma029@gmail.com?subject=$subject&body=$body'),
      mode: LaunchMode.externalApplication,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for the report — we\'ll look into it.')),
      );
    }
  }
}

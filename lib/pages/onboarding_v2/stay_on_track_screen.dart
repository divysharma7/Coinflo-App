import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';

class StayOnTrackScreen extends StatefulWidget {
  const StayOnTrackScreen({super.key});

  @override
  State<StayOnTrackScreen> createState() => _StayOnTrackScreenState();
}

class _StayOnTrackScreenState extends State<StayOnTrackScreen>
    with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = true;
  bool _dailyReminderEnabled = true;
  bool _weeklyReportEnabled = false;

  bool get _childrenEnabled => _notificationsEnabled;

  late final AnimationController _enterController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _loadSavedData();

    _enterController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    ));
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotif = prefs.getBool('notifications_enabled');
    final savedDaily = prefs.getBool('daily_reminder_enabled');
    final savedWeekly = prefs.getBool('weekly_report_enabled');
    setState(() {
      if (savedNotif != null) _notificationsEnabled = savedNotif;
      if (savedDaily != null) _dailyReminderEnabled = savedDaily;
      if (savedWeekly != null) _weeklyReportEnabled = savedWeekly;
    });
  }

  Future<void> _onNotificationToggle(bool value) async {
    if (value) {
      final status = await Permission.notification.status;

      if (status.isGranted) {
        setState(() => _notificationsEnabled = true);
      } else if (status.isDenied) {
        final result = await Permission.notification.request();
        if (result.isGranted) {
          setState(() => _notificationsEnabled = true);
        }
      } else if (status.isPermanentlyDenied) {
        _showSettingsDialog();
      }
    } else {
      setState(() => _notificationsEnabled = false);
    }
  }

  void _showSettingsDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Notifications Disabled'),
        content: const Text(
          'To enable notifications, open your device Settings and allow notifications for this app.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Open Settings'),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('daily_reminder_enabled', _dailyReminderEnabled);
    await prefs.setBool('weekly_report_enabled', _weeklyReportEnabled);

    if (mounted) await context.push('/onboarding/complete');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator (all filled)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
              ),
              child: _buildProgressIndicator(),
            ),

            // Back button
            AppBackButton(onTap: () => context.pop()),

            // Title + subtitle
            SlideTransition(
              position: _titleSlide,
              child: FadeTransition(
                opacity: _titleFade,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stay on track',
                        style: AppTextStyles.headingL
                            .copyWith(color: AppColors.black),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Set up reminders to help you stay consistent.',
                        style: AppTextStyles.bodyM
                            .copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Toggle rows
            Expanded(
              child: FadeTransition(
                opacity: _contentFade,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    children: [
                      _buildToggleRow(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Enable push notifications',
                        value: _notificationsEnabled,
                        onChanged: _onNotificationToggle,
                        enabled: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildToggleRow(
                        icon: Icons.access_time_outlined,
                        title: 'Daily Reminder',
                        subtitle: 'Remind me to log expenses every evening',
                        value: _dailyReminderEnabled,
                        onChanged: (v) =>
                            setState(() => _dailyReminderEnabled = v),
                        enabled: _childrenEnabled,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildToggleRow(
                        icon: Icons.bar_chart_outlined,
                        title: 'Weekly Report',
                        subtitle:
                            'Get a summary of your spending each week',
                        value: _weeklyReportEnabled,
                        onChanged: (v) =>
                            setState(() => _weeklyReportEnabled = v),
                        enabled: _childrenEnabled,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: AppButton(label: 'Continue', onTap: _onContinue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (index) {
        return Container(
          width: 24,
          height: 3,
          margin: EdgeInsets.only(right: index < 7 ? AppSpacing.xs : 0),
          decoration: const BoxDecoration(
            color: AppColors.black,
            borderRadius: AppRadius.full,
          ),
        );
      }),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool enabled,
  }) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: AppDurations.fast,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.xl,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.md,
              ),
              child: Icon(icon, size: 22, color: AppColors.gray600),
            ),
            const SizedBox(width: AppSpacing.md),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headingS),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.gray500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // CupertinoSwitch
            CupertinoSwitch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeTrackColor: AppColors.black,
            ),
          ],
        ),
      ),
    );
  }
}

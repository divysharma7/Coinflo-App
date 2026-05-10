import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';

class TrackIncomeScreen extends StatefulWidget {
  const TrackIncomeScreen({super.key});

  @override
  State<TrackIncomeScreen> createState() => _TrackIncomeScreenState();
}

class _TrackIncomeScreenState extends State<TrackIncomeScreen>
    with SingleTickerProviderStateMixin {
  bool _trackIncome = true;

  late final AnimationController _enterController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _yesCardFade;
  late final Animation<Offset> _yesCardSlide;
  late final Animation<double> _noCardFade;
  late final Animation<Offset> _noCardSlide;

  @override
  void initState() {
    super.initState();

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

    _yesCardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _yesCardSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _noCardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _noCardSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('track_income', _trackIncome);
    if (mounted) await Navigator.pushNamed(context, '/onboarding/step7');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
              ),
              child: _buildProgressIndicator(),
            ),

            // Back button
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                top: AppSpacing.md,
              ),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            ),

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
                        'Track your income too?',
                        style: AppTextStyles.headingL
                            .copyWith(color: AppColors.black),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Do you want to track both income and expenses, or just expenses?',
                        style: AppTextStyles.bodyM
                            .copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Option cards centered
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Yes card
                    SlideTransition(
                      position: _yesCardSlide,
                      child: FadeTransition(
                        opacity: _yesCardFade,
                        child: _buildOptionCard(
                          isSelected: _trackIncome,
                          icon: Icons.trending_up,
                          title: 'Yes, track income & expenses',
                          subtitle:
                              'See the full picture of your money flow',
                          onTap: () =>
                              setState(() => _trackIncome = true),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // No card
                    SlideTransition(
                      position: _noCardSlide,
                      child: FadeTransition(
                        opacity: _noCardFade,
                        child: _buildOptionCard(
                          isSelected: !_trackIncome,
                          icon: Icons.trending_down,
                          title: 'No, just expenses',
                          subtitle:
                              'Focus only on tracking what you spend',
                          onTap: () =>
                              setState(() => _trackIncome = false),
                        ),
                      ),
                    ),
                  ],
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
          decoration: BoxDecoration(
            color: index < 6 ? AppColors.black : AppColors.gray200,
            borderRadius: AppRadius.full,
          ),
        );
      }),
    );
  }

  Widget _buildOptionCard({
    required bool isSelected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.xl,
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.gray200,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected ? AppShadows.md : AppShadows.sm,
        ),
        child: Row(
          children: [
            // Icon box
            AnimatedContainer(
              duration: AppDurations.fast,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.black : AppColors.gray100,
                borderRadius: AppRadius.md,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.white : AppColors.gray500,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headingS.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.gray500),
                  ),
                ],
              ),
            ),
            // Checkmark
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: AppDurations.fast,
              child: const Icon(
                Icons.check_circle_outline,
                size: 24,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

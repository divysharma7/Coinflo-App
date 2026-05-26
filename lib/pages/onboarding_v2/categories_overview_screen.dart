import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_buddy_app/constants/app_categories.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/models/category_budget_model.dart';

class CategoriesOverviewScreen extends StatefulWidget {
  const CategoriesOverviewScreen({super.key});

  @override
  State<CategoriesOverviewScreen> createState() =>
      _CategoriesOverviewScreenState();
}

class _CategoriesOverviewScreenState extends State<CategoriesOverviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

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
        curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
    ));
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (mounted) await context.push('/onboarding/step6');
  }

  @override
  Widget build(BuildContext context) {
    final groups = CategoryGroup.values;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
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
            AppBackButton(onTap: () => context.pop()),

            // Scrollable content
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Title block
                  SliverToBoxAdapter(
                    child: SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.lg,
                            right: AppSpacing.lg,
                            top: AppSpacing.lg,
                            bottom: AppSpacing.xl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'We\'ve got you covered',
                                style: AppTextStyles.headingL
                                    .copyWith(color: AppColors.black),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '40 categories are already set up for you. Add more if you need something specific.',
                                style: AppTextStyles.bodyM
                                    .copyWith(color: AppColors.gray500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Category groups
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final group = groups[index];
                        final categories = kAllCategories[group] ?? [];
                        return _buildGroupSection(group, categories, index);
                      },
                      childCount: groups.length,
                    ),
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.lg),
                  ),
                ],
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
            color: index < 5 ? AppColors.black : AppColors.gray200,
            borderRadius: AppRadius.full,
          ),
        );
      }),
    );
  }

  Widget _buildGroupSection(
    CategoryGroup group,
    List<AppCategory> categories,
    int groupIndex,
  ) {
    // Staggered animation per group
    final delay = (groupIndex * 0.06).clamp(0.0, 0.6);
    final end = (delay + 0.4).clamp(0.0, 1.0);

    final groupFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: Interval(delay, end, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: groupFade,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: groupIndex == 0 ? 0 : AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: group.iconColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  group.label.toUpperCase(),
                  style: AppTextStyles.labelM
                      .copyWith(color: AppColors.gray500),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Category chips
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: categories.map((cat) => _buildChip(cat)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(AppCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.full,
        border: Border.all(color: AppColors.gray200, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 14, color: category.iconColor),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            category.name,
            style: AppTextStyles.bodyS.copyWith(color: AppColors.black),
          ),
        ],
      ),
    );
  }
}

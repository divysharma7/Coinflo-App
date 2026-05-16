import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/import_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProcessingPage extends ConsumerStatefulWidget {
  const ProcessingPage({super.key});

  @override
  ConsumerState<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends ConsumerState<ProcessingPage>
    with TickerProviderStateMixin {
  late final AnimationController _phaseController;
  late final AnimationController _spinController;
  int _currentPhaseIndex = 0;

  static const _phaseLabels = [
    'Reading your statement…',
    'Cleaning up the data…',
    'Recognizing your spending…',
    'Finding your subscriptions…',
    'Spotting unusual transactions…',
    'Building your budget baseline…',
  ];

  @override
  void initState() {
    super.initState();
    _phaseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..addListener(_updatePhase);
    _phaseController.repeat();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  void _updatePhase() {
    final newIndex = (_phaseController.value * _phaseLabels.length).floor() % _phaseLabels.length;
    if (newIndex != _currentPhaseIndex) {
      setState(() => _currentPhaseIndex = newIndex);
    }
  }

  @override
  void dispose() {
    _phaseController.removeListener(_updatePhase);
    _phaseController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ImportFlowState>(importFlowControllerProvider, (prev, next) {
      if (next.currentStep == ImportStep.review) {
        context.go('/import/review');
      } else if (next.currentStep == ImportStep.summary) {
        context.go('/import/summary');
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        context.go('/import');
      }
    });

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                const Spacer(flex: 2),
                RotationTransition(
                  turns: _spinController,
                  child: Icon(
                    PhosphorIcons.coinVertical(),
                    size: 72,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                AnimatedSwitcher(
                  duration: AppDurations.base,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    _phaseLabels[_currentPhaseIndex],
                    key: ValueKey(_currentPhaseIndex),
                    style: AppTextStyles.headingS,
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(flex: 2),
                const ClipRRect(
                  borderRadius: AppRadius.full,
                  child: LinearProgressIndicator(
                    backgroundColor: Color(0xFFE0E0E0),
                    color: Color(0xFF0A0A0A),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

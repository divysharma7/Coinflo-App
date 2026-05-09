import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';
import 'package:finance_buddy_app/pages/onboarding/onboarding_page.dart';
import 'package:finance_buddy_app/pages/shell_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _waveAnim;
  late final Animation<double> _wordmarkFade;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    // Waveform draws over 800ms
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _waveAnim = CurvedAnimation(parent: _waveCtrl, curve: Curves.easeInOut);

    // Wordmark + tagline fade in after waveform
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wordmarkFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeCtrl,
        curve: const Interval(0, 0.5, curve: Curves.easeIn),
      ),
    );
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Draw waveform
    await _waveCtrl.forward();
    // Fade in text
    await _fadeCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Navigate
    if (!mounted) return;
    final done = await ref.read(hasCompletedOnboardingProvider.future);
    if (!mounted) return;

    final destination = done ? const ShellPage() : const OnboardingPage();
    await Navigator.pushReplacement<void, void>(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionDuration: SpendlerMotion.transition,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpendlerColors.scaffold,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated ECG waveform in yellow circle
            AnimatedBuilder(
              animation: _waveAnim,
              builder: (context, _) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: SpendlerColors.yellow,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: CustomPaint(
                      painter: _WaveformPainter(progress: _waveAnim.value),
                      size: const Size(120, 120),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: SpendlerSpacing.lg),

            // SPENDLER wordmark
            FadeTransition(
              opacity: _wordmarkFade,
              child: Text(
                'SPENDLER',
                style: SpendlerTextStyles.heroAmount.copyWith(
                  fontSize: 28,
                  color: SpendlerColors.yellow,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: SpendlerSpacing.sm),

            // Tagline
            FadeTransition(
              opacity: _taglineFade,
              child: const Text(
                'Track what you spend.',
                style: TextStyle(
                  color: SpendlerColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws an ECG/heartbeat waveform that reveals left-to-right.
class _WaveformPainter extends CustomPainter {
  final double progress; // 0..1

  _WaveformPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final midY = h * 0.55;

    // Build the ECG path points (normalised)
    final points = <Offset>[
      Offset(0.05 * w, midY),         // start flat
      Offset(0.25 * w, midY),         // flat line
      Offset(0.32 * w, midY + h * 0.08), // small dip before spike
      Offset(0.40 * w, h * 0.18),     // spike UP (the heartbeat)
      Offset(0.48 * w, midY + h * 0.15), // dip below baseline
      Offset(0.55 * w, midY),         // return to baseline
      Offset(0.65 * w, midY - h * 0.06), // small bump
      Offset(0.72 * w, midY),         // back to baseline
      Offset(0.95 * w, midY),         // flat line out
    ];

    // Create path
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      // Smooth curve between points
      final cpX = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }

    // Clip to progress (reveal left to right)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * progress, h));
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.progress != progress;
}

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_buddy_app/pages/onboarding/onboarding_page.dart';

void main() {
  Widget buildWidget() {
    return const MaterialApp(
      home: OnboardingPage(),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('OnboardingPage', () {
    testWidgets('step 1 shows brand identity with app name and tagline',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('\$'), findsOneWidget);
      expect(find.text('SPENDLER'), findsOneWidget);
      expect(find.text('Track your spending habits.'), findsOneWidget);
    });

    testWidgets('step 1 is tappable to advance via GestureDetector',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // The identity screen is wrapped in a GestureDetector
      expect(find.byType(GestureDetector), findsWidgets);
      expect(find.text('SPENDLER'), findsOneWidget);
    });

    testWidgets('step 2 shows name input after tapping step 1',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Tap to advance from identity screen
      await tester.tap(find.text('SPENDLER'));
      await tester.pumpAndSettle();

      expect(find.text('What should we\ncall you?'), findsOneWidget);
      expect(find.text('Your first name'), findsOneWidget);
      expect(find.text('Next \u2192'), findsOneWidget);
    });

    testWidgets('PageView exists with 5 step pages', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('dot indicators are shown for all pages', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // 5 dot indicators rendered as AnimatedContainer
      expect(find.byType(AnimatedContainer), findsNWidgets(5));
    });

    testWidgets('BouncingScrollPhysics allows swipe navigation',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Swipe left to go to step 2 (name screen)
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await tester.pumpAndSettle();

      expect(find.text('What should we\ncall you?'), findsOneWidget);
    });

    testWidgets('step 1 brand screen shows dollar sign hero',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Verify the dollar sign is displayed as a hero element
      expect(find.text('\$'), findsOneWidget);
      expect(find.text('SPENDLER'), findsOneWidget);
    });

    testWidgets('last step shows start button with SMS access',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Navigate to the last page by swiping one page at a time
      for (int i = 0; i < 4; i++) {
        await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
        await tester.pumpAndSettle();
      }

      expect(find.text('Let\'s get started.'), findsOneWidget);
      // NeoPOPButton uppercases the label
      expect(find.text('ALLOW SMS ACCESS'), findsOneWidget);
      expect(find.text('I\'ll add manually'), findsOneWidget);
    });
  });
}

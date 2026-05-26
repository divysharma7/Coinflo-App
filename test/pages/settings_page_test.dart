import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/pages/settings/settings_page.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';

void main() {
  Widget buildWidget({
    String? userName,
    String? userEmail,
    String? currency,
    bool? trackIncome,
  }) {
    return ProviderScope(
      overrides: [
        userNameProvider.overrideWith((_) async => userName),
        userEmailProvider.overrideWith((_) async => userEmail),
        selectedCurrencyProvider.overrideWith((_) async => currency ?? 'inr'),
        trackIncomeProvider.overrideWith((_) async => trackIncome ?? true),
      ],
      child: const MaterialApp(
        home: SettingsPage(),
      ),
    );
  }

  group('SettingsPage', () {
    testWidgets('renders Settings title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders profile card with user name', (tester) async {
      await tester.pumpWidget(buildWidget(
        userName: 'Alice',
        userEmail: 'alice@example.com',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);
    });

    testWidgets('profile card shows defaults when no user data',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('User'), findsOneWidget);
      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('renders GENERAL section header', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('GENERAL'), findsOneWidget);
    });

    testWidgets('renders General section items', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ask Saraswati'), findsOneWidget);
      expect(find.text('Plans & Pricing'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Accounts'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Monthly Budget'), findsOneWidget);
    });

    testWidgets('renders ABOUT section header', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Scroll down to reveal ABOUT section
      await tester.scrollUntilVisible(
        find.text('ABOUT'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('renders About section items', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Help & Support'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Rate the App'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);
      expect(find.text('1.0.2'), findsOneWidget);
    });

    testWidgets('renders toggle switches for Track Income and Notifications',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Scroll to reveal toggle rows
      await tester.scrollUntilVisible(
        find.text('Track Income'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Track Income'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);

      // Two toggle switches
      expect(find.byType(Switch), findsNWidgets(2));
    });

    testWidgets('Track Income toggle is initially on', (tester) async {
      await tester.pumpWidget(buildWidget(trackIncome: true));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Track Income'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final switches =
          tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches[0].value, isTrue);
    });

    testWidgets('renders currency display value', (tester) async {
      await tester.pumpWidget(buildWidget(currency: 'inr'));
      await tester.pumpAndSettle();

      // Currency row should display INR (\u20b9)
      expect(find.textContaining('INR'), findsOneWidget);
    });

    testWidgets('renders Log Out button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Log Out'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Log Out'), findsOneWidget);
    });
  });
}

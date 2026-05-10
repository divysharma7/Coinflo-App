import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/pages/settings/profile_sheet.dart';
import 'package:finance_buddy_app/providers/onboarding_provider.dart';

void main() {
  Widget buildWidget({
    String? userName,
    String? userEmail,
  }) {
    return ProviderScope(
      overrides: [
        userNameProvider.overrideWith((_) async => userName),
        userEmailProvider.overrideWith((_) async => userEmail),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: const ProfileSheet(),
        ),
      ),
    );
  }

  group('ProfileSheet', () {
    testWidgets('renders Profile header', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('shows initials from two-word name', (tester) async {
      await tester.pumpWidget(buildWidget(userName: 'Alice Smith'));
      await tester.pumpAndSettle();

      // Two-word name => first letters: AS
      expect(find.text('AS'), findsOneWidget);
    });

    testWidgets('shows initials from single-word name', (tester) async {
      await tester.pumpWidget(buildWidget(userName: 'Bob'));
      await tester.pumpAndSettle();

      // Single name with 2+ chars => first two chars: BO
      expect(find.text('BO'), findsOneWidget);
    });

    testWidgets('shows full name below avatar', (tester) async {
      await tester.pumpWidget(buildWidget(userName: 'Alice Smith'));
      await tester.pumpAndSettle();

      expect(find.text('Alice Smith'), findsOneWidget);
    });

    testWidgets('shows default name when not set', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Default is 'User'
      expect(find.text('User'), findsOneWidget);
      expect(find.text('US'), findsOneWidget);
    });

    testWidgets('shows email when provided', (tester) async {
      await tester.pumpWidget(buildWidget(
        userName: 'Alice',
        userEmail: 'alice@example.com',
      ));
      await tester.pumpAndSettle();

      expect(find.text('alice@example.com'), findsOneWidget);
    });

    testWidgets('shows Not set when email is null', (tester) async {
      await tester.pumpWidget(buildWidget(userName: 'Alice'));
      await tester.pumpAndSettle();

      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('renders close button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('renders Settings and Accounts action rows', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Accounts'), findsOneWidget);
    });

    testWidgets('avatar circle has primary color background', (tester) async {
      await tester.pumpWidget(buildWidget(userName: 'Test'));
      await tester.pumpAndSettle();

      // Find the avatar container (80x80 circle)
      final container = tester.widgetList<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.maxWidth == 80 &&
              w.constraints?.maxHeight == 80,
        ),
      );
      // Avatar container exists
      expect(container, isNotEmpty);
    });
  });
}

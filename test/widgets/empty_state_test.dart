import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/widgets/common/empty_state.dart';

void main() {
  Widget buildWidget({
    IconData icon = Icons.inbox,
    String message = 'No transactions yet',
    String? subtitle,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: EmptyState(
          icon: icon,
          message: message,
          subtitle: subtitle,
        ),
      ),
    );
  }

  testWidgets('shows message text', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(message: 'Nothing here'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('shows icon', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(icon: Icons.inbox));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.inbox), findsOneWidget);
  });

  testWidgets('shows subtitle when provided', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(
      subtitle: 'Add your first transaction',
    ));
    await tester.pumpAndSettle();

    expect(find.text('Add your first transaction'), findsOneWidget);
  });

  testWidgets('hides subtitle when not provided', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(subtitle: null));
    await tester.pumpAndSettle();

    expect(find.text('No transactions yet'), findsOneWidget);
  });
}

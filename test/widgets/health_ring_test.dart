import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/widgets/common/health_ring.dart';

void main() {
  Widget buildWidget({
    double progress = 0.75,
    String? label,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HealthRing(progress: progress, label: label),
      ),
    );
  }

  testWidgets('renders percentage text for given progress',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(progress: 0.75));
    await tester.pumpAndSettle();

    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('renders 0% for zero progress', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(progress: 0.0));
    await tester.pumpAndSettle();

    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('renders 100% for full progress', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(progress: 1.0));
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('shows label when provided', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(label: 'remaining'));
    await tester.pumpAndSettle();

    expect(find.text('remaining'), findsOneWidget);
  });

  testWidgets('hides label when not provided', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(label: null));
    await tester.pumpAndSettle();

    // Should only have the percentage text, no label
    expect(find.text('75%'), findsOneWidget);
    // Only the percentage Text widget inside the ring's Center column
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    expect(textWidgets.length, 1);
  });
}

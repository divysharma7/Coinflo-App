import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/widgets/common/animated_amount.dart';

void main() {
  Widget buildWidget({
    double value = 1000,
    String prefix = '\$ ',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AnimatedAmount(value: value, prefix: prefix),
      ),
    );
  }

  testWidgets('renders formatted amount with default prefix',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(value: 12500));
    await tester.pumpAndSettle();

    // 12500 formatted = "12,500", with prefix "$ " => "$ 12,500"
    expect(find.text('\$ 12,500'), findsOneWidget);
  });

  testWidgets('renders small amount without comma',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(value: 500));
    await tester.pumpAndSettle();

    expect(find.text('\$ 500'), findsOneWidget);
  });

  testWidgets('renders with custom prefix', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(value: 2000, prefix: '₹ '));
    await tester.pumpAndSettle();

    expect(find.text('₹ 2,000'), findsOneWidget);
  });

  testWidgets('renders with empty prefix', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(value: 750, prefix: ''));
    await tester.pumpAndSettle();

    expect(find.text('750'), findsOneWidget);
  });
}

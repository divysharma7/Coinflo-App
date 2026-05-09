import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/widgets/common/hero_amount.dart';

void main() {
  Widget buildWidget({
    double amount = 1234,
    String symbol = '\$',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HeroAmount(amount: amount, symbol: symbol),
      ),
    );
  }

  testWidgets('renders default dollar symbol', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('\$'), findsOneWidget);
  });

  testWidgets('renders custom currency symbol', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(symbol: '₹'));
    await tester.pumpAndSettle();

    expect(find.text('₹'), findsOneWidget);
  });

  testWidgets('renders formatted amount', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(amount: 1234));
    await tester.pumpAndSettle();

    // AnimatedAmount formats 1234 as "1,234"
    expect(find.text('1,234'), findsOneWidget);
  });
}

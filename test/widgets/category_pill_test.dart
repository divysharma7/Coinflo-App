import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/enums.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/widgets/common/category_pill.dart';

void main() {
  Widget buildWidget({
    TransactionCategory category = TransactionCategory.foodAndDrink,
    double? amount,
    bool selected = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CategoryPill(
          category: category,
          amount: amount,
          selected: selected,
        ),
      ),
    );
  }

  testWidgets('shows category label text', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(category: TransactionCategory.shopping));

    expect(find.text('Shopping'), findsOneWidget);
  });

  testWidgets('shows label with amount when amount is provided',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(
      category: TransactionCategory.transport,
      amount: 500,
    ));

    expect(find.text('Transport \$500'), findsOneWidget);
  });

  testWidgets('icon uses category color when selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(
      category: TransactionCategory.foodAndDrink,
      selected: true,
    ));

    final icon = tester.widget<Icon>(find.byType(Icon));
    final expectedColor = SpendlerColors.categoryColor(
      TransactionCategory.foodAndDrink,
    );
    expect(icon.color, expectedColor);
  });

  testWidgets('icon uses muted color when not selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(
      category: TransactionCategory.foodAndDrink,
      selected: false,
    ));

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, SpendlerColors.textSecondary);
  });
}

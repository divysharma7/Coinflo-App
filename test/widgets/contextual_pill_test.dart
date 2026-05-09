import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/widgets/common/contextual_pill.dart';

void main() {
  Widget buildWidget({
    required String text,
    DeltaType type = DeltaType.neutral,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ContextualPill(text: text, type: type),
      ),
    );
  }

  testWidgets('renders text in uppercase', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(text: 'on track'));

    expect(find.text('ON TRACK'), findsOneWidget);
  });

  testWidgets('positive type uses accentGreen color',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(
      text: '+10%',
      type: DeltaType.positive,
    ));

    final textWidget = tester.widget<Text>(find.text('+10%'));
    expect(textWidget.style?.color, SpendlerColors.accentGreen);
  });

  testWidgets('negative type uses accentAmber color',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(
      text: '-5%',
      type: DeltaType.negative,
    ));

    final textWidget = tester.widget<Text>(find.text('-5%'));
    expect(textWidget.style?.color, SpendlerColors.accentAmber);
  });

  testWidgets('neutral type uses accentBlue color',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(
      text: 'stable',
      type: DeltaType.neutral,
    ));

    final textWidget = tester.widget<Text>(find.text('STABLE'));
    expect(textWidget.style?.color, SpendlerColors.accentBlue);
  });
}

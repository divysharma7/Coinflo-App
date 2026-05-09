import 'package:flutter_test/flutter_test.dart';
import 'package:finance_buddy_app/app.dart';

void main() {
  testWidgets('App renders splash screen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const PaisaBoltaApp());
    await tester.pump();

    // App starts with splash screen showing brand name
    expect(find.text('PULSE'), findsOneWidget);
  });
}

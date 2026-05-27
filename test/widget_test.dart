import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/pages/splash/splash_page.dart';

void main() {
  testWidgets('Splash page renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SplashPage())));
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);
  });
}

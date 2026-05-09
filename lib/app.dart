import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/core/theme.dart';
import 'package:finance_buddy_app/pages/splash/splash_page.dart';

class SpendlerApp extends StatelessWidget {
  const SpendlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Force dark status bar / nav bar to match our OLED theme.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return ProviderScope(
      child: MaterialApp(
        title: 'Spendler',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: SpendlerTheme.darkTheme,
        theme: SpendlerTheme.darkTheme,
        home: const SplashPage(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/core/router.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

class SpendlerApp extends StatelessWidget {
  const SpendlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);

          return MaterialApp.router(
            title: 'CoinFlo',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.light,
            theme: ThemeData.light(useMaterial3: true).copyWith(
              // Schibsted Grotesk is the app-wide UI typeface (CoinFlo Hi-Fi);
              // amounts override to JetBrains Mono via AppTextStyles.
              textTheme: ThemeData.light(useMaterial3: true)
                  .textTheme
                  .apply(fontFamily: 'SchibstedGrotesk'),
              scaffoldBackgroundColor: AppColors.offWhite,
              colorScheme: const ColorScheme.light(
                surface: AppColors.white,
                primary: AppColors.black,
                onPrimary: AppColors.white,
                error: AppColors.red,
                onSurface: AppColors.black,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.offWhite,
                foregroundColor: AppColors.black,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.dark,
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                dragHandleColor: AppColors.gray300,
                dragHandleSize: Size(36, 4),
                showDragHandle: true,
              ),
              dividerTheme: const DividerThemeData(
                color: AppColors.gray200,
                thickness: 1,
                space: 0,
              ),
              snackBarTheme: SnackBarThemeData(
                backgroundColor: AppColors.nearBlack,
                contentTextStyle:
                    AppTextStyles.bodyM.copyWith(color: AppColors.white),
                behavior: SnackBarBehavior.floating,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.md,
                ),
              ),
            ),
            darkTheme: ThemeData.light(useMaterial3: true),
            // Clamp OS font scaling so 1.5–2x accessibility settings don't
            // overflow fixed-height components (buttons, nav rows, chips).
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: child!,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}

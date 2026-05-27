import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finance_buddy_app/app.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/local/local_repository.dart';
import 'package:finance_buddy_app/design_system/app_durations.dart';
import 'package:finance_buddy_app/firebase_options.dart';
import 'package:finance_buddy_app/services/notifications/notification_service.dart';

/// Whether Firebase was successfully initialized.
bool firebaseInitialized = false;

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Configure flutter_animate defaults
      Animate.defaultDuration = AppDurations.base;
      Animate.defaultCurve = Curves.easeOutCubic;

      // Show user-friendly error widget in release mode
      if (kReleaseMode) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return const Material(
            child: Center(
              child: Text(
                'Something went wrong',
                style: TextStyle(fontSize: 16),
                textDirection: TextDirection.ltr,
              ),
            ),
          );
        };
      }

      // Log Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        debugPrint('FlutterError: ${details.exception}');
        debugPrint('Stack trace: ${details.stack}');
        if (firebaseInitialized) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
      };

      // Catch platform-level uncaught errors
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        debugPrint('PlatformDispatcher error: $error');
        debugPrint('Stack trace: $stack');
        if (firebaseInitialized) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        }
        return true;
      };

      // Initialize Firebase (non-blocking — app works without it)
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        firebaseInitialized = true;
        if (kDebugMode) debugPrint('Firebase initialized successfully');
      } on Exception catch (e) {
        if (kDebugMode) debugPrint('Firebase initialization skipped: $e');
      }

      // Initialize notifications
      await NotificationService().initialize();

      // Purge notifications older than 30 days
      final db = SpendlerDatabase();
      final repo = LocalRepository(db);
      await repo.purgeOlderThan(30);
      await db.close();

      runApp(const SpendlerApp());
    },
    (Object error, StackTrace stack) {
      if (kDebugMode) {
        debugPrint('Unhandled async error: $error');
        debugPrint('Stack trace: $stack');
      }
      if (firebaseInitialized) {
        FirebaseCrashlytics.instance.recordError(error, stack);
      }
    },
  );
}

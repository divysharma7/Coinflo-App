import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:finance_buddy_app/app.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/local/local_repository.dart';
import 'package:finance_buddy_app/firebase_options.dart';
import 'package:finance_buddy_app/services/notifications/notification_service.dart';

/// Whether Firebase was successfully initialized.
bool firebaseInitialized = false;

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Log Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        debugPrint('FlutterError: ${details.exception}');
        debugPrint('Stack trace: ${details.stack}');
      };

      // Catch platform-level uncaught errors
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        debugPrint('PlatformDispatcher error: $error');
        debugPrint('Stack trace: $stack');
        return true;
      };

      // Initialize Firebase (non-blocking — app works without it)
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        firebaseInitialized = true;
        debugPrint('Firebase initialized successfully');
      } on Exception catch (e) {
        debugPrint('Firebase initialization skipped: $e');
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
      debugPrint('Unhandled async error: $error');
      debugPrint('Stack trace: $stack');
    },
  );
}

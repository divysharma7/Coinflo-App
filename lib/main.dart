import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:finance_buddy_app/app.dart';
import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/data/repositories/local/local_repository.dart';
import 'package:finance_buddy_app/data/seed_data.dart';
import 'package:finance_buddy_app/services/notifications/notification_service.dart';

Future<void> main() async {
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

  // Initialize notifications
  await NotificationService().initialize();

  // Seed dummy data on first launch
  final db = PaisaDatabase();
  await SeedData.seedIfNeeded(db);

  // Purge notifications older than 30 days
  final repo = LocalRepository(db);
  await repo.purgeOlderThan(30);

  await db.close();

  // Run the app inside a guarded zone to catch async errors
  runZonedGuarded(
    () {
      runApp(const PaisaBoltaApp());
    },
    (Object error, StackTrace stack) {
      debugPrint('Unhandled async error: $error');
      debugPrint('Stack trace: $stack');
    },
  );
}

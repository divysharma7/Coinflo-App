import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finance_buddy_app/services/auth/auth_service.dart';
import 'package:finance_buddy_app/services/firestore/firestore_service.dart';

/// Singleton auth service.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Singleton Firestore service.
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

/// Stream of Firebase auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Whether the user has a stored local auth token (hard returning-user check).
final isReturningUserProvider = FutureProvider<bool>((ref) async {
  return ref.watch(authServiceProvider).isReturningUser();
});

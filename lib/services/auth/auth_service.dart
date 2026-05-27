import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _authTokenKey = 'auth_token';
  static const _userUidKey = 'user_uid';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  FirebaseAuth? _auth;

  FirebaseAuth get _firebaseAuth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  /// Current Firebase user (null if Firebase not initialized).
  User? get currentUser {
    try {
      return _firebaseAuth.currentUser;
    } on Exception catch (_) {
      return null;
    }
  }

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges {
    try {
      return _firebaseAuth.authStateChanges();
    } on Exception catch (_) {
      return const Stream.empty();
    }
  }

  // ─── Local auth token (hard check) ──────────────────

  /// Returns true if a local auth token exists (returning user).
  Future<bool> isReturningUser() async {
    final token = await _secureStorage.read(key: _authTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Store auth token + uid in encrypted storage after sign-in/sign-up.
  Future<void> _storeAuthLocally(User user) async {
    final token = await user.getIdToken();
    if (token != null) {
      await _secureStorage.write(key: _authTokenKey, value: token);
    }
    await _secureStorage.write(key: _userUidKey, value: user.uid);
  }

  /// Get locally stored user UID.
  Future<String?> getStoredUid() async {
    return _secureStorage.read(key: _userUidKey);
  }

  // ─── Firebase Auth methods ──────────────────────────

  /// Sign up with email and password.
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await _storeAuthLocally(user);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('Sign-up failed: ${e.code}');
      rethrow;
    }
  }

  /// Sign in with email and password.
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await _storeAuthLocally(user);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('Sign-in failed: ${e.code}');
      rethrow;
    }
  }

  /// Sign out and clear local auth data.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Firebase sign-out error: $e');
    }
    await _secureStorage.delete(key: _authTokenKey);
    await _secureStorage.delete(key: _userUidKey);
  }

  /// Clear local auth data only (without Firebase sign-out).
  Future<void> clearLocalAuth() async {
    await _secureStorage.delete(key: _authTokenKey);
    await _secureStorage.delete(key: _userUidKey);
  }
}

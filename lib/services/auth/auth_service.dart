import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _authTokenKey = 'auth_token';
  static const _userUidKey = 'user_uid';

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Store auth token + uid locally after successful sign-in/sign-up.
  Future<void> _storeAuthLocally(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await user.getIdToken();
    if (token != null) {
      await prefs.setString(_authTokenKey, token);
    }
    await prefs.setString(_userUidKey, user.uid);
  }

  /// Get locally stored user UID.
  Future<String?> getStoredUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userUidKey);
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
      debugPrint('Sign-up failed: ${e.message}');
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
      debugPrint('Sign-in failed: ${e.message}');
      rethrow;
    }
  }

  /// Sign out and clear local auth data.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on Exception catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_userUidKey);
  }

  /// Clear local auth data only (without Firebase sign-out).
  Future<void> clearLocalAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_userUidKey);
  }
}

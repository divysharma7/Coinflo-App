import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  // ─── User profile ─────────────────────────────────────

  /// Create the full user profile + all onboarding data in one batch.
  Future<void> createUserWithOnboardingData({
    required String uid,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final batch = _db.batch();

    // 1. User profile document (exclude null values to satisfy security rules)
    final profileData = <String, dynamic>{
      'email': email,
      'trackIncome': prefs.getBool('track_income') ?? true,
      'notificationsEnabled': prefs.getBool('notifications_enabled') ?? true,
      'dailyReminderEnabled': prefs.getBool('daily_reminder_enabled') ?? true,
      'weeklyReportEnabled': prefs.getBool('weekly_report_enabled') ?? false,
      'onboardingCompleted': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final name = prefs.getString('user_name');
    if (name != null) profileData['name'] = name;
    final currency = prefs.getString('currency_code');
    if (currency != null) profileData['currency'] = currency;
    final currencySymbol = prefs.getString('currency_symbol');
    if (currencySymbol != null) profileData['currencySymbol'] = currencySymbol;
    final monthlyBudget = prefs.getInt('monthly_budget');
    if (monthlyBudget != null) profileData['monthlyBudget'] = monthlyBudget;
    batch.set(_userDoc(uid), profileData);

    // 2. Accounts subcollection
    final accountsJson = prefs.getString('accounts');
    if (accountsJson != null) {
      final accounts =
          (jsonDecode(accountsJson) as List).cast<Map<String, dynamic>>();
      for (final account in accounts) {
        final docRef = _userDoc(uid).collection('accounts').doc(account['id'] as String);
        batch.set(docRef, {
          ...account,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // 3. Category budgets subcollection
    final budgetsJson = prefs.getString('category_budgets');
    if (budgetsJson != null) {
      final budgets =
          (jsonDecode(budgetsJson) as List).cast<Map<String, dynamic>>();
      for (final budget in budgets) {
        final docRef = _userDoc(uid).collection('categoryBudgets').doc(budget['id'] as String);
        batch.set(docRef, {
          ...budget,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // 4. Savings goals subcollection
    final goalsJson = prefs.getString('savings_goals');
    if (goalsJson != null) {
      final goals =
          (jsonDecode(goalsJson) as List).cast<Map<String, dynamic>>();
      for (final goal in goals) {
        final cleanGoal = Map<String, dynamic>.from(goal)
          ..removeWhere((_, v) => v == null);
        final docRef = _userDoc(uid).collection('savingsGoals').doc(goal['id'] as String);
        batch.set(docRef, cleanGoal);
      }
    }

    // 5. Recurring payments subcollection
    final paymentsJson = prefs.getString('recurring_payments');
    if (paymentsJson != null) {
      final payments =
          (jsonDecode(paymentsJson) as List).cast<Map<String, dynamic>>();
      for (final payment in payments) {
        final cleanPayment = Map<String, dynamic>.from(payment)
          ..removeWhere((_, v) => v == null);
        final docRef = _userDoc(uid).collection('recurringPayments').doc(payment['id'] as String);
        batch.set(docRef, cleanPayment);
      }
    }

    // Commit everything atomically
    await batch.commit();
    debugPrint('Firestore: synced all onboarding data for $uid');
  }

  // ─── Fetch data for returning users ───────────────────

  /// Fetch the full user profile.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _userDoc(uid).get();
    return doc.data();
  }

  /// Fetch all onboarding data and hydrate SharedPreferences + return raw data.
  Future<void> hydrateLocalFromFirestore(String uid) async {
    final prefs = await SharedPreferences.getInstance();

    // Profile / settings
    final profile = await getUserProfile(uid);
    if (profile == null) return;

    if (profile['currency'] != null) {
      await prefs.setString('currency_code', profile['currency'] as String);
    }
    if (profile['currencySymbol'] != null) {
      await prefs.setString('currency_symbol', profile['currencySymbol'] as String);
    }
    if (profile['name'] != null) {
      await prefs.setString('user_name', profile['name'] as String);
    }
    if (profile['monthlyBudget'] != null) {
      await prefs.setInt('monthly_budget', profile['monthlyBudget'] as int);
    }
    if (profile['trackIncome'] != null) {
      await prefs.setBool('track_income', profile['trackIncome'] as bool);
    }
    if (profile['notificationsEnabled'] != null) {
      await prefs.setBool('notifications_enabled', profile['notificationsEnabled'] as bool);
    }
    if (profile['dailyReminderEnabled'] != null) {
      await prefs.setBool('daily_reminder_enabled', profile['dailyReminderEnabled'] as bool);
    }
    if (profile['weeklyReportEnabled'] != null) {
      await prefs.setBool('weekly_report_enabled', profile['weeklyReportEnabled'] as bool);
    }
    await prefs.setBool('onboarding_completed', true);

    // Accounts
    final accountsSnap = await _userDoc(uid).collection('accounts').get();
    if (accountsSnap.docs.isNotEmpty) {
      final accountsList = accountsSnap.docs.map((d) => d.data()).toList();
      await prefs.setString('accounts', jsonEncode(accountsList));
    }

    // Category budgets
    final budgetsSnap = await _userDoc(uid).collection('categoryBudgets').get();
    if (budgetsSnap.docs.isNotEmpty) {
      final budgetsList = budgetsSnap.docs.map((d) => d.data()).toList();
      await prefs.setString('category_budgets', jsonEncode(budgetsList));
    }

    // Savings goals
    final goalsSnap = await _userDoc(uid).collection('savingsGoals').get();
    if (goalsSnap.docs.isNotEmpty) {
      final goalsList = goalsSnap.docs.map((d) => d.data()).toList();
      await prefs.setString('savings_goals', jsonEncode(goalsList));
    }

    // Recurring payments
    final paymentsSnap = await _userDoc(uid).collection('recurringPayments').get();
    if (paymentsSnap.docs.isNotEmpty) {
      final paymentsList = paymentsSnap.docs.map((d) => d.data()).toList();
      await prefs.setString('recurring_payments', jsonEncode(paymentsList));
    }

    debugPrint('Firestore: hydrated local data for $uid');
  }

  /// Update user profile fields.
  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _userDoc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

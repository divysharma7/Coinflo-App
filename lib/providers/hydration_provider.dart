import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/data/db.dart';
import 'package:finance_buddy_app/main.dart' show firebaseInitialized;
import 'package:finance_buddy_app/providers/auth_provider.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';

/// Phase of the post-sign-in Firestore → local hydration.
enum HydrationPhase { loading, success, error }

/// Drives the sign-in hydration off the sign-in screen so it has a dedicated,
/// branded loading state plus an error/retry/skip UI (ISSUE 8).
///
/// Also performs the budgets/goals sync into Drift with upsert/dedupe semantics
/// so a repeated sign-in no longer creates duplicate rows (ISSUE 4).
class HydrationController extends StateNotifier<HydrationPhase> {
  HydrationController(this._ref, this._uid) : super(HydrationPhase.loading) {
    run();
  }

  final Ref _ref;
  final String _uid;

  Future<void> run() async {
    if (mounted) state = HydrationPhase.loading;
    try {
      if (firebaseInitialized && _uid.isNotEmpty) {
        await _ref
            .read(firestoreServiceProvider)
            .hydrateLocalFromFirestore(_uid);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await _syncOnboardingDataToDrift();
      if (mounted) state = HydrationPhase.success;
    } on Object catch (e, st) {
      debugPrint('Hydration failed: $e\n$st');
      if (mounted) state = HydrationPhase.error;
    }
  }

  /// Sync hydrated budgets & goals from SharedPreferences into Drift.
  ///
  /// Budgets are upserted by category and goals are deduped by name, so signing
  /// in again (or after editing locally) never produces duplicate entries.
  Future<void> _syncOnboardingDataToDrift() async {
    final prefs = await SharedPreferences.getInstance();
    final repo = _ref.read(repositoryProvider);

    // Category budgets — upsert by category.
    final budgetsJson = prefs.getString('category_budgets');
    if (budgetsJson != null) {
      try {
        final list =
            (jsonDecode(budgetsJson) as List).cast<Map<String, dynamic>>();
        for (final b in list) {
          final category = b['group'] as String? ?? '';
          final limit = (b['monthlyLimit'] as num?)?.toDouble() ?? 0;
          if (category.isEmpty || limit <= 0) continue;
          final existing = await repo.getBudgetForCategory(category);
          if (existing != null) {
            await repo.updateBudget(
              existing.id,
              CategoryBudgetsCompanion(monthlyLimit: drift.Value(limit)),
            );
          } else {
            await repo.insertBudget(CategoryBudgetsCompanion(
              category: drift.Value(category),
              monthlyLimit: drift.Value(limit),
            ));
          }
        }
      } on Exception catch (e) {
        debugPrint('Budget sync to Drift failed: $e');
      }
    }

    // Savings goals — skip names that already exist (dedupe by name).
    final goalsJson = prefs.getString('savings_goals');
    if (goalsJson != null) {
      try {
        final existingGoals = await repo.watchAllGoals().first;
        final existingNames = {
          for (final g in existingGoals) g.name.trim().toLowerCase(),
        };
        final list =
            (jsonDecode(goalsJson) as List).cast<Map<String, dynamic>>();
        for (final g in list) {
          final name = g['name'] as String? ?? '';
          final target = (g['targetAmount'] as num?)?.toDouble() ?? 0;
          final icon = g['iconAsset'] as String? ?? 'star';
          if (name.isEmpty || target <= 0) continue;
          if (existingNames.contains(name.trim().toLowerCase())) continue;
          await repo.insertGoal(SavingsGoalsCompanion(
            name: drift.Value(name),
            targetAmount: drift.Value(target),
            iconName: drift.Value(icon),
          ));
          existingNames.add(name.trim().toLowerCase());
        }
      } on Exception catch (e) {
        debugPrint('Goals sync to Drift failed: $e');
      }
    }
  }
}

/// One controller per uid; auto-disposed when the hydration page leaves.
final hydrationControllerProvider = StateNotifierProvider.autoDispose
    .family<HydrationController, HydrationPhase, String>(
  (ref, uid) => HydrationController(ref, uid),
);

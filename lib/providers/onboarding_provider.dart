import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_buddy_app/core/enums.dart';

const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

const _onboardingKey = 'onboarding_completed';
const _userNameKey = 'user_name';

/// Returns true if onboarding has been completed.
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingKey) ?? false;
});

/// The user's first name, entered during onboarding.
final userNameProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_userNameKey);
});

/// Save the user's name during onboarding.
Future<void> saveUserName(String name) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_userNameKey, name.trim());
}

/// Call this after onboarding is done.
Future<void> completeOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingKey, true);
}

// ─── Profile settings ────────────────────────────────

const _salaryKey = 'monthly_salary';
const _targetKey = 'spending_target';

final monthlySalaryProvider = FutureProvider<double?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble(_salaryKey);
});

final spendingTargetProvider = FutureProvider<double?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble(_targetKey);
});

Future<void> saveMonthlySalary(double value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_salaryKey, value);
}

Future<void> saveSpendingTarget(double value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_targetKey, value);
}

// ─── Currency preference ─────────────────────────────

const _currencyKey = 'currency_code';

final selectedCurrencyProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_currencyKey) ?? 'inr';
});

Future<void> saveSelectedCurrency(String currencyName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_currencyKey, currencyName);
  // Also update the symbol so screens reading currency_symbol stay in sync.
  try {
    final currency = Currency.values.firstWhere((c) => c.name == currencyName);
    await prefs.setString('currency_symbol', currency.symbol);
  } on StateError catch (_) {
    // Unknown currency name — leave symbol unchanged.
  }
}

// ─── Track income toggle ─────────────────────────────

const _trackIncomeKey = 'track_income';

final trackIncomeProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_trackIncomeKey) ?? true;
});

Future<void> saveTrackIncome(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_trackIncomeKey, value);
}

// ─── Monthly budget ──────────────────────────────────

const _monthlyBudgetKey = 'monthly_budget';

final monthlyBudgetProvider = FutureProvider<double?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  // Onboarding saves as int, settings saves as double — handle both
  final asDouble = prefs.getDouble(_monthlyBudgetKey);
  if (asDouble != null) return asDouble;
  final asInt = prefs.getInt(_monthlyBudgetKey);
  if (asInt != null) return asInt.toDouble();
  return null;
});

Future<void> saveMonthlyBudget(double value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_monthlyBudgetKey, value);
}

// ─── User email (encrypted) ─────────────────────────

const _userEmailKey = 'user_email';

final userEmailProvider = FutureProvider<String?>((ref) async {
  return _secureStorage.read(key: _userEmailKey);
});

Future<void> saveUserEmail(String email) async {
  await _secureStorage.write(key: _userEmailKey, value: email);
}

// ─── Returning-user gate ────────────────────────────

/// Resolves onboarding status. If SharedPref is missing but Firebase has a
/// real UID, retroactively mark onboarding as completed.
Future<bool> resolveOnboardingStatus(SharedPreferences prefs, String? firebaseUid) async {
  final done = prefs.getBool('onboarding_completed') ?? false;
  if (done) return true;

  // Existing Firebase user without the flag — retroactively set it
  if (firebaseUid != null && firebaseUid.isNotEmpty && firebaseUid != 'test_user_123') {
    await prefs.setBool('onboarding_completed', true);
    return true;
  }
  return false;
}

/// Records the very first app launch (idempotent).
Future<void> markFirstLaunchIfNeeded(SharedPreferences prefs) async {
  if (!prefs.containsKey('first_launch')) {
    await prefs.setBool('first_launch', true);
    await prefs.setString('first_launch_date', DateTime.now().toIso8601String());
  }
}

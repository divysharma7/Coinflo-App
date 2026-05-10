import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingKey = 'onboarding_completed';
const _seededKey = 'db_seeded_v2';
const _userNameKey = 'user_name';

/// Returns true if onboarding has been completed (or user is a returning user
/// who had data before onboarding was added).
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  // Existing users who seeded data should skip onboarding
  if (prefs.getBool(_seededKey) == true &&
      prefs.getBool(_onboardingKey) != true) {
    await prefs.setBool(_onboardingKey, true);
    return true;
  }
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

const _currencyKey = 'selected_currency';

final selectedCurrencyProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_currencyKey) ?? 'inr';
});

Future<void> saveSelectedCurrency(String currencyName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_currencyKey, currencyName);
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
  return prefs.getDouble(_monthlyBudgetKey);
});

Future<void> saveMonthlyBudget(double value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_monthlyBudgetKey, value);
}

// ─── User email ──────────────────────────────────────

const _userEmailKey = 'user_email';

final userEmailProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_userEmailKey);
});

Future<void> saveUserEmail(String email) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_userEmailKey, email);
}

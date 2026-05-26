import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/providers/transaction_providers.dart';
import 'package:finance_buddy_app/providers/plan_providers.dart';
import 'package:finance_buddy_app/services/saraswati/saraswati_service.dart';
import 'package:intl/intl.dart';

/// A single chat message in the Saraswati conversation.
class SaraswatiMessage {
  SaraswatiMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String text;
  final bool isUser;
  final DateTime timestamp;
}

/// Provides the SaraswatiService instance backed by the app repository.
final saraswatiServiceProvider = Provider<SaraswatiService>((ref) {
  final repo = ref.watch(repositoryProvider);
  return SaraswatiService(repo);
});

/// Builds a financial context summary string from the user's data.
///
/// Used to hydrate Saraswati's knowledge about the user's current financial
/// situation so responses can be more contextual and personalised.
final saraswatiFinancialContextProvider = Provider<String>((ref) {
  final currencyFmt = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  final parts = <String>[];

  // Monthly expense
  final expense = ref.watch(monthlyExpenseProvider);
  expense.whenData((amt) {
    if (amt > 0) {
      parts.add('Spent ${currencyFmt.format(amt)} this month');
    }
  });

  // Top 3 categories
  final topCats = ref.watch(topCategoriesProvider);
  topCats.whenData((entries) {
    if (entries.isNotEmpty) {
      final catStrings = entries.map((e) {
        final label = e.key[0].toUpperCase() + e.key.substring(1);
        return '$label (${currencyFmt.format(e.value)})';
      }).toList();
      parts.add('Top categories: ${catStrings.join(', ')}');
    }
  });

  // Budget status
  final budgetStatus = ref.watch(budgetStatusProvider);
  budgetStatus.whenData((status) {
    if (status.totalLimit > 0) {
      parts.add(
        'Monthly budget: ${currencyFmt.format(status.totalLimit)} '
        '(${status.isOverBudget ? 'over budget by ${currencyFmt.format(status.remaining.abs())}' : '${currencyFmt.format(status.remaining)} remaining'})',
      );
    }
  });

  if (parts.isEmpty) return '';
  return "User's financial context: ${parts.join('. ')}.";
});

/// Manages the chat message history and handles sending new queries.
class SaraswatiChatNotifier extends StateNotifier<List<SaraswatiMessage>> {
  SaraswatiChatNotifier(this._service, this._financialContext)
      : super([_welcomeMessage]);

  final SaraswatiService _service;
  final String _financialContext;

  static final _welcomeMessage = SaraswatiMessage(
    text: "Hey, I'm Saraswati! I live inside your transaction data "
        "and I'm here to help you make sense of it all.\n\n"
        "Ask me anything \u2014 like *\"how much did I spend this week?\"* "
        "or *\"show me a category breakdown\"*.",
    isUser: false,
  );

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  Future<void> send(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || _isProcessing) return;

    // Add user message
    state = [...state, SaraswatiMessage(text: trimmed, isUser: true)];

    _isProcessing = true;
    // Force a state update so UI can show typing indicator
    state = [...state];

    try {
      final reply = await _service.ask(trimmed, context: _financialContext);
      state = [...state, SaraswatiMessage(text: reply, isUser: false)];
    } on Exception catch (_) {
      state = [
        ...state,
        SaraswatiMessage(
          text: "Oops, something went wrong while crunching the numbers. "
              "Give it another try!",
          isUser: false,
        ),
      ];
    } finally {
      _isProcessing = false;
    }
  }

  void clear() {
    state = [_welcomeMessage];
    _isProcessing = false;
  }
}

/// The chat message list provider.
final saraswatiChatProvider =
    StateNotifierProvider<SaraswatiChatNotifier, List<SaraswatiMessage>>((ref) {
  final service = ref.watch(saraswatiServiceProvider);
  final context = ref.watch(saraswatiFinancialContextProvider);
  return SaraswatiChatNotifier(service, context);
});

/// Whether Saraswati is currently processing a query.
final saraswatiProcessingProvider = Provider<bool>((ref) {
  final notifier = ref.watch(saraswatiChatProvider.notifier);
  // Re-evaluate when message list changes (notifier toggles state)
  ref.watch(saraswatiChatProvider);
  return notifier.isProcessing;
});

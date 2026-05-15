import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/providers/transaction_providers.dart';
import 'package:finance_buddy_app/providers/plan_providers.dart';
import 'package:finance_buddy_app/services/penny/penny_service.dart';
import 'package:intl/intl.dart';

/// A single chat message in the Penny conversation.
class PennyMessage {
  PennyMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String text;
  final bool isUser;
  final DateTime timestamp;
}

/// Provides the PennyService instance backed by the app repository.
final pennyServiceProvider = Provider<PennyService>((ref) {
  final repo = ref.watch(repositoryProvider);
  return PennyService(repo);
});

/// Builds a financial context summary string from the user's data.
///
/// Used to hydrate Penny's knowledge about the user's current financial
/// situation so responses can be more contextual and personalised.
final pennyFinancialContextProvider = Provider<String>((ref) {
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
class PennyChatNotifier extends StateNotifier<List<PennyMessage>> {
  PennyChatNotifier(this._service, this._financialContext)
      : super([_welcomeMessage]);

  final PennyService _service;
  final String _financialContext;

  static final _welcomeMessage = PennyMessage(
    text: "Hey, I'm Penny! I live inside your transaction data "
        "and I'm here to help you make sense of it all.\n\n"
        "Ask me anything — like *\"how much did I spend this week?\"* "
        "or *\"show me a category breakdown\"*.",
    isUser: false,
  );

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  Future<void> send(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || _isProcessing) return;

    // Add user message
    state = [...state, PennyMessage(text: trimmed, isUser: true)];

    _isProcessing = true;
    // Force a state update so UI can show typing indicator
    state = [...state];

    try {
      final reply = await _service.ask(trimmed, context: _financialContext);
      state = [...state, PennyMessage(text: reply, isUser: false)];
    } on Exception catch (_) {
      state = [
        ...state,
        PennyMessage(
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
final pennyChatProvider =
    StateNotifierProvider<PennyChatNotifier, List<PennyMessage>>((ref) {
  final service = ref.watch(pennyServiceProvider);
  final context = ref.watch(pennyFinancialContextProvider);
  return PennyChatNotifier(service, context);
});

/// Whether Penny is currently processing a query.
final pennyProcessingProvider = Provider<bool>((ref) {
  final notifier = ref.watch(pennyChatProvider.notifier);
  // Re-evaluate when message list changes (notifier toggles state)
  ref.watch(pennyChatProvider);
  return notifier.isProcessing;
});

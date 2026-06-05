import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_buddy_app/providers/database_providers.dart';
import 'package:finance_buddy_app/services/saraswati/saraswati_history_repository.dart';
import 'package:finance_buddy_app/providers/transaction_providers.dart';
import 'package:finance_buddy_app/providers/plan_providers.dart';
import 'package:finance_buddy_app/services/saraswati/cache/intent_cache_repository.dart';
import 'package:finance_buddy_app/services/saraswati/entry/amount_sanity_checker.dart';
import 'package:finance_buddy_app/services/saraswati/entry/disambiguation_engine.dart';
import 'package:finance_buddy_app/services/saraswati/entry/entry_action.dart';
import 'package:finance_buddy_app/services/saraswati/entry/entry_cache_repository.dart';
import 'package:finance_buddy_app/services/saraswati/entry/entry_executor.dart';
import 'package:finance_buddy_app/services/saraswati/entry/llm/entry_extractor_prompt.dart';
import 'package:finance_buddy_app/services/saraswati/entry/llm/llm_entry_extractor.dart';
import 'package:finance_buddy_app/services/saraswati/entry/pattern_matcher.dart';
import 'package:finance_buddy_app/services/saraswati/entry/personal_defaults_repository.dart';
import 'package:finance_buddy_app/services/saraswati/entry/quickadd_matcher.dart';
import 'package:finance_buddy_app/services/saraswati/intent/intent_executor.dart';
import 'package:finance_buddy_app/services/saraswati/intent/keyword_intent_matcher.dart';
import 'package:finance_buddy_app/services/saraswati/intent/saraswati_intent.dart';
import 'package:finance_buddy_app/services/saraswati/llm/llm_classifier_prompt.dart';
import 'package:finance_buddy_app/services/saraswati/llm/llm_intent_classifier.dart';
import 'package:finance_buddy_app/services/saraswati/saraswati_entry_service.dart';
import 'package:finance_buddy_app/services/saraswati/saraswati_router.dart';
import 'package:finance_buddy_app/services/saraswati/entry/transaction_draft.dart';
import 'package:finance_buddy_app/services/saraswati/saraswati_service.dart';
import 'package:intl/intl.dart';

/// A single chat message in the Saraswati conversation.
class SaraswatiMessage {
  SaraswatiMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.entryAction,
  }) : timestamp = timestamp ?? DateTime.now();

  final String text;
  final bool isUser;
  final DateTime timestamp;

  /// Non-null when this message is an entry pipeline response.
  final EntryAction? entryAction;
}

// ─── Dependency providers ────────────────────────────────

/// Intent executor backed by the app repository.
final _intentExecutorProvider = Provider<IntentExecutor>((ref) {
  final repo = ref.watch(repositoryProvider);
  return IntentExecutor(repo);
});

/// Intent cache backed by the app database.
final _intentCacheProvider = Provider<IntentCacheRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return IntentCacheRepository(db);
});

/// Persistent chat-history store backed by the app database.
final saraswatiHistoryProvider = Provider<SaraswatiHistoryRepository>((ref) {
  return SaraswatiHistoryRepository(ref.watch(databaseProvider));
});

/// Gemini model configured for intent classification.
final _classifierModelProvider = Provider<GenerativeModel>((ref) {
  return FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.0-flash',
    systemInstruction: Content.system(kClassifierSystemPrompt),
  );
});

/// LLM intent classifier.
final _llmClassifierProvider = Provider<LlmIntentClassifier>((ref) {
  final model = ref.watch(_classifierModelProvider);
  return LlmIntentClassifier(model);
});

// ─── Service provider ────────────────────────────────────

/// Provides the SaraswatiService with all dependencies wired.
final saraswatiServiceProvider = Provider<SaraswatiService>((ref) {
  return SaraswatiService(
    executor: ref.watch(_intentExecutorProvider),
    keywordMatcher: const KeywordIntentMatcher(),
    cache: ref.watch(_intentCacheProvider),
    llm: ref.watch(_llmClassifierProvider),
  );
});

// ─── Entry pipeline providers ───────────────────────────────

/// Gemini model configured for transaction extraction.
final _entryExtractorModelProvider = Provider<GenerativeModel>((ref) {
  return FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.0-flash',
    systemInstruction: Content.system(kEntryExtractorSystemPrompt),
  );
});

final _llmEntryExtractorProvider = Provider<LlmEntryExtractor>((ref) {
  return LlmEntryExtractor(ref.watch(_entryExtractorModelProvider));
});

final _entryCacheProvider = Provider<EntryCacheRepository>((ref) {
  return EntryCacheRepository(ref.watch(databaseProvider));
});

final _personalDefaultsProvider = Provider<PersonalDefaultsRepository>((ref) {
  return PersonalDefaultsRepository(ref.watch(databaseProvider));
});

final _entryExecutorProvider = Provider<EntryExecutor>((ref) {
  return EntryExecutor(
    ref.watch(repositoryProvider),
    ref.watch(_personalDefaultsProvider),
  );
});

final saraswatiEntryServiceProvider = Provider<SaraswatiEntryService>((ref) {
  return SaraswatiEntryService(
    quickaddMatcher: const QuickaddMatcher(),
    patternMatcher: const PatternMatcher(),
    cache: ref.watch(_entryCacheProvider),
    llm: ref.watch(_llmEntryExtractorProvider),
    defaults: ref.watch(_personalDefaultsProvider),
    disambiguation: const DisambiguationEngine(
      sanityChecker: AmountSanityChecker(),
    ),
  );
});

final saraswatiRouterProvider = Provider<SaraswatiRouter>((ref) {
  return const SaraswatiRouter();
});

/// Provides the entry executor for undo operations.
final saraswatiEntryExecutorProvider = Provider<EntryExecutor>((ref) {
  return ref.watch(_entryExecutorProvider);
});

// ─── Financial context ───────────────────────────────────

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

// ─── Chat state ──────────────────────────────────────────

/// Manages the chat message history and handles sending new queries.
class SaraswatiChatNotifier extends StateNotifier<List<SaraswatiMessage>> {
  SaraswatiChatNotifier(
    this._service,
    this._entryService,
    this._router,
    this._entryExecutor,
    this._financialContext,
    this._history,
  ) : super([_welcomeMessage]) {
    _loadHistory();
  }

  final SaraswatiService _service;
  final SaraswatiEntryService _entryService;
  final SaraswatiRouter _router;
  final EntryExecutor _entryExecutor;
  final String _financialContext;
  final SaraswatiHistoryRepository _history;

  /// Hydrate persisted conversation (≤7 days old) on first build. Only applies
  /// if the user hasn't already started a new message in the meantime.
  Future<void> _loadHistory() async {
    try {
      final rows = await _history.loadRecent();
      if (rows.isEmpty || state.length != 1) return;
      state = [
        _welcomeMessage,
        ...rows.map((r) => SaraswatiMessage(
              text: r.content,
              isUser: r.isUser,
              timestamp: r.createdAt,
            )),
      ];
    } on Exception catch (e) {
      debugPrint('Saraswati history load failed: $e');
    }
  }

  /// Snapshot the current conversation (excluding the static welcome) to disk.
  /// Entry actions are transient and intentionally not persisted.
  Future<void> _persist() async {
    try {
      await _history.replaceAll([
        for (final m in state)
          if (!identical(m, _welcomeMessage))
            (content: m.text, isUser: m.isUser, createdAt: m.timestamp),
      ]);
    } on Exception catch (e) {
      debugPrint('Saraswati history persist failed: $e');
    }
  }

  static final _welcomeMessage = SaraswatiMessage(
    text: "Hey, I'm Saraswati! I live inside your transaction data "
        "and I'm here to help you make sense of it all.\n\n"
        "Ask me anything \u2014 like *\"how much did I spend this week?\"* "
        "or *\"show me a category breakdown\"*. You can also log expenses "
        "\u2014 just type *\"100 coffee\"* or *\"split 600 with rahul\"*.",
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
    state = [...state];

    try {
      final route = _router.classify(trimmed.toLowerCase());

      switch (route) {
        case SaraswatiRoute.entry:
          await _handleEntry(trimmed);
        case SaraswatiRoute.question:
          await _handleQuery(trimmed);
        case SaraswatiRoute.ambiguous:
          // Try entry first; if it falls back to form, try query instead.
          final action = await _entryService.processEntry(trimmed);
          if (action is QuickFormFallbackAction &&
              action.reason == 'unrecognized') {
            await _handleQuery(trimmed);
          } else {
            _addEntryAction(action);
          }
      }
    } on Exception catch (_) {
      state = [
        ...state,
        SaraswatiMessage(
          text: "Oops, something went wrong. Give it another try!",
          isUser: false,
        ),
      ];
    } finally {
      _isProcessing = false;
      unawaited(_persist());
    }
  }

  /// Handle a chip selection from an AskOneQuestionAction.
  Future<void> confirmEntryField(
    EntryAction originalAction,
    String fieldName,
    String selectedValue,
  ) async {
    if (_isProcessing) return;
    if (originalAction is! AskOneQuestionAction) return;

    _isProcessing = true;
    state = [...state];

    try {
      var draft = originalAction.partialDraft;

      // Apply the confirmed field.
      switch (fieldName) {
        case 'category':
          draft = draft.copyWith(
            category: () => selectedValue,
            fieldConfidence: {
              ...draft.fieldConfidence,
              'category': 1.0,
            },
          );
        case 'counterparty':
          draft = draft.copyWith(
            counterparty: () => selectedValue,
            fieldConfidence: {
              ...draft.fieldConfidence,
              'counterparty': 1.0,
            },
          );
        case 'amount':
          final amount = double.tryParse(selectedValue);
          if (amount != null) {
            draft = draft.copyWith(
              amount: () => amount,
              fieldConfidence: {
                ...draft.fieldConfidence,
                'amount': 1.0,
              },
            );
          }
        case 'split_with':
          // Confirmation tap on split — proceed with commit.
          break;
      }

      // Commit the confirmed draft.
      final txnId = await _entryExecutor.commit(draft);
      await _entryService.cacheConfirmedEntry(draft.rawInput, draft);

      state = [
        ...state,
        SaraswatiMessage(
          text: _formatCommitMessage(draft),
          isUser: false,
          entryAction: SilentCommitAction(draft),
        ),
      ];

      // Store the transaction ID for undo.
      _lastCommittedTxnId = txnId;
    } on Exception catch (_) {
      state = [
        ...state,
        SaraswatiMessage(
          text: "Couldn't save that entry. Please try again.",
          isUser: false,
        ),
      ];
    } finally {
      _isProcessing = false;
      unawaited(_persist());
    }
  }

  /// Undo the last committed entry.
  int? _lastCommittedTxnId;

  Future<bool> undoLastEntry() async {
    final txnId = _lastCommittedTxnId;
    if (txnId == null) return false;
    try {
      await _entryExecutor.undo(txnId);
      _lastCommittedTxnId = null;
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Correct the last classification and replace the response.
  Future<void> correct(
    String originalQuery,
    SaraswatiIntent correctedIntent,
  ) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = [...state];

    try {
      final reply = await _service.correctIntent(
        originalQuery,
        correctedIntent,
        context: _financialContext,
      );
      state = [...state, SaraswatiMessage(text: reply, isUser: false)];
    } on Exception catch (_) {
      state = [
        ...state,
        SaraswatiMessage(
          text: "Couldn't apply that correction — please try again.",
          isUser: false,
        ),
      ];
    } finally {
      _isProcessing = false;
      unawaited(_persist());
    }
  }

  void clear() {
    state = [_welcomeMessage];
    _isProcessing = false;
    _lastCommittedTxnId = null;
    unawaited(_history.clear());
  }

  // ─── Private ──────────────────────────────────────────

  Future<void> _handleQuery(String query) async {
    final reply = await _service.ask(query, context: _financialContext);
    state = [...state, SaraswatiMessage(text: reply, isUser: false)];
  }

  Future<void> _handleEntry(String query) async {
    final action = await _entryService.processEntry(query);
    _addEntryAction(action);
  }

  void _addEntryAction(EntryAction action) {
    switch (action) {
      case SilentCommitAction(:final draft):
        // Auto-commit and show undo.
        _autoCommit(draft);
      case AskOneQuestionAction():
        state = [
          ...state,
          SaraswatiMessage(
            text: action.questionText,
            isUser: false,
            entryAction: action,
          ),
        ];
      case QuickFormFallbackAction():
        state = [
          ...state,
          SaraswatiMessage(
            text: "I'll open the form for you to fill in the details.",
            isUser: false,
            entryAction: action,
          ),
        ];
    }
  }

  Future<void> _autoCommit(TransactionDraft draft) async {
    try {
      final txnId = await _entryExecutor.commit(draft);
      _lastCommittedTxnId = txnId;
      await _entryService.cacheConfirmedEntry(draft.rawInput, draft);
      state = [
        ...state,
        SaraswatiMessage(
          text: _formatCommitMessage(draft),
          isUser: false,
          entryAction: SilentCommitAction(draft),
        ),
      ];
    } on Exception catch (_) {
      state = [
        ...state,
        SaraswatiMessage(
          text: "Couldn't save that entry. Please try again.",
          isUser: false,
        ),
      ];
    }
  }

  String _formatCommitMessage(TransactionDraft draft) {
    final amount = draft.amount?.toStringAsFixed(
            draft.amount == draft.amount!.roundToDouble() ? 0 : 2) ??
        '?';
    final category = draft.category ?? draft.kind.name;
    final who = draft.counterparty ?? '';
    final whoSuffix = who.isNotEmpty ? ' ($who)' : '';
    return 'Logged \u20B9$amount $category$whoSuffix';
  }
}

/// The chat message list provider.
final saraswatiChatProvider =
    StateNotifierProvider<SaraswatiChatNotifier, List<SaraswatiMessage>>((ref) {
  final service = ref.watch(saraswatiServiceProvider);
  final entryService = ref.watch(saraswatiEntryServiceProvider);
  final router = ref.watch(saraswatiRouterProvider);
  final entryExecutor = ref.watch(_entryExecutorProvider);
  final context = ref.watch(saraswatiFinancialContextProvider);
  final history = ref.watch(saraswatiHistoryProvider);
  return SaraswatiChatNotifier(
    service,
    entryService,
    router,
    entryExecutor,
    context,
    history,
  );
});

/// Whether Saraswati is currently processing a query.
final saraswatiProcessingProvider = Provider<bool>((ref) {
  final notifier = ref.watch(saraswatiChatProvider.notifier);
  // Re-evaluate when message list changes (notifier toggles state)
  ref.watch(saraswatiChatProvider);
  return notifier.isProcessing;
});

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/pages/add/quick_add_sheet.dart';
import 'package:finance_buddy_app/providers/saraswati_providers.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

import 'package:finance_buddy_app/pages/saraswati/widgets/assistant_bubble.dart';
import 'package:finance_buddy_app/pages/saraswati/widgets/empty_state.dart';
import 'package:finance_buddy_app/pages/saraswati/widgets/entry_action_bubble.dart';
import 'package:finance_buddy_app/pages/saraswati/widgets/input_bar.dart';
import 'package:finance_buddy_app/pages/saraswati/widgets/typing_indicator.dart';
import 'package:finance_buddy_app/pages/saraswati/widgets/user_bubble.dart';

/// Ask Saraswati — an AI chat assistant that answers questions about
/// the user's transaction data.
class SaraswatiPage extends ConsumerStatefulWidget {
  const SaraswatiPage({super.key});

  @override
  ConsumerState<SaraswatiPage> createState() => _SaraswatiPageState();
}

class _SaraswatiPageState extends ConsumerState<SaraswatiPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  Timer? _hintTimer;
  int _hintIndex = 0;

  static const _entrySuggestions = [
    '100 coffee',
    '500 grocery',
    'split 600 with rahul',
  ];

  static const _querySuggestions = [
    'How much did I spend this month?',
    'Show my spending by category',
    'How does this month compare to last month?',
  ];

  static const _hints = [
    'Ask about your finances...',
    'Log an expense \u2014 try "100 coffee"',
  ];

  @override
  void initState() {
    super.initState();
    _hintTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_focusNode.hasFocus && mounted) {
        setState(() => _hintIndex++);
      }
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Whether the user is currently near the bottom of the chat list
  /// (within ~100px). Used to decide if we should auto-scroll.
  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    return pos.maxScrollExtent - pos.pixels <= 100;
  }

  void _send([String? text]) {
    final msg = text ?? _controller.text.trim();
    if (msg.isEmpty) return;
    _controller.clear();
    ref.read(saraswatiChatProvider.notifier).send(msg);
    // User just sent a message — always scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) => _forceScrollToBottom());
  }

  void _forceScrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppDurations.base,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(saraswatiChatProvider);
    final isProcessing = ref.watch(saraswatiProcessingProvider);
    final hasMessages = messages.length > 1; // more than just the welcome message

    // Auto-scroll when new messages arrive, but only if user is near the bottom.
    // If they've scrolled up to read history, don't yank them down.
    ref.listen<List<SaraswatiMessage>>(saraswatiChatProvider, (_, _) {
      final wasNearBottom = _isNearBottom;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (wasNearBottom) _forceScrollToBottom();
      });
    });

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIcons.caretLeft(), color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ask Saraswati',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${messages.length > 1 ? messages.length - 1 : 0} transactions loaded',
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
        children: [
          // Chat messages or empty state
          Expanded(
            child: hasMessages
                ? ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: messages.length + (isProcessing ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const TypingIndicator();
                      }
                      final msg = messages[index];
                      if (msg.isUser) return UserBubble(text: msg.text);
                      if (msg.entryAction != null) {
                        return EntryActionBubble(
                          message: msg,
                          onChipTap: (field, value) {
                            ref.read(saraswatiChatProvider.notifier)
                                .confirmEntryField(msg.entryAction!, field, value);
                          },
                          onUndo: () async {
                            final ok = await ref
                                .read(saraswatiChatProvider.notifier)
                                .undoLastEntry();
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Entry undone'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          onFormFallback: () {
                            showSpendlerSheet<void>(
                              context: context,
                              builder: (_) => const QuickAddSheet(),
                            );
                          },
                        );
                      }
                      return AssistantBubble(text: msg.text);
                    },
                  )
                : EmptyState(
                    entrySuggestions: _entrySuggestions,
                    querySuggestions: _querySuggestions,
                    onSuggestionTap: _send,
                  ),
          ),

          // Input area
          InputBar(
            controller: _controller,
            focusNode: _focusNode,
            onSend: () => _send(),
            isProcessing: isProcessing,
            hintText: _hints[_hintIndex % _hints.length],
          ),
        ],
          ),
        ),
      ),
    );
  }
}

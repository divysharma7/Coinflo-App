import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/pages/add/quick_add_sheet.dart';
import 'package:finance_buddy_app/providers/saraswati_providers.dart';
import 'package:finance_buddy_app/services/saraswati/entry/entry_action.dart';
import 'package:finance_buddy_app/widgets/common/spendler_bottom_sheet.dart';

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
                        return const _TypingIndicator();
                      }
                      final msg = messages[index];
                      if (msg.isUser) return _UserBubble(text: msg.text);
                      if (msg.entryAction != null) {
                        return _EntryActionBubble(
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
                      return _AssistantBubble(text: msg.text);
                    },
                  )
                : _EmptyState(
                    entrySuggestions: _entrySuggestions,
                    querySuggestions: _querySuggestions,
                    onSuggestionTap: _send,
                  ),
          ),

          // Input area
          _InputBar(
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

// ─── Empty State ──────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.entrySuggestions,
    required this.querySuggestions,
    required this.onSuggestionTap,
  });

  final List<String> entrySuggestions;
  final List<String> querySuggestions;
  final void Function(String) onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    var delay = 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Lightning icon in rounded square
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: PhosphorIcon(
                PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          const Text(
            "Hi, I'm Saraswati",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          const Text(
            'Ask me anything about your finances, or log expenses by typing naturally.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ─── Quick Log section ──────────────────────────
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('QUICK LOG', style: AppTextStyles.labelM),
          ),
          const SizedBox(height: AppSpacing.sm),

          ...entrySuggestions.map((s) {
            final d = Duration(milliseconds: delay);
            delay += 80;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: GestureDetector(
                onTap: () => onSuggestionTap(s),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.catGreenBg,
                    borderRadius: AppRadius.base,
                    border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.arrowUpRight(),
                        color: AppColors.catGreenText,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.catGreenText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate()
                .fadeIn(delay: d, duration: AppDurations.slow)
                .slideY(begin: 0.05, delay: d, duration: AppDurations.slow);
          }),

          const SizedBox(height: AppSpacing.lg),

          // ─── Ask Saraswati section ──────────────────────
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('ASK SARASWATI', style: AppTextStyles.labelM),
          ),
          const SizedBox(height: AppSpacing.sm),

          ...querySuggestions.map((s) {
            final d = Duration(milliseconds: delay);
            delay += 80;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: GestureDetector(
                onTap: () => onSuggestionTap(s),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.base,
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      PhosphorIcon(
                        PhosphorIcons.caretRight(),
                        color: AppColors.gray500,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ).animate()
                .fadeIn(delay: d, duration: AppDurations.slow)
                .slideY(begin: 0.05, delay: d, duration: AppDurations.slow);
          }),
        ],
      ),
    );
  }
}

// ─── User Bubble ───────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxs,
        bottom: AppSpacing.xxs,
        left: 64,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.zero, // squared corner
            ),
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.gray200, width: 1),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Assistant Bubble ──────────────────────────────────────

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: AppRadius.lg,
        ),
        child: _MarkdownText(text: text),
      ),
    ).animate()
        .fadeIn(duration: AppDurations.base)
        .slideY(
            begin: 0.03,
            duration: AppDurations.base,
            curve: Curves.easeOutCubic);
  }
}

// ─── Entry Action Bubble ─────────────────────────────────────

class _EntryActionBubble extends StatefulWidget {
  const _EntryActionBubble({
    required this.message,
    required this.onChipTap,
    required this.onUndo,
    required this.onFormFallback,
  });

  final SaraswatiMessage message;
  final void Function(String field, String value) onChipTap;
  final VoidCallback onUndo;
  final VoidCallback onFormFallback;

  @override
  State<_EntryActionBubble> createState() => _EntryActionBubbleState();
}

class _EntryActionBubbleState extends State<_EntryActionBubble>
    with SingleTickerProviderStateMixin {
  bool _undoAvailable = false;
  bool _undoFading = false;
  Timer? _undoTimer;
  late final AnimationController _undoProgress;

  @override
  void initState() {
    super.initState();
    _undoProgress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    if (widget.message.entryAction is SilentCommitAction) {
      _undoAvailable = true;
      _undoProgress.forward();
      _undoTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _undoFading = true);
        // Fade out then remove.
        Future.delayed(AppDurations.fast, () {
          if (mounted) setState(() => _undoAvailable = false);
        });
      });
    }
    if (widget.message.entryAction is QuickFormFallbackAction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onFormFallback();
      });
    }
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _undoProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.message.entryAction!;
    final isCommit = action is SilentCommitAction;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isCommit ? AppColors.catGreenBg : AppColors.offWhite,
          borderRadius: AppRadius.lg,
          border: isCommit
              ? Border(
                  left: BorderSide(color: AppColors.green, width: 3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Commit: checkmark + text ─────────────────
            if (isCommit)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhosphorIcon(
                    PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                    color: AppColors.catGreenText,
                    size: 18,
                  ).animate().scale(
                        begin: const Offset(0.5, 0.5),
                        duration: AppDurations.fast,
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: _MarkdownText(text: widget.message.text)),
                ],
              )
            else
              _MarkdownText(text: widget.message.text),

            // ─── Undo pill with countdown ─────────────────
            if (isCommit && _undoAvailable) ...[
              const SizedBox(height: AppSpacing.sm),
              AnimatedOpacity(
                opacity: _undoFading ? 0.0 : 1.0,
                duration: AppDurations.fast,
                child: _UndoPill(
                  progress: _undoProgress,
                  onTap: () {
                    _undoTimer?.cancel();
                    _undoProgress.stop();
                    setState(() => _undoAvailable = false);
                    widget.onUndo();
                  },
                ),
              ),
            ],

            // ─── Chips for AskOneQuestion ─────────────────
            if (action is AskOneQuestionAction) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var i = 0; i < action.chipOptions.length; i++)
                    _TactileChip(
                      label: action.chipOptions[i],
                      onTap: () => widget.onChipTap(
                          action.fieldToConfirm, action.chipOptions[i]),
                      delay: Duration(milliseconds: 50 * i),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate()
        .fadeIn(duration: AppDurations.base)
        .slideY(
            begin: 0.03,
            duration: AppDurations.base,
            curve: Curves.easeOutCubic);
  }
}

// ─── Undo Pill with Countdown Bar ────────────────────────────

class _UndoPill extends StatelessWidget {
  const _UndoPill({required this.progress, required this.onTap});

  final AnimationController progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 32,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: AppRadius.pill,
        ),
        child: Stack(
          children: [
            // Shrinking progress bar
            AnimatedBuilder(
              animation: progress,
              builder: (context, _) {
                return FractionallySizedBox(
                  widthFactor: 1.0 - progress.value,
                  child: Container(color: AppColors.gray200),
                );
              },
            ),
            // Label
            const Center(
              child: Text(
                'Undo',
                style: TextStyle(
                  color: AppColors.gray500,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tactile Chip with Press State ───────────────────────────

class _TactileChip extends StatefulWidget {
  const _TactileChip({
    required this.label,
    required this.onTap,
    required this.delay,
  });

  final String label;
  final VoidCallback onTap;
  final Duration delay;

  @override
  State<_TactileChip> createState() => _TactileChipState();
}

class _TactileChipState extends State<_TactileChip> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: AppDurations.fast,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.base,
            border: Border.all(color: AppColors.gray200),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
        ),
      ),
    ).animate()
        .fadeIn(delay: widget.delay, duration: AppDurations.fast)
        .slideY(
            begin: 0.1,
            delay: widget.delay,
            duration: AppDurations.fast);
  }
}

// ─── Simple Markdown Renderer ──────────────────────────────

/// Renders a lightweight subset of markdown: **bold**, *italic*,
/// bullet lists (- item), and numbered lists (1. item).
class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      // Bullet list
      if (line.trimLeft().startsWith('- ')) {
        final content = line.trimLeft().substring(2);
        children.add(Padding(
          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 7),
                child: Icon(Icons.circle, size: 5, color: AppColors.black),
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildRichLine(content)),
            ],
          ),
        ));
        continue;
      }

      // Numbered list
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line.trimLeft());
      if (numMatch != null) {
        final number = numMatch.group(1)!;
        final content = numMatch.group(2)!;
        children.add(Padding(
          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number.',
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: _buildRichLine(content)),
            ],
          ),
        ));
        continue;
      }

      // Regular line
      children.add(_buildRichLine(line));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildRichLine(String line) {
    return RichText(text: _parseInlineMarkdown(line));
  }

  TextSpan _parseInlineMarkdown(String text) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: _baseStyle,
        ));
      }

      if (match.group(1) != null) {
        // **bold**
        spans.add(TextSpan(
          text: match.group(1),
          style: _baseStyle.copyWith(fontWeight: FontWeight.w700),
        ));
      } else if (match.group(2) != null) {
        // *italic*
        spans.add(TextSpan(
          text: match.group(2),
          style: _baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }
      lastEnd = match.end;
    }

    // Remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: _baseStyle,
      ));
    }

    if (spans.isEmpty) {
      return TextSpan(text: text, style: _baseStyle);
    }

    return TextSpan(children: spans);
  }

  static const _baseStyle = TextStyle(
    color: AppColors.black,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
}

// ─── Typing Indicator ──────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: AppDurations.shimmer,
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: AppRadius.lg,
        ),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i * 0.2;
                final t = ((_anim.value - delay) % 1.0).clamp(0.0, 1.0);
                final opacity = 0.3 + 0.7 * (1 - (2 * t - 1).abs());
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.gray500,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ─── Input Bar ─────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isProcessing,
    required this.hintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isProcessing;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: AppColors.offWhite,
        border: Border(
          top: BorderSide(color: AppColors.gray200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.pill,
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                enabled: !isProcessing,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Circular black send button
          GestureDetector(
            onTap: isProcessing ? null : onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isProcessing
                    ? AppColors.white
                    : AppColors.black,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gray200, width: 1),
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                  size: 20,
                  color: isProcessing
                      ? AppColors.gray500
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

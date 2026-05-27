import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';
import 'package:finance_buddy_app/providers/saraswati_providers.dart';

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

  static const _suggestions = [
    'How much did I spend this month?',
    'What is my top spending category?',
    'Show my spending by category',
    'How does this month compare to last month?',
  ];

  @override
  void dispose() {
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
                      return msg.isUser
                          ? _UserBubble(text: msg.text)
                          : _AssistantBubble(text: msg.text);
                    },
                  )
                : _EmptyState(
                    suggestions: _suggestions,
                    onSuggestionTap: _send,
                  ),
          ),

          // Input area
          _InputBar(
            controller: _controller,
            focusNode: _focusNode,
            onSend: () => _send(),
            isProcessing: isProcessing,
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
    required this.suggestions,
    required this.onSuggestionTap,
  });

  final List<String> suggestions;
  final void Function(String) onSuggestionTap;

  @override
  Widget build(BuildContext context) {
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

          // Title
          const Text(
            "Hi, I'm Saraswati",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Subtitle
          const Text(
            'Ask me anything about your finances\u2009\u2014\u2009spending, trends, categories.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Suggestions label
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SUGGESTIONS',
              style: AppTextStyles.labelM,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Suggestion cards
          ...suggestions.map((s) => Padding(
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
              )),
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
    );
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
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isProcessing;

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
                decoration: const InputDecoration(
                  hintText: 'Ask about your finances...',
                  hintStyle: TextStyle(
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

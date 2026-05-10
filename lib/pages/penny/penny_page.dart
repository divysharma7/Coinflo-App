import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:finance_buddy_app/core/tokens.dart';
import 'package:finance_buddy_app/providers/penny_providers.dart';

/// Ask Penny — an AI chat assistant that answers questions about
/// the user's transaction data.
class PennyPage extends ConsumerStatefulWidget {
  const PennyPage({super.key});

  @override
  ConsumerState<PennyPage> createState() => _PennyPageState();
}

class _PennyPageState extends ConsumerState<PennyPage> {
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

  void _send([String? text]) {
    final msg = text ?? _controller.text.trim();
    if (msg.isEmpty) return;
    _controller.clear();
    ref.read(pennyChatProvider.notifier).send(msg);
    // Scroll to bottom after a frame so new messages are laid out
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: SpendlerMotion.transition,
        curve: SpendlerMotion.surfaceCurve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(pennyChatProvider);
    final isProcessing = ref.watch(pennyProcessingProvider);
    final hasMessages = messages.length > 1; // more than just the welcome message

    // Auto-scroll when new messages arrive
    ref.listen<List<PennyMessage>>(pennyChatProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

    return Scaffold(
      backgroundColor: SpendlerColors.scaffold,
      appBar: AppBar(
        backgroundColor: SpendlerColors.scaffold,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIcons.caretLeft(), color: SpendlerColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ask Penny',
              style: TextStyle(
                color: SpendlerColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${messages.length > 1 ? messages.length - 1 : 0} transactions loaded',
              style: const TextStyle(
                color: SpendlerColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Chat messages or empty state
          Expanded(
            child: hasMessages
                ? ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpendlerSpacing.screenH,
                      vertical: SpendlerSpacing.sm,
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
        horizontal: SpendlerSpacing.screenH,
        vertical: SpendlerSpacing.xl,
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Lightning icon in rounded square
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: SpendlerColors.primary,
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
          const SizedBox(height: SpendlerSpacing.lg),

          // Title
          const Text(
            "Hi, I'm Penny",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: SpendlerColors.textPrimary,
            ),
          ),
          const SizedBox(height: SpendlerSpacing.sm),

          // Subtitle
          const Text(
            'Ask me anything about your finances\u2009\u2014\u2009spending, trends, categories.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: SpendlerColors.textTertiary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: SpendlerSpacing.xl),

          // Suggestions label
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SUGGESTIONS',
              style: SpendlerTextStyles.sectionLabel,
            ),
          ),
          const SizedBox(height: SpendlerSpacing.cardGap),

          // Suggestion cards
          ...suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: SpendlerSpacing.sm),
                child: GestureDetector(
                  onTap: () => onSuggestionTap(s),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpendlerSpacing.md,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: SpendlerColors.surface,
                      borderRadius: BorderRadius.circular(SpendlerRadii.button),
                      border: Border.all(color: SpendlerColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: SpendlerColors.textPrimary,
                            ),
                          ),
                        ),
                        PhosphorIcon(
                          PhosphorIcons.caretRight(),
                          color: SpendlerColors.textTertiary,
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
        top: SpendlerSpacing.xs,
        bottom: SpendlerSpacing.xs,
        left: 64,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpendlerSpacing.md,
            vertical: SpendlerSpacing.cardGap,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF000000),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.zero, // squared corner
            ),
            border: Border.fromBorderSide(
              BorderSide(color: SpendlerColors.border, width: 1),
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
        top: SpendlerSpacing.sm,
        bottom: SpendlerSpacing.sm,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(SpendlerSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(SpendlerRadii.card),
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
                child: Icon(Icons.circle, size: 5, color: Color(0xFF333333)),
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
                  color: Color(0xFF333333),
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
    color: Color(0xFF1A1A1A),
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
      duration: const Duration(milliseconds: 1200),
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
        top: SpendlerSpacing.sm,
        bottom: SpendlerSpacing.sm,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(SpendlerSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(SpendlerRadii.card),
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
                        color: Color(0xFF999999),
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
        left: SpendlerSpacing.screenH,
        right: SpendlerSpacing.screenH,
        top: SpendlerSpacing.sm,
        bottom: SpendlerSpacing.sm + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: SpendlerColors.scaffold,
        border: Border(
          top: BorderSide(color: SpendlerColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: SpendlerColors.surfaceHigh,
                borderRadius: BorderRadius.circular(SpendlerRadii.pill),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(
                  color: SpendlerColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask about your finances...',
                  hintStyle: TextStyle(
                    color: SpendlerColors.textTertiary,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: SpendlerSpacing.md,
                    vertical: SpendlerSpacing.cardGap,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                enabled: !isProcessing,
              ),
            ),
          ),
          const SizedBox(width: SpendlerSpacing.sm),
          // Circular black send button
          GestureDetector(
            onTap: isProcessing ? null : onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isProcessing
                    ? SpendlerColors.surfaceHigh
                    : const Color(0xFF000000),
                shape: BoxShape.circle,
                border: Border.all(color: SpendlerColors.border, width: 1),
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                  size: 20,
                  color: isProcessing
                      ? SpendlerColors.textTertiary
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

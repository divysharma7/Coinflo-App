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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(pennyChatProvider.notifier).send(text);
    // Scroll to bottom after a frame so new messages are laid out
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: PaisaMotion.transition,
        curve: PaisaMotion.surfaceCurve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(pennyChatProvider);
    final isProcessing = ref.watch(pennyProcessingProvider);

    // Auto-scroll when new messages arrive
    ref.listen<List<PennyMessage>>(pennyChatProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

    return Scaffold(
      backgroundColor: PaisaColors.scaffold,
      appBar: AppBar(
        backgroundColor: PaisaColors.scaffold,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIcons.caretLeft(), color: PaisaColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: PaisaColors.yellow,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    color: PaisaColors.scaffold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: PaisaSpacing.sm),
            const Text(
              'Ask Penny',
              style: TextStyle(
                color: PaisaColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: PaisaSpacing.screenH,
                vertical: PaisaSpacing.sm,
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
            ),
          ),

          // Input area
          _InputBar(
            controller: _controller,
            focusNode: _focusNode,
            onSend: _send,
            isProcessing: isProcessing,
          ),
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
        top: PaisaSpacing.xs,
        bottom: PaisaSpacing.xs,
        left: 64,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PaisaSpacing.md,
            vertical: PaisaSpacing.cardGap,
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
              BorderSide(color: PaisaColors.border, width: 1),
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
        top: PaisaSpacing.sm,
        bottom: PaisaSpacing.sm,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(PaisaSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(PaisaRadii.card),
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
        top: PaisaSpacing.sm,
        bottom: PaisaSpacing.sm,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(PaisaSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(PaisaRadii.card),
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
        left: PaisaSpacing.screenH,
        right: PaisaSpacing.screenH,
        top: PaisaSpacing.sm,
        bottom: PaisaSpacing.sm + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: PaisaColors.scaffold,
        border: Border(
          top: BorderSide(color: PaisaColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: PaisaColors.surfaceHigh,
                borderRadius: BorderRadius.circular(PaisaRadii.pill),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(
                  color: PaisaColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask Penny anything...',
                  hintStyle: TextStyle(
                    color: PaisaColors.textTertiary,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: PaisaSpacing.md,
                    vertical: PaisaSpacing.cardGap,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                enabled: !isProcessing,
              ),
            ),
          ),
          const SizedBox(width: PaisaSpacing.sm),
          // Circular black send button
          GestureDetector(
            onTap: isProcessing ? null : onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isProcessing
                    ? PaisaColors.surfaceHigh
                    : const Color(0xFF000000),
                shape: BoxShape.circle,
                border: Border.all(color: PaisaColors.border, width: 1),
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                  size: 20,
                  color: isProcessing
                      ? PaisaColors.textTertiary
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

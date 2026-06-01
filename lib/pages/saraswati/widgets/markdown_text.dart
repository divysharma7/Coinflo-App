import 'package:flutter/material.dart';
import 'package:finance_buddy_app/design_system/design_system.dart';

// ─── Simple Markdown Renderer ──────────────────────────────

/// Renders a lightweight subset of markdown: **bold**, *italic*,
/// bullet lists (- item), and numbered lists (1. item).
class MarkdownText extends StatelessWidget {
  const MarkdownText({super.key, required this.text});
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

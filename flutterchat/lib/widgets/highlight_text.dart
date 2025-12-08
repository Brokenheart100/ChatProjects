import 'package:flutter/material.dart';

class HighlightText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextStyle highlightStyle;

  const HighlightText({
    super.key,
    required this.text,
    required this.style,
    required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    // 正则匹配 <mark>...</mark>
    final RegExp regex = RegExp(r'<mark>(.*?)</mark>');
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return Text(text,
          style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final List<InlineSpan> spans = [];
    int currentIndex = 0;

    for (final match in matches) {
      // 1. 添加高亮前的普通文本
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: style,
        ));
      }

      // 2. 添加高亮文本 (去掉标签)
      spans.add(TextSpan(
        text: match.group(1), // 取出括号里的内容
        style: highlightStyle,
      ));

      currentIndex = match.end;
    }

    // 3. 添加剩余文本
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

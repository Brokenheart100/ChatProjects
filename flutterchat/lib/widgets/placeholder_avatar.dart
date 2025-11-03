import 'package:flutter/material.dart';

// 这是一个可复用的、根据文本生成占位头像的 Widget
class PlaceholderAvatar extends StatelessWidget {
  final String text;
  final double radius;
  final double fontSize;

  const PlaceholderAvatar({
    super.key,
    required this.text,
    this.radius = 22.0, // 默认半径，匹配会话列表
    this.fontSize = 16.0,
  });

  // 这个方法根据输入文本的哈希值生成一个稳定的、独特的颜色
  Color _generateColorFromText(String text) {
    if (text.isEmpty) {
      return Colors.grey;
    }
    // 使用文本的 hashCode 生成颜色，确保同一个名字总显示同一种颜色
    final int hash = text.hashCode;
    final double hue = (hash % 360).toDouble(); // 色相在 0-360 之间
    return HSLColor.fromAHSL(1.0, hue, 0.4, 0.5)
        .toColor(); // 使用 HSL 颜色空间生成更柔和的颜色
  }

  @override
  Widget build(BuildContext context) {
    // 如果文本为空，则显示一个默认的图标
    if (text.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade300,
        child: Icon(Icons.person, size: radius, color: Colors.grey.shade600),
      );
    }

    // 获取文本的第一个字符作为头像文字
    final String firstChar = text.substring(0, 1).toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: _generateColorFromText(text),
      child: Text(
        firstChar,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

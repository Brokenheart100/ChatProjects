import 'package:flutter/material.dart';

/// 一个可复用的、风格统一的自定义搜索输入框组件。
class CustomSearchField extends StatelessWidget {
  /// 提示文字，例如 "搜索" 或 "输入好友ID"。
  final String? hintText;

  /// 当输入框内容改变时的回调函数。
  final ValueChanged<String>? onChanged;

  /// 当用户通过键盘提交（如按回车键）时的回调函数。
  final ValueChanged<String>? onSubmitted;

  /// 输入框的控制器，用于从外部获取或设置输入框的文本。
  final TextEditingController? controller;

  /// 输入框的高度，默认为 32.0。
  final double height;

  /// 构造函数
  const CustomSearchField({
    super.key,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.height = 32.0, // 为高度提供一个默认值
  });

  @override
  Widget build(BuildContext context) {
    // 使用一个固定高度的容器来包裹 TextField，确保其尺寸。
    return SizedBox(
      width: double.infinity,
      height: height,
      child: TextField(
        // 关联外部传入的控制器
        controller: controller,
        // 关联外部传入的回调函数
        onChanged: onChanged,
        onSubmitted: onSubmitted,

        // 统一的文本样式
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),

        // 统一的装饰器（外观）
        decoration: InputDecoration(
          // 使用外部传入的 hintText，如果为 null，则不显示提示
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),

          // 统一的搜索图标
          prefixIcon: const Icon(
            Icons.search,
            size: 16,
            color: Colors.white54,
          ),

          // --- 核心样式，确保背景和边框统一 ---
          filled: true,
          fillColor: const Color(0xFF4A4A4A), // 统一的深灰色背景

          // 移除所有边框线
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0), // 圆角半径，调整为图片风格（约 8-12px）
            borderSide: BorderSide.none, // 无边框线
          ),

          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ), // 内边距调整高度
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide(color: Colors.blue, width: 1.0), // 聚焦时蓝边
          ),

          // --- 核心布局，确保内容垂直居中 ---
          // 移除默认的垂直内边距，让内容更容易居中
          // isDense: true,
        ),
      ),
    );
  }
}

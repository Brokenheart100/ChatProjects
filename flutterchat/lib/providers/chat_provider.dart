import 'package:flutter/material.dart';
import 'package:flutterchat/models/chat_message.dart';

class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  void addMessage(ChatMessage message) {
    _messages.insert(0, message); // 新消息加在最前面
    notifyListeners();
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:image_picker/image_picker.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

// 1. 初始化事件：进入聊天页面，开始加载历史记录，并订阅 MQTT
class ChatStarted extends ChatEvent {}

// 2. 用户发送文本消息事件
class ChatTextMessageSent extends ChatEvent {
  final String text;
  const ChatTextMessageSent(this.text);
}

// 3. 用户发送图片事件 (传递选中的文件)
class ChatImageSent extends ChatEvent {
  final XFile imageFile;
  const ChatImageSent(this.imageFile);
}

// 4. (内部事件) 收到 MQTT 推送的新消息
class ChatNewMessageReceived extends ChatEvent {
  final ChatMessage message;
  const ChatNewMessageReceived(this.message);
}

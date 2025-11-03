import 'package:logger/logger.dart';

// 创建一个全局可访问的 logger 实例
final logger = Logger(
  // PrettyPrinter 提供了丰富多彩、格式优美的日志输出
  printer: PrettyPrinter(
    methodCount: 1, // 每个日志输出中包含的方法调用堆栈深度
    errorMethodCount: 5, // 错误日志的方法调用堆栈深度
    lineLength: 80, // 每行日志的宽度
    colors: true, // 为不同级别的日志启用颜色
    printEmojis: true, // 在日志前面打印表情符号
    printTime: true, // 打印时间戳
  ),
);

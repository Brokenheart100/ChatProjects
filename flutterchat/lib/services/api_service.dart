import 'package:flutterchat/services/api/api_base.dart';
import 'package:flutterchat/services/api/auth_api.dart';
import 'package:flutterchat/services/api/chat_api.dart';
import 'package:flutterchat/services/api/contact_api.dart';
import 'package:flutterchat/services/api/file_api.dart';

// 重新导出 UploadInfo，防止 breaking change
export 'package:flutterchat/services/api/file_api.dart' show UploadInfo;

/// 聚合所有 API 模块
class ApiService extends ApiBase with AuthApi, ChatApi, ContactApi, FileApi {
  // 这里不需要写任何代码了！
  // 它自动拥有了所有 Mixin 的能力。
}

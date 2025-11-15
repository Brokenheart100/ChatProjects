class SavedAccount {
  String username;
  String token; // 用于自动登录
  String? avatarUrl; // MinIO Object Key
  bool autoLoginEnabled;

  SavedAccount({
    required this.username,
    required this.token,
    this.avatarUrl,
    this.autoLoginEnabled = false,
  });

  // 用于将对象转换为可以存储的 Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'token': token,
      'avatarUrl': avatarUrl,
      'autoLoginEnabled': autoLoginEnabled,
    };
  }

  // 用于从 Map (JSON) 创建对象
  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      username: json['username'],
      token: json['token'],
      avatarUrl: json['avatarUrl'],
      autoLoginEnabled: json['autoLoginEnabled'] ?? false,
    );
  }
}

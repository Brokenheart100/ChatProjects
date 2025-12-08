class SavedAccount {
  final String username;
  final String token; // ⚠️ 注意：生产环境建议加密存储
  final String? avatarUrl;
  bool autoLoginEnabled;
  final DateTime lastLoginAt; // ✅ 新增：用于排序

  SavedAccount({
    required this.username,
    required this.token,
    this.avatarUrl,
    this.autoLoginEnabled = false,
    DateTime? lastLoginAt,
  }) : lastLoginAt = lastLoginAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'token': token,
      'avatarUrl': avatarUrl,
      'autoLoginEnabled': autoLoginEnabled,
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      username: json['username'],
      token: json['token'],
      avatarUrl: json['avatarUrl'],
      autoLoginEnabled: json['autoLoginEnabled'] ?? false,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : DateTime.now(),
    );
  }
}

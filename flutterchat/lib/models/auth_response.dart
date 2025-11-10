class AuthResponse {
  final String userId;
  final String username;
  final String email;
  final String token;
  final String? avatarUrl; // 对应后端的 MinIO Object Key

  AuthResponse({
    required this.userId,
    required this.username,
    required this.email,
    required this.token,
    this.avatarUrl,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId'],
      username: json['username'],
      email: json['email'],
      token: json['token'],
      avatarUrl: json['avatarUrl'],
    );
  }
}

import 'dart:convert';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.name,
    required this.email,
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
  });
  final String userId;
  final String name;
  final String email;
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;

  bool get isExpired => !DateTime.now().isBefore(expiresAt);

  String toJson() => jsonEncode({
    'userId': userId,
    'name': name,
    'email': email,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  });

  factory AuthSession.fromJson(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    return AuthSession(
      userId: data['userId'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String?,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
  }
}

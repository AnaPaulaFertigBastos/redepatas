import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'auth_session.dart';
import 'session_store.dart';

/// Contrato esperado da API C#: login/refresh retornam user, accessToken,
/// refreshToken e expiresAt (ISO 8601 UTC).
class ApiAuthService implements AuthService {
  ApiAuthService({
    required this.baseUrl,
    required this.store,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final SessionStore store;
  final http.Client _client;

  Uri _uri(String path) =>
      Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');

  @override
  Future<AuthSession> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await _client.post(
      _uri('/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );
    if (response.statusCode == 409) {
      throw const AuthException(
        'Este e-mail já está cadastrado. Entre com sua conta.',
      );
    }
    if (response.statusCode == 400) {
      throw const AuthException(
        'Confira os dados: nome, e-mail e senha de 8 a 128 caracteres.',
      );
    }
    _requireSuccess(response);
    final session = _sessionFromResponse(response);
    await store.write(session.toJson());
    return session;
  }

  @override
  Future<AuthSession> signIn(String email, String password) async {
    final response = await _client.post(
      _uri('/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 400 || response.statusCode == 401) {
      throw const AuthException('E-mail ou senha inválidos.');
    }
    _requireSuccess(response);
    final session = _sessionFromResponse(response);
    await store.write(session.toJson());
    return session;
  }

  @override
  Future<AuthSession?> restore() async {
    final saved = await store.read();
    if (saved == null) return null;
    AuthSession session;
    try {
      session = AuthSession.fromJson(saved);
    } catch (_) {
      await store.clear();
      return null;
    }

    if (session.isExpired) return _refresh(session.refreshToken);
    final response = await _client.get(
      _uri('/api/auth/me'),
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (response.statusCode == 401) return _refresh(session.refreshToken);
    _requireSuccess(response);
    return session;
  }

  Future<AuthSession?> _refresh(String? refreshToken) async {
    if (refreshToken == null) {
      await store.clear();
      return null;
    }
    final response = await _client.post(
      _uri('/api/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (response.statusCode == 400 || response.statusCode == 401) {
      await store.clear();
      return null;
    }
    _requireSuccess(response);
    final session = _sessionFromResponse(response);
    await store.write(session.toJson());
    return session;
  }

  @override
  Future<void> signOut() async {
    final saved = await store.read();
    try {
      if (saved != null) {
        final session = AuthSession.fromJson(saved);
        if (session.refreshToken != null) {
          await _client.post(
            _uri('/api/auth/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${session.accessToken}',
            },
            body: jsonEncode({'refreshToken': session.refreshToken}),
          );
        }
      }
    } finally {
      await store.clear();
    }
  }

  AuthSession _sessionFromResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final user = body['user'] as Map<String, dynamic>;
    return AuthSession(
      userId: user['id'] as String,
      name: user['name'] as String,
      email: user['email'] as String,
      accessToken: body['accessToken'] as String,
      refreshToken: body['refreshToken'] as String?,
      expiresAt: DateTime.parse(body['expiresAt'] as String),
    );
  }

  void _requireSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        'Falha na autenticação (${response.statusCode}). Tente novamente.',
      );
    }
  }
}

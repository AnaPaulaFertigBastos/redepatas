import 'dart:convert';
import 'dart:math';

import 'auth_session.dart';
import 'session_store.dart';

abstract class AuthService {
  Future<AuthSession?> restore();
  Future<AuthSession> signIn(String email, String password);
  Future<void> signOut();
}

class MockAuthService implements AuthService {
  MockAuthService(this.store);
  final SessionStore store;

  static const demoEmail = 'voluntario@redepatas.app';
  static const demoPassword = '123456';

  @override
  Future<AuthSession?> restore() async {
    final saved = await store.read();
    if (saved == null) return null;
    try {
      final session = AuthSession.fromJson(saved);
      if (session.isExpired ||
          session.userId != 'demo-volunteer' ||
          !session.accessToken.startsWith('demo.')) {
        await store.clear();
        return null;
      }
      return session;
    } catch (_) {
      await store.clear();
      return null;
    }
  }

  @override
  Future<AuthSession> signIn(String email, String password) async {
    if (email.trim().toLowerCase() != demoEmail || password != demoPassword) {
      throw const AuthException(
        'E-mail ou senha inválidos. Use a conta de demonstração.',
      );
    }
    final random = Random.secure();
    final token = base64UrlEncode(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    final session = AuthSession(
      userId: 'demo-volunteer',
      name: 'Voluntária da rede',
      email: demoEmail,
      accessToken: 'demo.$token',
      refreshToken: 'demo-refresh.$token',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
    await store.write(session.toJson());
    return session;
  }

  @override
  Future<void> signOut() => store.clear();
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

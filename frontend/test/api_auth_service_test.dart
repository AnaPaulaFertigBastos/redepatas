import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:redepatas/auth/api_auth_service.dart';
import 'package:redepatas/auth/auth_session.dart';
import 'package:redepatas/auth/auth_service.dart';
import 'package:redepatas/auth/session_store.dart';

void main() {
  test('cadastro envia os dados normalizados e salva a sessão', () async {
    final store = MemorySessionStore();
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/auth/register');
      expect(jsonDecode(request.body), {
        'name': 'Ana',
        'email': 'ana@example.com',
        'password': 'senha1234',
      });
      return http.Response(jsonEncode(_payload('registered')), 201);
    });
    addTearDown(client.close);
    final service = ApiAuthService(
      baseUrl: 'https://example.test/',
      store: store,
      client: client,
    );
    final session = await service.register(
      ' Ana ',
      ' ANA@example.com ',
      'senha1234',
    );
    expect(session.name, 'Ana');
    expect(
      AuthSession.fromJson((await store.read())!).accessToken,
      'registered',
    );
  });

  test('e-mail duplicado e dados inválidos não salvam sessão', () async {
    for (final status in [409, 400]) {
      final store = MemorySessionStore();
      final client = MockClient((_) async => http.Response('{}', status));
      final service = ApiAuthService(
        baseUrl: 'https://example.test',
        store: store,
        client: client,
      );
      await expectLater(
        service.register('Ana', 'ana@example.com', 'senha1234'),
        throwsA(isA<AuthException>()),
      );
      expect(await store.read(), isNull);
      client.close();
    }
  });

  test('login, validação, renovação e logout seguem o contrato HTTP', () async {
    final calls = <String>[];
    final client = MockClient((request) async {
      calls.add('${request.method} ${request.url.path}');
      if (request.url.path == '/api/auth/login') {
        expect(jsonDecode(request.body)['email'], 'ana@example.com');
        return http.Response(jsonEncode(_payload('first')), 200);
      }
      if (request.url.path == '/api/auth/me') {
        expect(request.headers['Authorization'], 'Bearer first');
        return http.Response('{}', 200);
      }
      if (request.url.path == '/api/auth/refresh') {
        expect(jsonDecode(request.body)['refreshToken'], 'refresh-first');
        return http.Response(jsonEncode(_payload('second')), 200);
      }
      if (request.url.path == '/api/auth/logout') {
        expect(jsonDecode(request.body)['refreshToken'], 'refresh-second');
        return http.Response('{}', 204);
      }
      return http.Response('{}', 404);
    });
    final store = MemorySessionStore();
    final service = ApiAuthService(
      baseUrl: 'https://example.test',
      store: store,
      client: client,
    );

    final signedIn = await service.signIn('ana@example.com', 'senha');
    expect(signedIn.accessToken, 'first');
    expect((await service.restore())?.userId, 'u1');

    await store.write(
      AuthSession(
        userId: signedIn.userId,
        name: signedIn.name,
        email: signedIn.email,
        accessToken: signedIn.accessToken,
        refreshToken: signedIn.refreshToken,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ).toJson(),
    );
    expect((await service.restore())?.accessToken, 'second');
    await service.signOut();
    expect(await store.read(), null);
    expect(calls, [
      'POST /api/auth/login',
      'GET /api/auth/me',
      'POST /api/auth/refresh',
      'POST /api/auth/logout',
    ]);
    client.close();
  });
}

Map<String, dynamic> _payload(String token) => {
  'user': {'id': 'u1', 'name': 'Ana', 'email': 'ana@example.com'},
  'accessToken': token,
  'refreshToken': 'refresh-$token',
  'expiresAt': DateTime.now()
      .add(const Duration(hours: 1))
      .toUtc()
      .toIso8601String(),
};

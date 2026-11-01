import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:redepatas/auth/api_auth_service.dart';
import 'package:redepatas/auth/auth_controller.dart';
import 'package:redepatas/auth/session_store.dart';
import 'package:redepatas/ui/login_page.dart';

void main() {
  testWidgets('registre-se valida campos e autentica com a conta criada', (
    tester,
  ) async {
    var calls = 0;
    final client = MockClient((request) async {
        if (request.url.path == '/api/auth/logout') {
          return http.Response('', 204);
        }
      calls++;
      expect(jsonDecode(request.body), {
        'name': 'Ana Silva',
        'email': 'ana@example.com',
        'password': 'senha1234',
      });
      return http.Response(
        jsonEncode({
          'user': {'id': 'u1', 'name': 'Ana Silva', 'email': 'ana@example.com'},
          'accessToken': 'token',
          'refreshToken': 'refresh',
          'expiresAt': DateTime.now()
              .add(const Duration(minutes: 15))
              .toUtc()
              .toIso8601String(),
        }),
        201,
      );
    });
    final auth = AuthController(
      ApiAuthService(
        baseUrl: 'https://example.test',
        store: MemorySessionStore(),
        client: client,
      ),
    );
    addTearDown(auth.dispose);
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(auth: auth, demoMode: false)),
    );
    await tester.ensureVisible(find.text('Não tem uma conta? Registre-se'));
    await tester.tap(find.text('Não tem uma conta? Registre-se'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(
      find.text('Informe seu nome com pelo menos 2 caracteres.'),
      findsOneWidget,
    );
    expect(calls, 0);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ana Silva');
    await tester.enterText(fields.at(1), 'ana@example.com');
    await tester.enterText(fields.at(2), 'senha1234');
    await tester.enterText(fields.at(3), 'diferente');
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('As senhas não coincidem.'), findsOneWidget);
    expect(calls, 0);
    await tester.enterText(fields.at(3), 'senha1234');
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(auth.isSignedIn, true);
    expect(auth.session?.name, 'Ana Silva');
      await auth.signOut();
  });
}

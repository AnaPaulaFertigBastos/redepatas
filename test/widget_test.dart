import 'package:flutter_test/flutter_test.dart';
import 'package:redepatas/app/redepatas_app.dart';
import 'package:redepatas/auth/auth_controller.dart';
import 'package:redepatas/auth/auth_service.dart';
import 'package:redepatas/auth/session_store.dart';

void main() {
  test('sessão mock é restaurada e removida no logout', () async {
    final store = MemorySessionStore();
    final first = AuthController(MockAuthService(store));
    await first.restore();
    expect(first.isSignedIn, false);
    await first.signIn(MockAuthService.demoEmail, MockAuthService.demoPassword);
    expect(first.isSignedIn, true);
    first.dispose();

    final reopened = AuthController(MockAuthService(store));
    await reopened.restore();
    expect(reopened.isSignedIn, true);
    await reopened.signOut();
    expect(reopened.isSignedIn, false);
    expect(await store.read(), null);
    reopened.dispose();
  });

  testWidgets('mostra login e abre o mapa após entrar', (tester) async {
    final auth = AuthController(MockAuthService(MemorySessionStore()));
    addTearDown(auth.dispose);
    await tester.pumpWidget(RedePatasApp(authController: auth));
    await tester.pump();
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    await tester.ensureVisible(find.text('Entrar com conta de demonstração'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar com conta de demonstração'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Cuidar começa por perto.'), findsOneWidget);
    await auth.signOut();
    await tester.pump();
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_service.dart';
import 'common.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth, required this.demoMode});
  final AuthController auth;
  final bool demoMode;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscurePassword = true;
  bool busy = false;
  String? errorMessage;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit({bool demo = false}) async {
    if (!demo && !formKey.currentState!.validate()) return;
    setState(() {
      busy = true;
      errorMessage = null;
    });
    try {
      await widget.auth.signIn(
        demo ? MockAuthService.demoEmail : email.text.trim(),
        demo ? MockAuthService.demoPassword : password.text,
      );
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 174,
                  decoration: BoxDecoration(
                    color: forest,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -28,
                        child: Icon(
                          Icons.pets_rounded,
                          color: Colors.white.withValues(alpha: .08),
                          size: 210,
                        ),
                      ),
                      const Positioned(
                        left: 25,
                        bottom: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.pets_rounded,
                              color: Colors.white,
                              size: 41,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'RedePatas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 29,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Uma rede de cuidado para quem precisa.',
                              style: TextStyle(
                                color: Color(0xFFCAE0D7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Bem-vindo de volta',
                  style: TextStyle(
                    color: ink,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Entre para registrar pontos e acompanhar a rede.',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 25),
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          return text.contains('@') && text.contains('.')
                              ? null
                              : 'Informe um e-mail válido.';
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: password,
                        obscureText: obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => (value?.isNotEmpty ?? false)
                            ? null
                            : 'Informe sua senha.',
                        onFieldSubmitted: (_) {
                          if (!busy) submit();
                        },
                      ),
                    ],
                  ),
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFB44739),
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: busy ? null : submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: forest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                if (widget.demoMode) ...[
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OU TESTE O APP',
                          style: TextStyle(
                            color: muted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => submit(demo: true),
                    icon: const Icon(Icons.pets_rounded),
                    label: const Text('Entrar com conta de demonstração'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: forest,
                      side: const BorderSide(color: Color(0xFFB8D1C2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Protótipo: a conta de demonstração usa dados locais. A autenticação real será feita pela API C#.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 11, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

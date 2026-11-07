import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../data/api_redepatas_repository.dart';
import '../auth/auth_controller.dart';
import '../auth/api_auth_service.dart';
import '../auth/auth_service.dart';
import '../auth/session_store.dart';
import '../ui/home_shell.dart';
import '../ui/login_page.dart';
import '../notifications/push_service.dart';

class RedePatasApp extends StatefulWidget {
  const RedePatasApp({super.key, this.authController, this.push});
  final PushService? push;
  final AuthController? authController;
  @override
  State<RedePatasApp> createState() => _RedePatasAppState();
}

class _RedePatasAppState extends State<RedePatasApp> {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  late final RedePatasRepository repository;
  late final AuthController auth;
  late final bool ownsAuth;
  @override
  void initState() {
    super.initState();
    ownsAuth = widget.authController == null;
    final store = SecureSessionStore();
    auth =
        widget.authController ??
        AuthController(
          apiBaseUrl.isEmpty
              ? MockAuthService(store)
              : ApiAuthService(baseUrl: apiBaseUrl, store: store),
        );
    repository = apiBaseUrl.isEmpty
        ? MockRedePatasRepository()
        : ApiRedePatasRepository(baseUrl: apiBaseUrl, auth: auth);
    auth.addListener(_syncPush);
    auth.restore();
  }

  void _syncPush() {
    if (auth.status != AuthStatus.restoring) {
      widget.push?.syncSession(auth.isSignedIn ? auth.session : null);
    }
  }

  @override
  void dispose() {
    repository.dispose();
    auth.removeListener(_syncPush);
    if (ownsAuth) auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RedePatas',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F8F4),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF174E43),
        primary: const Color(0xFF174E43),
        secondary: const Color(0xFFE9855F),
        surface: Colors.white,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F8F4),
        foregroundColor: Color(0xFF173B35),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F5F1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    ),
    home: AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        if (auth.status == AuthStatus.restoring) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!auth.isSignedIn) {
          return LoginPage(
            auth: auth,
            demoMode: auth.service is MockAuthService,
          );
        }
        return HomeShell(
          key: ValueKey(auth.session!.userId),
          repository: repository,
          auth: auth,
          push: widget.push,
        );
      },
    ),
  );
}

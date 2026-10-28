import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'auth_session.dart';

enum AuthStatus { restoring, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  AuthController(this.service);
  final AuthService service;
  AuthStatus status = AuthStatus.restoring;
  AuthSession? session;
  Timer? _expiryTimer;

  bool get isSignedIn =>
      status == AuthStatus.signedIn && session != null && !session!.isExpired;

  Future<void> restore() async {
    status = AuthStatus.restoring;
    notifyListeners();
    try {
      session = await service.restore();
    } catch (_) {
      session = null;
    }
    status = session == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    _scheduleExpiry();
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    session = await service.signIn(email, password);
    status = AuthStatus.signedIn;
    _scheduleExpiry();
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await service.signOut();
    } finally {
      _expiryTimer?.cancel();
      session = null;
      status = AuthStatus.signedOut;
      notifyListeners();
    }
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final current = session;
    if (current == null) return;
    final remaining = current.expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      restore();
    } else {
      _expiryTimer = Timer(remaining, () async {
        await restore();
      });
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}

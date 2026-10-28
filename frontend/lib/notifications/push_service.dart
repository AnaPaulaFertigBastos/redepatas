// The API contract uses FCM registration tokens for HTTP v1/Admin SDK delivery,
// rather than the newer Firebase Installation ID registration API.
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_session.dart';

/// Mobile FCM client. Sending and scheduling messages belongs to the API.
class PushService extends ChangeNotifier {
  final openedPoint = ValueNotifier<String?>(null);
  final messages = StreamController<RemoteMessage>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool available = false;
  String status = 'Notificações ainda não configuradas.';
  String? _token;
  AuthSession? _session;
  Future<void> _pending = Future.value();
  static const _baseUrl = String.fromEnvironment('API_BASE_URL');

  Future<void> initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      // Uses google-services.json / GoogleService-Info.plist.
      await Firebase.initializeApp();
      available = true;
      status = 'Ative os avisos para receber notificações no celular.';
      _subscriptions.add(FirebaseMessaging.onMessage.listen(messages.add));
      _subscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen(_open));
      _subscriptions.add(
        FirebaseMessaging.instance.onTokenRefresh.listen((token) {
          _token = token;
          unawaited(syncSession(_session));
        }),
      );
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _open(initial);
    } catch (_) {
      available = false;
      status = 'Configure o projeto Firebase para ativar os avisos.';
    }
    notifyListeners();
  }

  void _open(RemoteMessage message) {
    final id = message.data['pointId'];
    if (id is String && id.isNotEmpty) openedPoint.value = id;
  }

  Future<void> enable() async {
    if (!available) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        status = 'Permissão negada. Ative as notificações nas configurações do celular.';
        notifyListeners();
        return;
      }
      // Display foreground messages inside the app, avoiding duplicate iOS alerts.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
      _token = await FirebaseMessaging.instance.getToken();
      if (_token == null) throw StateError('Token indisponível');
      await syncSession(_session);
    } catch (_) {
      status = 'Não foi possível ativar os avisos. Tente novamente.';
      notifyListeners();
    }
  }

  /// Serialize registrations to avoid a stale request overwriting a new session.
  Future<void> syncSession(AuthSession? session) {
    final previous = _session;
    _session = session;
    _pending = _pending.then((_) async {
      try {
        if (!available) return;
        if (session == null) {
          if (previous != null && _token != null && _baseUrl.isNotEmpty) {
            await _request('DELETE', previous, _token!);
          }
          // Invalidates delivery to this installation even without an API.
          await FirebaseMessaging.instance.deleteToken();
          _token = null;
          status = 'Avisos desvinculados deste aparelho.';
        } else {
          final settings = await FirebaseMessaging.instance
              .getNotificationSettings();
          if (settings.authorizationStatus != AuthorizationStatus.authorized &&
              settings.authorizationStatus != AuthorizationStatus.provisional) {
            return;
          }
          _token ??= await FirebaseMessaging.instance.getToken();
          if (_token == null) return;
          if (_baseUrl.isEmpty) {
            status = 'Permissão concedida. Configure a API para receber alertas dos pontos.';
          } else {
            await _request('PUT', session, _token!);
            status = 'Notificações ativadas neste aparelho.';
          }
        }
      } catch (_) {
        status = 'Falha ao sincronizar os avisos. Toque em ativar para tentar novamente.';
        if (session == null) {
          try {
            await FirebaseMessaging.instance.deleteToken();
          } catch (_) {
            /* Retry on next session. */
          }
          _token = null;
        }
      }
      notifyListeners();
    });
    return _pending;
  }

  Future<void> _request(
    String method,
    AuthSession session,
    String token,
  ) async {
    final client = http.Client();
    try {
      final request =
          http.Request(
              method,
              Uri.parse(
                '${_baseUrl.replaceFirst(RegExp(r"/+$"), "")}/api/me/push-devices',
              ),
            )
            ..headers.addAll({
              'Authorization': 'Bearer ${session.accessToken}',
              'Content-Type': 'application/json',
            })
            ..body = jsonEncode({
              'token': token,
              'platform': defaultTargetPlatform.name,
            });
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 15));
      await response.stream.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Cadastro do aparelho recusado');
      }
    } finally {
      client.close();
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(messages.close());
    openedPoint.dispose();
    super.dispose();
  }
}

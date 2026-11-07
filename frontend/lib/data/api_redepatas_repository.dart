import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../auth/auth_controller.dart';
import '../domain/models.dart';
import 'repository.dart';

/// Points are persisted by the API. Animal data remains in the demo repository.
class ApiRedePatasRepository extends MockRedePatasRepository {
  ApiRedePatasRepository({
    required this.baseUrl,
    required this.auth,
    http.Client? client,
  }) : _client = client ?? http.Client() {
    _userId = auth.session?.userId;
    auth.addListener(_sessionChanged);
  }

  final String baseUrl;
  final AuthController auth;
  final http.Client _client;
  List<SupportPoint> _points = [];
  List<MaintenanceRecord> _maintenance = [];
  String? _userId;
  int _generation = 0;
  bool _disposed = false;
  final Set<String> _pending = {};

  @override
  List<MaintenanceRecord> get maintenance => List.unmodifiable(_maintenance);

  void _sessionChanged() {
    final userId = auth.session?.userId;
    if (userId == _userId) return;
    _userId = userId;
    _generation++;
    _points = [];
    _maintenance = [];
    notifyListeners();
  }

  Future<http.Response> _authorized(
    String method,
    String path, {
    Object? body,
  }) async {
    if (auth.session == null || auth.session!.isExpired) await auth.restore();
    final userId = auth.session?.userId;
    Future<http.Response> send() async {
      final session = auth.session;
      if (session == null || session.userId != userId) {
        throw Exception('Sessão expirada. Entre novamente.');
      }
      final request = http.Request(method, _uri(path));
      request.headers['Authorization'] = 'Bearer ${session.accessToken}';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      return http.Response.fromStream(await _client.send(request));
    }

    var response = await send();
    if (response.statusCode == 401) {
      await auth.restore();
      response = await send();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        response.statusCode == 403
            ? 'Você não tem permissão para esta ação.'
            : 'Não foi possível concluir a operação (${response.statusCode}).',
      );
    }
    return response;
  }

  Uri _uri(String path) =>
      Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');

  @override
  List<SupportPoint> get points => List.unmodifiable(_points);

  @override
  Future<void> load() async {
    final generation = ++_generation;
    final response = await _client.get(_uri('/api/pontos'));
    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar pontos.');
    }
    final points = (jsonDecode(response.body) as List<dynamic>)
        .map((e) => _decode(e as Map<String, dynamic>))
        .toList();
    var history = <MaintenanceRecord>[];
    if (auth.isSignedIn) {
      final followed = await _authorized('GET', '/api/me/followed-points');
      final ids = (jsonDecode(followed.body) as List<dynamic>).toSet();
      for (final point in points) {
        point.following = ids.contains(point.id);
      }
      final records = await _authorized('GET', '/api/manutencoes');
      history = (jsonDecode(records.body) as List<dynamic>)
          .map((e) => _decodeMaintenance(e as Map<String, dynamic>))
          .toList();
    }
    if (_disposed || generation != _generation) return;
    _points = points;
    _maintenance = history;
    notifyListeners();
  }

  @override
  Future<void> addPoint(SupportPoint point) async {
    final generation = _generation;
    if (auth.session == null || auth.session!.isExpired) {
      await auth.restore();
    }
    var session = auth.session;
    if (session == null) {
      throw Exception('Entre novamente para cadastrar um ponto.');
    }
    final body = jsonEncode({
      'name': point.name,
      'description': point.description,
      'latitude': point.position.latitude,
      'longitude': point.position.longitude,
      'address': point.address,
      'schedule': point.schedule,
      'maintainer': point.maintainer,
      'animalCount': point.animalCount,
      'resources': point.resources.map((r) => r.name).toList(),
      if (point.photoBytes != null)
        'photoBase64': base64Encode(point.photoBytes!),
    });
    Future<http.Response> send(String token) => _client.post(
      _uri('/api/pontos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    var response = await send(session.accessToken);
    if (response.statusCode == 401) {
      await auth.restore();
      session = auth.session;
      if (session == null) throw Exception('Sessão expirada. Entre novamente.');
      if (_disposed || generation != _generation) return;
      response = await send(session.accessToken);
    }
    if (response.statusCode != 201) {
      String? message;
      try {
        message =
            (jsonDecode(response.body) as Map<String, dynamic>)['message']
                as String?;
      } catch (_) {}
      throw Exception(
        message ?? 'Erro ao cadastrar ponto (${response.statusCode}).',
      );
    }
    if (_disposed || generation != _generation) return;
    _points.insert(
      0,
      _decode(jsonDecode(response.body) as Map<String, dynamic>),
    );
    notifyListeners();
  }

  @override
  Future<void> updateStatus(
    String pointId,
    PointStatus status,
    String action,
  ) async {
    if (!_pending.add('status:$pointId')) return;
    final generation = _generation;
    try {
      final response = await _authorized(
        'POST',
        '/api/pontos/$pointId/maintenance',
        body: {'status': status.name},
      );
      if (_disposed || generation != _generation) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final point = _points.firstWhere((p) => p.id == pointId);
      point.status = PointStatus.values.byName(data['status'] as String);
      point.updatedAt = DateTime.parse(data['updatedAt'] as String);
      _maintenance.insert(
        0,
        _decodeMaintenance(data['maintenance'] as Map<String, dynamic>),
      );
      notifyListeners();
    } finally {
      _pending.remove('status:$pointId');
    }
  }

  @override
  Future<void> toggleFollowing(String pointId) async {
    if (!_pending.add('follow:$pointId')) return;
    final generation = _generation;
    try {
      final point = _points.firstWhere((p) => p.id == pointId);
      final following = !point.following;
      await _authorized(
        following ? 'PUT' : 'DELETE',
        '/api/me/followed-points/$pointId',
      );
      if (_disposed || generation != _generation) return;
      point.following = following;
      notifyListeners();
    } finally {
      _pending.remove('follow:$pointId');
    }
  }

  MaintenanceRecord _decodeMaintenance(Map<String, dynamic> data) =>
      MaintenanceRecord(
        id: data['id'] as String,
        pointId: data['pointId'] as String,
        action: data['action'] as String,
        author: data['author'] as String,
        date: DateTime.parse(data['date'] as String),
      );

  SupportPoint _decode(Map<String, dynamic> data) {
    final photoPath = data['photoUrl'] as String?;
    return SupportPoint(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      position: LatLng(
        (data['latitude'] as num).toDouble(),
        (data['longitude'] as num).toDouble(),
      ),
      resources: (data['resources'] as List<dynamic>)
          .map((e) => Resource.values.byName(e as String))
          .toSet(),
      status: data['status'] == 'ativo'
          ? PointStatus.supplied
          : PointStatus.values.byName(data['status'] as String),
      address: data['address'] as String? ?? '',
      maintainer: data['maintainer'] as String? ?? '',
      schedule: data['schedule'] as String? ?? '',
      animalCount: data['animalCount'] as int,
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      photoUrl: photoPath == null ? null : _uri(photoPath).toString(),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    auth.removeListener(_sessionChanged);
    _client.close();
    super.dispose();
  }
}

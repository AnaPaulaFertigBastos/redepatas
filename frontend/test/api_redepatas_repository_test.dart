import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:redepatas/auth/auth_controller.dart';
import 'package:redepatas/auth/auth_service.dart';
import 'package:redepatas/auth/session_store.dart';
import 'package:redepatas/data/api_redepatas_repository.dart';
import 'package:redepatas/domain/models.dart';

void main() {
  test('acompanhamento e manutenção persistem, falhas não alteram o estado e logout limpa dados', () async {
    final auth = AuthController(MockAuthService(MemorySessionStore()));
    await auth.signIn(MockAuthService.demoEmail, MockAuthService.demoPassword);
    addTearDown(auth.dispose);
    var following = false;
    var status = 'ativo';
    var fail = false;
    final records = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/pontos') {
        return http.Response(
          jsonEncode([
            {
              'id': 'p1',
              'name': 'Praça',
              'description': 'Ponto de apoio',
              'latitude': -25.4,
              'longitude': -49.2,
              'resources': ['water'],
              'status': status,
              'animalCount': 2,
              'updatedAt': '2026-11-06T12:00:00Z',
            },
          ]),
          200,
        );
      }
      expect(request.headers['Authorization'], startsWith('Bearer demo.'));
      if (fail) return http.Response('', 500);
      if (path == '/api/me/followed-points') {
        return http.Response(jsonEncode(following ? ['p1'] : []), 200);
      }
      if (path == '/api/manutencoes') {
        return http.Response(jsonEncode(records), 200);
      }
      if (path.endsWith('/maintenance')) {
        status =
            (jsonDecode(request.body) as Map<String, dynamic>)['status']
                as String;
        records.add({
          'id': 'm1',
          'pointId': 'p1',
          'action': 'Falta água',
          'author': 'Ana',
          'date': '2026-11-06T13:00:00Z',
        });
        return http.Response(
          jsonEncode({
            'status': status,
            'updatedAt': '2026-11-06T13:00:00Z',
            'maintenance': records.single,
          }),
          200,
        );
      }
      following = request.method == 'PUT';
      return http.Response('', 204);
    });
    final repository = ApiRedePatasRepository(
      baseUrl: 'https://example.test',
      auth: auth,
      client: client,
    );
    addTearDown(repository.dispose);
    await repository.load();
    expect(repository.maintenance, isEmpty);
    await repository.toggleFollowing('p1');
    await repository.updateStatus('p1', PointStatus.needsWater, 'ignored');
    await repository.load();
    expect(repository.points.single.following, isTrue);
    expect(repository.points.single.status, PointStatus.needsWater);
    expect(repository.maintenance.single.author, 'Ana');
    fail = true;
    await expectLater(repository.toggleFollowing('p1'), throwsException);
    expect(repository.points.single.following, isTrue);
    await expectLater(
      repository.updateStatus('p1', PointStatus.supplied, ''),
      throwsException,
    );
    expect(repository.points.single.status, PointStatus.needsWater);
    fail = false;
    await repository.toggleFollowing('p1');
    expect(repository.points.single.following, isFalse);
    await auth.signOut();
    expect(repository.points, isEmpty);
    expect(repository.maintenance, isEmpty);
  });
  test(
    'cadastro envia o ponto autenticado e usa o ID gerado pela API',
    () async {
      final auth = AuthController(MockAuthService(MemorySessionStore()));
      await auth.signIn(
        MockAuthService.demoEmail,
        MockAuthService.demoPassword,
      );
      addTearDown(auth.dispose);
      final calls = <String>[];
      final client = MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.method == 'GET') return http.Response('[]', 200);
        expect(request.headers['Authorization'], startsWith('Bearer demo.'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Ponto Central');
        expect(body['resources'], ['water', 'food']);
        expect(body['photoBase64'], base64Encode([1, 2, 3]));
        return http.Response(
          jsonEncode({
            'id': 'server-id',
            'name': body['name'],
            'description': body['description'],
            'latitude': body['latitude'],
            'longitude': body['longitude'],
            'address': body['address'],
            'schedule': body['schedule'],
            'maintainer': body['maintainer'],
            'animalCount': body['animalCount'],
            'resources': body['resources'],
            'status': 'ativo',
            'updatedAt': '2026-11-03T12:00:00Z',
            'photoUrl': '/uploads/pontos/photo.jpg',
          }),
          201,
        );
      });
      final repository = ApiRedePatasRepository(
        baseUrl: 'https://example.test',
        auth: auth,
        client: client,
      );
      addTearDown(repository.dispose);
      await repository.load();
      await repository.addPoint(
        SupportPoint(
          id: 'temporary-id',
          name: 'Ponto Central',
          description: 'Água e ração',
          position: const LatLng(-25.43, -49.27),
          resources: {Resource.water, Resource.food},
          status: PointStatus.supplied,
          address: 'Praça',
          maintainer: 'Comunidade',
          schedule: 'Diário',
          animalCount: 3,
          updatedAt: DateTime.now(),
          photoBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      expect(calls, [
        'GET /api/pontos',
        'GET /api/me/followed-points',
        'GET /api/manutencoes',
        'POST /api/pontos',
      ]);
      expect(repository.points.single.id, 'server-id');
      expect(
        repository.points.single.photoUrl,
        'https://example.test/uploads/pontos/photo.jpg',
      );
    },
  );
}

import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import 'mock/mock_animals.dart';
import 'mock/mock_maintenance.dart';
import 'mock/mock_points.dart';

abstract class RedePatasRepository extends ChangeNotifier {
  List<SupportPoint> get points;
  List<StreetAnimal> get animals;
  List<MaintenanceRecord> get maintenance;
  Future<void> load();
  Future<void> addPoint(SupportPoint point);
  Future<void> addAnimal(StreetAnimal animal);
  Future<void> updateStatus(String pointId, PointStatus status, String action);
  Future<void> toggleFollowing(String pointId);
}

class MockRedePatasRepository extends RedePatasRepository {
  final _points = List<SupportPoint>.of(mockPoints);
  final _animals = List<StreetAnimal>.of(mockAnimals);
  final _maintenance = List<MaintenanceRecord>.of(mockMaintenance);
  @override
  List<SupportPoint> get points => List.unmodifiable(_points);
  @override
  List<StreetAnimal> get animals => List.unmodifiable(_animals);
  @override
  List<MaintenanceRecord> get maintenance => List.unmodifiable(_maintenance);
  @override
  Future<void> load() async {}

  @override
  Future<void> addPoint(SupportPoint point) async {
    _points.insert(0, point);
    notifyListeners();
  }

  @override
  Future<void> addAnimal(StreetAnimal animal) async {
    _animals.insert(0, animal);
    notifyListeners();
  }

  @override
  Future<void> updateStatus(
    String pointId,
    PointStatus status,
    String action,
  ) async {
    final point = _points.firstWhere((p) => p.id == pointId);
    point.status = status;
    point.updatedAt = DateTime.now();
    _maintenance.insert(
      0,
      MaintenanceRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        pointId: pointId,
        action: action,
        author: 'Você',
        date: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  @override
  Future<void> toggleFollowing(String pointId) async {
    final point = _points.firstWhere((p) => p.id == pointId);
    point.following = !point.following;
    notifyListeners();
  }
}

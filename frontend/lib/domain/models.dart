import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

enum Resource { water, food, shelter, other }

extension ResourceLabel on Resource {
  String get label => switch (this) {
    Resource.water => 'Água',
    Resource.food => 'Ração',
    Resource.shelter => 'Abrigo',
    Resource.other => 'Outros',
  };
}

enum PointStatus { supplied, attention, needsWater, needsFood, inactive }

extension PointStatusLabel on PointStatus {
  String get label => switch (this) {
    PointStatus.supplied => 'Abastecido',
    PointStatus.attention => 'Precisa de atenção',
    PointStatus.needsWater => 'Precisa de água',
    PointStatus.needsFood => 'Precisa de ração',
    PointStatus.inactive => 'Inativo',
  };
}

class SupportPoint {
  SupportPoint({
    required this.id,
    required this.name,
    required this.description,
    required this.position,
    required this.resources,
    required this.status,
    required this.address,
    required this.maintainer,
    required this.schedule,
    required this.animalCount,
    required this.updatedAt,
    this.photoUrl,
    this.photoBytes,
    this.following = false,
  });
  final String id, name, description, address, maintainer, schedule;
  final LatLng position;
  final Set<Resource> resources;
  PointStatus status;
  final int animalCount;
  final String? photoUrl;
  final Uint8List? photoBytes;
  bool following;
  DateTime updatedAt;
}

class StreetAnimal {
  StreetAnimal({
    required this.id,
    required this.name,
    required this.description,
    required this.position,
    required this.lastSeen,
    this.photoUrl,
    this.photoBytes,
  });
  final String id, name, description;
  final LatLng position;
  final DateTime lastSeen;
  final String? photoUrl;
  final Uint8List? photoBytes;
}

class MaintenanceRecord {
  MaintenanceRecord({
    required this.id,
    required this.pointId,
    required this.action,
    required this.author,
    required this.date,
  });
  final String id, pointId, action, author;
  final DateTime date;
}

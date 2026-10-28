import '../../domain/models.dart';

final mockMaintenance = <MaintenanceRecord>[
  MaintenanceRecord(
    id: 'm1',
    pointId: 'p1',
    action: 'Água em falta informada',
    author: 'Ana P.',
    date: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  MaintenanceRecord(
    id: 'm2',
    pointId: 'p1',
    action: 'Ração abastecida',
    author: 'Carlos M.',
    date: DateTime.now().subtract(const Duration(days: 1)),
  ),
  MaintenanceRecord(
    id: 'm3',
    pointId: 'p2',
    action: 'Ponto verificado e abastecido',
    author: 'Marina S.',
    date: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  MaintenanceRecord(
    id: 'm4',
    pointId: 'p3',
    action: 'Ração em falta informada',
    author: 'Luiza R.',
    date: DateTime.now().subtract(const Duration(hours: 8)),
  ),
  MaintenanceRecord(
    id: 'm5',
    pointId: 'p4',
    action: 'Abrigo precisa de manutenção',
    author: 'João P.',
    date: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

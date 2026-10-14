import 'package:latlong2/latlong.dart';

import '../../domain/models.dart';

final mockAnimals = <StreetAnimal>[
  StreetAnimal(
    id: 'a1',
    name: 'Caramelo',
    description: 'Cão dócil, costuma ficar perto da praça no fim da tarde.',
    position: const LatLng(-25.4321, -49.2761),
    lastSeen: DateTime.now().subtract(const Duration(hours: 3)),
    photoUrl: 'https://images.unsplash.com/photo-1558788353-f76d92427f16?w=900',
  ),
  StreetAnimal(
    id: 'a2',
    name: 'Luna',
    description: 'Gatinha cinza vista próxima ao Largo da Ordem.',
    position: const LatLng(-25.4278, -49.2702),
    lastSeen: DateTime.now().subtract(const Duration(days: 1)),
    photoUrl:
        'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=900',
  ),
  StreetAnimal(
    id: 'a3',
    name: 'Pretinho',
    description: 'Cão de porte médio; precisa de acompanhamento.',
    position: const LatLng(-25.4260, -49.2655),
    lastSeen: DateTime.now().subtract(const Duration(days: 2)),
    photoUrl: 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=900',
  ),
];

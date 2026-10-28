import 'package:latlong2/latlong.dart';

import '../../domain/models.dart';

// Dados fictícios concentrados em Curitiba para facilitar a demonstração.
final mockPoints = <SupportPoint>[
  SupportPoint(
    id: 'p1',
    name: 'Ponto da Praça Osório',
    description: 'Bebedouro e comedouro ao lado do jardim central.',
    position: const LatLng(-25.4332, -49.2754),
    resources: {Resource.water, Resource.food},
    status: PointStatus.needsWater,
    address: 'Praça Osório · Centro',
    maintainer: 'Rede de voluntários',
    schedule: 'Verificado diariamente',
    animalCount: 5,
    photoUrl:
        'https://images.unsplash.com/photo-1457140072488-019662a8b7cb?w=900',
    following: true,
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  SupportPoint(
    id: 'p2',
    name: 'Abrigo da Rua XV',
    description: 'Casinha protegida da chuva e pote de água.',
    position: const LatLng(-25.4304, -49.2688),
    resources: {Resource.water, Resource.shelter},
    status: PointStatus.supplied,
    address: 'Rua XV de Novembro · Centro',
    maintainer: 'Marina S.',
    schedule: 'Seg, qua e sex',
    animalCount: 3,
    photoUrl: 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=900',
    updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  SupportPoint(
    id: 'p3',
    name: 'Comedouro do Largo',
    description: 'Ponto comunitário próximo ao Largo da Ordem.',
    position: const LatLng(-25.4271, -49.2711),
    resources: {Resource.food, Resource.water},
    status: PointStatus.needsFood,
    address: 'Largo da Ordem · São Francisco',
    maintainer: 'Coletivo Patas',
    schedule: 'Todos os dias',
    animalCount: 7,
    photoUrl:
        'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=900',
    updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
  ),
  SupportPoint(
    id: 'p4',
    name: 'Cantinho do Passeio',
    description: 'Área sombreada com água e abrigo.',
    position: const LatLng(-25.4252, -49.2660),
    resources: {Resource.water, Resource.shelter},
    status: PointStatus.attention,
    address: 'Passeio Público · Centro',
    maintainer: 'João P.',
    schedule: 'Fim de semana',
    animalCount: 4,
    photoUrl:
        'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=900',
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  SupportPoint(
    id: 'p5',
    name: 'Ponto do Batel',
    description: 'Comedouro mantido pelos moradores.',
    position: const LatLng(-25.4419, -49.2829),
    resources: {Resource.food, Resource.water},
    status: PointStatus.supplied,
    address: 'Rua Bispo Dom José · Batel',
    maintainer: 'Moradores do bairro',
    schedule: 'Diariamente',
    animalCount: 2,
    photoUrl:
        'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=900',
    updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
  ),
];

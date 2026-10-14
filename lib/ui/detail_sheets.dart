import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../data/repository.dart';
import '../domain/models.dart';
import 'common.dart';

void showPointDetails(
  BuildContext context,
  RedePatasRepository repository,
  SupportPoint point,
  LatLng origin,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: .83,
      minChildSize: .4,
      maxChildSize: .95,
      expand: false,
      builder: (context, controller) => AnimatedBuilder(
        animation: repository,
        builder: (context, _) => Container(
          decoration: const BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCAD8CF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SizedBox(
                  height: 190,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      photo(
                        url: point.photoUrl,
                        bytes: point.photoBytes,
                        width: double.infinity,
                        height: 190,
                        radius: BorderRadius.circular(20),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(
                              point.following
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_outline_rounded,
                              color: forest,
                              size: 21,
                            ),
                            onPressed: () async {
                              try {
                                await repository.toggleFollowing(point.id);
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Não foi possível acompanhar o ponto: $error',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 17, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        point.name,
                        style: const TextStyle(
                          color: ink,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusPill(point.status, compact: true),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined, color: muted, size: 17),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        point.address,
                        style: const TextStyle(color: muted, fontSize: 13),
                      ),
                    ),
                    Text(
                      distanceLabel(origin, point.position),
                      style: const TextStyle(
                        color: forest,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  point.description,
                  style: const TextStyle(color: ink, height: 1.4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: point.resources
                      .map(
                        (resource) => Chip(
                          avatar: Icon(
                            resourceIcon(resource),
                            color: forest,
                            size: 18,
                          ),
                          label: Text(resource.label),
                          backgroundColor: paleGreen,
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Column(
                      children: [
                        _info(
                          Icons.calendar_today_rounded,
                          'Abastecimento',
                          point.schedule,
                        ),
                        const Divider(height: 20),
                        _info(
                          Icons.handshake_outlined,
                          'Responsável',
                          point.maintainer,
                        ),
                        const Divider(height: 20),
                        _info(
                          Icons.pets_rounded,
                          'Animais atendidos',
                          '${point.animalCount} aproximadamente',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 25, 20, 6),
                child: Text(
                  'Atualizar situação',
                  style: TextStyle(
                    color: ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Visitou este ponto? Sua informação ajuda outras pessoas.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 13, 20, 0),
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _statusAction(
                      context,
                      repository,
                      point,
                      'Abasteci / verifiquei',
                      PointStatus.supplied,
                      Icons.check_circle_outline_rounded,
                    ),
                    _statusAction(
                      context,
                      repository,
                      point,
                      'Falta água',
                      PointStatus.needsWater,
                      Icons.water_drop_outlined,
                    ),
                    _statusAction(
                      context,
                      repository,
                      point,
                      'Falta ração',
                      PointStatus.needsFood,
                      Icons.restaurant_outlined,
                    ),
                    _statusAction(
                      context,
                      repository,
                      point,
                      'Precisa de manutenção',
                      PointStatus.attention,
                      Icons.build_outlined,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 26, 20, 8),
                child: Text(
                  'Histórico do ponto',
                  style: TextStyle(
                    color: ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ...repository.maintenance
                  .where((r) => r.pointId == point.id)
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.history_rounded,
                            color: forest,
                          ),
                          title: Text(
                            r.action,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${r.author} · ${relativeTime(r.date)}',
                            style: const TextStyle(color: muted, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _info(IconData icon, String title, String value) => Row(
  children: [
    Icon(icon, color: forest, size: 20),
    const SizedBox(width: 12),
    Expanded(
      child: Text(title, style: const TextStyle(color: muted, fontSize: 13)),
    ),
    Flexible(
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  ],
);
Widget _statusAction(
  BuildContext context,
  RedePatasRepository repository,
  SupportPoint point,
  String text,
  PointStatus status,
  IconData icon,
) => ActionChip(
  avatar: Icon(icon, color: statusColor(status), size: 18),
  label: Text(text, style: const TextStyle(fontSize: 12)),
  onPressed: () async {
    try {
      await repository.updateStatus(point.id, status, text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atualização registrada no histórico.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível atualizar o ponto: $error')),
        );
      }
    }
  },
  backgroundColor: Colors.white,
  side: const BorderSide(color: Color(0xFFE5EBE5)),
);

void showAnimalDetails(
  BuildContext context,
  StreetAnimal animal,
  LatLng origin,
) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: cream,
  builder: (context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          photo(
            url: animal.photoUrl,
            bytes: animal.photoBytes,
            width: double.infinity,
            height: 230,
            radius: BorderRadius.circular(22),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.pets_rounded, color: peach),
              const SizedBox(width: 7),
              Text(
                animal.name,
                style: const TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 23,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            animal.description,
            style: const TextStyle(color: ink, height: 1.4),
          ),
          const SizedBox(height: 14),
          Text(
            'Visto ${relativeTime(animal.lastSeen)} · ${distanceLabel(origin, animal.position)} de distância',
            style: const TextStyle(color: muted),
          ),
        ],
      ),
    ),
  ),
);

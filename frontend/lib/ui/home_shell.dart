import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../auth/auth_controller.dart';
import '../data/repository.dart';
import '../data/map_config.dart';
import '../domain/models.dart';
import 'common.dart';
import 'detail_sheets.dart';
import 'entry_sheet.dart';
import '../notifications/push_service.dart';

const demoCenter = LatLng(-25.4304, -49.2713);

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.repository,
    required this.auth,
    this.push,
  });
  final PushService? push;
  final RedePatasRepository repository;
  final AuthController auth;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  Resource? filter;
  bool showAnimals = true;
  LatLng? currentLocation;
  final mapController = MapController();
  bool alertsNearby = true;
  bool alertsFollowing = true;
  double alertRadiusKm = 5;
  StreamSubscription<dynamic>? _pushMessages;

  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_refresh);
    widget.push?.addListener(_refresh);
    widget.push?.openedPoint.addListener(_openPushPoint);
    _pushMessages = widget.push?.messages.stream.listen((message) {
      if (!mounted) return;
      final id = message.data['pointId'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.notification?.body ?? 'Há uma atualização em um ponto.',
          ),
          action: id is String
              ? SnackBarAction(
                  label: 'Ver ponto',
                  onPressed: () {
                    widget.push?.openedPoint.value = id;
                  },
                )
              : null,
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPushPoint());
  }

  @override
  void dispose() {
    widget.repository.removeListener(_refresh);
    widget.push?.removeListener(_refresh);
    widget.push?.openedPoint.removeListener(_openPushPoint);
    _pushMessages?.cancel();
    mapController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _openPushPoint() {
    if (!mounted) return;
    final id = widget.push?.openedPoint.value;
    if (id == null) return;
    widget.push?.openedPoint.value = null;
    final matches = widget.repository.points.where((point) => point.id == id);
    if (matches.isNotEmpty) {
      openPoint(matches.first);
    } else {
      setState(() => tab = 2);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este ponto não está disponível nos dados carregados.'),
        ),
      );
    }
  }

  LatLng get origin => currentLocation ?? demoCenter;
  List<SupportPoint> get visiblePoints =>
      widget.repository.points
          .where(
            (p) =>
                p.status != PointStatus.inactive &&
                (filter == null || p.resources.contains(filter)),
          )
          .toList()
        ..sort(
          (a, b) => const Distance()
              .as(LengthUnit.Meter, origin, a.position)
              .compareTo(
                const Distance().as(LengthUnit.Meter, origin, b.position),
              ),
        );

  Future<void> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Ative o GPS para ver sua localização.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização não concedida.');
      }
      final position = await Geolocator.getCurrentPosition();
      final here = LatLng(position.latitude, position.longitude);
      setState(() => currentLocation = here);
      if (tab == 0) mapController.move(here, 14);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  void openPoint(SupportPoint point) =>
      showPointDetails(context, widget.repository, point, origin);
  void openAnimal(StreetAnimal animal) =>
      showAnimalDetails(context, animal, origin);
  void createEntry() => showEntrySheet(context, widget.repository, origin);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(
        index: tab,
        children: [_mapPage(), _explorePage(), _alertsPage(), _communityPage()],
      ),
    ),
    floatingActionButton: tab == 0 || tab == 1
        ? FloatingActionButton.extended(
            onPressed: createEntry,
            backgroundColor: peach,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Adicionar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        : null,
    bottomNavigationBar: NavigationBar(
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: paleGreen,
      selectedIndex: tab,
      onDestinationSelected: (index) => setState(() => tab = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map_rounded),
          label: 'Mapa',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore_rounded),
          label: 'Explorar',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_none_rounded),
          selectedIcon: Icon(Icons.notifications_rounded),
          label: 'Alertas',
        ),
        NavigationDestination(
          icon: Icon(Icons.pets_outlined),
          selectedIcon: Icon(Icons.pets_rounded),
          label: 'Comunidade',
        ),
      ],
    ),
  );

  Widget _heading(String subtitle) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: forest,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.pets_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RedePatas',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: ink,
                letterSpacing: -.6,
              ),
            ),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: muted)),
          ],
        ),
        const Spacer(),
        IconButton.filledTonal(
          onPressed: locate,
          tooltip: 'Usar minha localização',
          style: IconButton.styleFrom(
            backgroundColor: paleGreen,
            foregroundColor: forest,
          ),
          icon: const Icon(Icons.my_location_rounded),
        ),
      ],
    ),
  );

  Widget _mapPage() => Column(
    children: [
      _heading(
        currentLocation == null
            ? 'Curitiba, PR · localização de exemplo'
            : 'Pontos próximos de você',
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 13),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Cuidar começa por perto.',
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
            Text(
              '${visiblePoints.length} pontos',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      ),
      SizedBox(
        height: 45,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _filterChip('Todos', null, Icons.grid_view_rounded),
            _filterChip('Água', Resource.water, Icons.water_drop_rounded),
            _filterChip('Ração', Resource.food, Icons.restaurant_rounded),
            _filterChip('Abrigo', Resource.shelter, Icons.home_rounded),
            const SizedBox(width: 4),
            FilterChip(
              label: const Text('Animais'),
              avatar: Icon(
                Icons.pets_rounded,
                size: 17,
                color: showAnimals ? forest : muted,
              ),
              selected: showAnimals,
              onSelected: (v) => setState(() => showAnimals = v),
              showCheckmark: false,
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: FlutterMap(
                mapController: mapController,
                options: const MapOptions(
                  initialCenter: demoCenter,
                  initialZoom: 13.8,
                  minZoom: 4,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate: mapTileUrl,
                    userAgentPackageName: mapUserAgent,
                  ),
                  if (currentLocation != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: currentLocation!,
                          radius: 13,
                          color: const Color(0x444A9CD5),
                          borderColor: Colors.white,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      ...visiblePoints.map(
                        (p) => Marker(
                          point: p.position,
                          width: 52,
                          height: 64,
                          child: GestureDetector(
                            onTap: () => openPoint(p),
                            child: _mapPin(p),
                          ),
                        ),
                      ),
                      if (showAnimals)
                        ...widget.repository.animals.map(
                          (a) => Marker(
                            point: a.position,
                            width: 44,
                            height: 50,
                            child: GestureDetector(
                              onTap: () => openAnimal(a),
                              child: _animalPin(),
                            ),
                          ),
                        ),
                      if (currentLocation != null)
                        Marker(
                          point: currentLocation!,
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF398CCC),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 14,
              right: 16,
              child: Column(
                children: [
                  _mapButton(
                    Icons.add,
                    () => mapController.move(
                      mapController.camera.center,
                      mapController.camera.zoom + 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _mapButton(
                    Icons.remove,
                    () => mapController.move(
                      mapController.camera.center,
                      mapController.camera.zoom - 1,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(left: 16, right: 16, bottom: 16, child: _mapPreview()),
          ],
        ),
      ),
    ],
  );

  Widget _filterChip(String title, Resource? value, IconData icon) {
    final selected = filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(title),
        avatar: Icon(icon, size: 17, color: selected ? Colors.white : forest),
        selected: selected,
        onSelected: (_) => setState(() => filter = value),
        selectedColor: forest,
        labelStyle: TextStyle(
          color: selected ? Colors.white : forest,
          fontWeight: FontWeight.w600,
        ),
        showCheckmark: false,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? forest : const Color(0xFFE2E9E3)),
      ),
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(13),
    elevation: 2,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: SizedBox(width: 40, height: 40, child: Icon(icon, color: forest)),
    ),
  );
  Widget _mapPin(SupportPoint p) => Column(
    children: [
      Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: statusColor(p.status),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 9,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          p.resources.contains(Resource.water)
              ? Icons.water_drop_rounded
              : p.resources.contains(Resource.food)
              ? Icons.restaurant_rounded
              : Icons.home_rounded,
          color: Colors.white,
          size: 23,
        ),
      ),
      Icon(
        Icons.arrow_drop_down_rounded,
        color: statusColor(p.status),
        size: 18,
      ),
    ],
  );
  Widget _animalPin() => Column(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: peach,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 7)],
        ),
        child: const Icon(Icons.pets_rounded, color: Colors.white, size: 18),
      ),
      const Icon(Icons.arrow_drop_down_rounded, color: peach, size: 14),
    ],
  );
  Widget _mapPreview() {
    if (visiblePoints.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Nenhum ponto com este filtro.',
            style: TextStyle(color: muted),
          ),
        ),
      );
    }
    final point = visiblePoints.first;
    return Card(
      elevation: 5,
      shadowColor: Colors.black12,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => openPoint(point),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              photo(
                url: point.photoUrl,
                bytes: point.photoBytes,
                width: 76,
                height: 75,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PONTO MAIS PRÓXIMO · ${distanceLabel(origin, point.position)}',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      point.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ink,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    StatusPill(point.status, compact: true),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: forest),
            ],
          ),
        ),
      ),
    );
  }

  Widget _explorePage() => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heading('Descubra onde sua ajuda faz diferença'),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Explore a rede',
                style: TextStyle(
                  color: ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${widget.repository.points.length} pontos de apoio e ${widget.repository.animals.length} animais registrados em Curitiba.',
                style: const TextStyle(color: muted),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _filterChip('Todos', null, Icons.grid_view_rounded),
                  _filterChip('Água', Resource.water, Icons.water_drop_rounded),
                  _filterChip('Ração', Resource.food, Icons.restaurant_rounded),
                  _filterChip('Abrigo', Resource.shelter, Icons.home_rounded),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
              child: Text(
                'Pontos de apoio',
                style: TextStyle(
                  color: ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
      SliverList.builder(
        itemCount: visiblePoints.length,
        itemBuilder: (context, index) => _pointListCard(visiblePoints[index]),
      ),
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: Text(
                'Animais avistados',
                style: TextStyle(
                  color: ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ...widget.repository.animals.map(_animalListCard),
            const SizedBox(height: 85),
          ],
        ),
      ),
    ],
  );
  Widget _pointListCard(SupportPoint point) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    child: Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => openPoint(point),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              photo(
                url: point.photoUrl,
                bytes: point.photoBytes,
                width: 88,
                height: 88,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.name,
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${point.address} · ${distanceLabel(origin, point.position)}',
                      style: const TextStyle(color: muted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    StatusPill(point.status, compact: true),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _animalListCard(StreetAnimal animal) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    child: Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => openAnimal(animal),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              photo(
                url: animal.photoUrl,
                bytes: animal.photoBytes,
                width: 72,
                height: 72,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.name,
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Visto ${relativeTime(animal.lastSeen)} · ${distanceLabel(origin, animal.position)}',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _alertsPage() {
    final alerts = widget.repository.points
        .where(
          (p) =>
              p.status != PointStatus.supplied &&
              p.status != PointStatus.inactive &&
              (alertsNearby &&
                      const Distance().as(
                            LengthUnit.Kilometer,
                            origin,
                            p.position,
                          ) <=
                          alertRadiusKm ||
                  alertsFollowing && p.following),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        _heading('Saiba onde você pode ajudar'),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 5),
          child: Text(
            'Alertas da rede',
            style: TextStyle(
              color: ink,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '${alerts.length} pontos precisam de atenção na sua área.',
            style: const TextStyle(color: muted),
          ),
        ),
        const SizedBox(height: 20),
        ...alerts.map(
          (p) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Card(
              child: InkWell(
                onTap: () => openPoint(p),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: statusColor(p.status).withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          p.status == PointStatus.needsWater
                              ? Icons.water_drop_rounded
                              : p.status == PointStatus.needsFood
                              ? Icons.restaurant_rounded
                              : Icons.build_rounded,
                          color: statusColor(p.status),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.status.label,
                              style: const TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(p.name, style: const TextStyle(color: ink)),
                            const SizedBox(height: 5),
                            Text(
                              '${distanceLabel(origin, p.position)} · atualizado ${relativeTime(p.updatedAt)}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: muted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (alerts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Nenhum alerta com as preferências atuais.'),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Text(
            'Preferências de alerta',
            style: TextStyle(
              color: ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Pontos próximos'),
                  subtitle: const Text('Avisos conforme o raio definido'),
                  value: alertsNearby,
                  onChanged: (v) => setState(() => alertsNearby = v),
                ),
                const Divider(height: 1, indent: 17, endIndent: 17),
                SwitchListTile(
                  title: const Text('Pontos acompanhados'),
                  subtitle: const Text('Avisos dos pontos que você segue'),
                  value: alertsFollowing,
                  onChanged: (v) => setState(() => alertsFollowing = v),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      const Text('Raio de interesse'),
                      const Spacer(),
                      Text(
                        '${alertRadiusKm.round()} km',
                        style: const TextStyle(
                          color: forest,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Slider(
                  value: alertRadiusKm,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  onChanged: (v) => setState(() => alertRadiusKm = v),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Column(
            children: [
              Text(
                widget.push?.status ?? 'Notificações ainda não configuradas.',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              TextButton.icon(
                onPressed: widget.push?.available == true
                    ? widget.push!.enable
                    : null,
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Ativar notificações no celular'),
              ),
              const Text(
                'Raio e pontos acompanhados acima filtram os alertas dentro do app. '
                'Os avisos push dependem das preferências salvas no servidor.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _communityPage() {
    final records = widget.repository.maintenance;
    final grouped = <String, int>{};
    for (final a in widget.repository.animals) {
      final key = a.position.longitude < -49.272
          ? 'Centro / Praça Osório'
          : 'Centro / Largo da Ordem';
      grouped[key] = (grouped[key] ?? 0) + 1;
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 35),
      children: [
        _heading('Pequenas ações, grande impacto'),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Text(
            'Nossa comunidade',
            style: TextStyle(
              color: ink,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Juntos, mantemos a rede de cuidado ativa.',
            style: TextStyle(color: muted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: paleGreen,
                    child: Icon(Icons.person_rounded, color: forest),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.auth.session?.name ?? '',
                          style: const TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.auth.session?.email ?? '',
                          style: const TextStyle(color: muted, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await widget.push?.syncSession(null);
                        await widget.auth.signOut();
                      } catch (error) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Não foi possível sair: $error'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Sair'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: _metric(
                  '${widget.repository.points.length}',
                  'pontos ativos',
                  Icons.place_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metric(
                  '${widget.repository.animals.length}',
                  'animais vistos',
                  Icons.pets_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metric(
                  '${records.length}',
                  'ações',
                  Icons.favorite_rounded,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            'Onde há mais avistamentos',
            style: TextStyle(
              color: ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ...grouped.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFE9DF),
                  child: Icon(Icons.pets_rounded, color: peach),
                ),
                title: Text(e.key),
                subtitle: const Text('Região com registros da comunidade'),
                trailing: Text(
                  '${e.value}',
                  style: const TextStyle(
                    color: forest,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
          child: Text(
            'Histórico de cuidado',
            style: TextStyle(
              color: ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ...records.map((r) {
          final point = widget.repository.points
              .where((p) => p.id == r.pointId)
              .firstOrNull;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: paleGreen,
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: forest,
                    size: 19,
                  ),
                ),
                title: Text(
                  r.action,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text('${point?.name ?? 'Ponto'} · ${r.author}'),
                trailing: Text(
                  relativeTime(r.date),
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _metric(String number, String label, IconData icon) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 17),
      child: Column(
        children: [
          Icon(icon, color: forest, size: 24),
          const SizedBox(height: 7),
          Text(
            number,
            style: const TextStyle(
              color: ink,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

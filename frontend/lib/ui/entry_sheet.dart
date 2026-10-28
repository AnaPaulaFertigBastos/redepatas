import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../data/repository.dart';
import '../data/map_config.dart';
import '../domain/models.dart';
import 'common.dart';

void showEntrySheet(
  BuildContext context,
  RedePatasRepository repository,
  LatLng initialPosition,
) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: cream,
  useSafeArea: true,
  builder: (context) =>
      EntrySheet(repository: repository, initialPosition: initialPosition),
);

class EntrySheet extends StatefulWidget {
  const EntrySheet({
    super.key,
    required this.repository,
    required this.initialPosition,
  });
  final RedePatasRepository repository;
  final LatLng initialPosition;
  @override
  State<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<EntrySheet> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final description = TextEditingController();
  final address = TextEditingController();
  final maintainer = TextEditingController();
  final schedule = TextEditingController();
  final count = TextEditingController();
  final mapController = MapController();
  late LatLng position = widget.initialPosition;
  Uint8List? photoBytes;
  bool isAnimal = false;
  final resources = <Resource>{Resource.water};

  @override
  void dispose() {
    for (final c in [name, description, address, maintainer, schedule, count]) {
      c.dispose();
    }
    mapController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1400,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => photoBytes = bytes);
    }
  }

  Future<void> useGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Ative o GPS.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização não concedida.');
      }
      final p = await Geolocator.getCurrentPosition();
      setState(() => position = LatLng(p.latitude, p.longitude));
      mapController.move(position, 15);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    if (!isAnimal && resources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um recurso.')),
      );
      return;
    }
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    try {
      if (isAnimal) {
        await widget.repository.addAnimal(
          StreetAnimal(
            id: id,
            name: name.text.trim(),
            description: description.text.trim(),
            position: position,
            lastSeen: DateTime.now(),
            photoBytes: photoBytes,
          ),
        );
      } else {
        await widget.repository.addPoint(
          SupportPoint(
            id: id,
            name: name.text.trim(),
            description: description.text.trim(),
            position: position,
            resources: Set.of(resources),
            status: PointStatus.supplied,
            address: address.text.trim().isEmpty
                ? 'Local informado pela comunidade'
                : address.text.trim(),
            maintainer: maintainer.text.trim().isEmpty
                ? 'Comunidade'
                : maintainer.text.trim(),
            schedule: schedule.text.trim().isEmpty
                ? 'A combinar'
                : schedule.text.trim(),
            animalCount: int.tryParse(count.text) ?? 0,
            updatedAt: DateTime.now(),
            photoBytes: photoBytes,
          ),
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isAnimal
                ? 'Animal registrado no mapa.'
                : 'Ponto de apoio cadastrado.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .95,
    child: Column(
      children: [
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFCAD8CF),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Novo registro',
                      style: TextStyle(
                        color: ink,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      isAnimal
                          ? 'Conte sobre um animal avistado'
                          : 'Ajude a ampliar nossa rede',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.place_rounded),
                      label: Text('Ponto de apoio'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.pets_rounded),
                      label: Text('Animal'),
                    ),
                  ],
                  selected: {isAnimal},
                  onSelectionChanged: (v) => setState(() => isAnimal = v.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: isAnimal
                        ? 'Nome ou identificação *'
                        : 'Nome do ponto *',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Informe um nome.' : null,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: description,
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isAnimal
                        ? 'Descrição do animal *'
                        : 'Descrição do local *',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Informe uma descrição.'
                      : null,
                ),
                if (!isAnimal) ...[
                  const SizedBox(height: 11),
                  TextFormField(
                    controller: address,
                    decoration: const InputDecoration(
                      labelText: 'Referência ou endereço',
                    ),
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    'O que este ponto oferece?',
                    style: TextStyle(color: ink, fontWeight: FontWeight.w800),
                  ),
                  Wrap(
                    spacing: 7,
                    children: Resource.values
                        .map(
                          (r) => FilterChip(
                            label: Text(r.label),
                            avatar: Icon(resourceIcon(r), size: 17),
                            selected: resources.contains(r),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                resources.add(r);
                              } else {
                                resources.remove(r);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: schedule,
                    decoration: const InputDecoration(
                      labelText: 'Frequência / horário de abastecimento',
                    ),
                  ),
                  const SizedBox(height: 11),
                  TextFormField(
                    controller: maintainer,
                    decoration: const InputDecoration(
                      labelText: 'Quem mantém o ponto?',
                    ),
                  ),
                  const SizedBox(height: 11),
                  TextFormField(
                    controller: count,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade aproximada de animais',
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const Text(
                  'Foto',
                  style: TextStyle(color: ink, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: pickImage,
                  borderRadius: BorderRadius.circular(17),
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: paleGreen,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: photoBytes == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: forest),
                              SizedBox(height: 6),
                              Text(
                                'Toque para escolher uma foto',
                                style: TextStyle(color: forest, fontSize: 12),
                              ),
                            ],
                          )
                        : photo(
                            bytes: photoBytes,
                            width: double.infinity,
                            height: 110,
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Localização no mapa',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: useGps,
                      icon: const Icon(Icons.my_location_rounded, size: 17),
                      label: const Text('Usar GPS'),
                    ),
                  ],
                ),
                const Text(
                  'Toque no mapa para ajustar o marcador.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: position,
                        initialZoom: 14,
                        onTap: (_, p) => setState(() => position = p),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: mapTileUrl,
                          userAgentPackageName: mapUserAgent,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: position,
                              width: 42,
                              height: 42,
                              child: const Icon(
                                Icons.location_pin,
                                color: peach,
                                size: 40,
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
                ),
                const SizedBox(height: 9),
                Text(
                  '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.check_rounded),
              label: Text(isAnimal ? 'Registrar animal' : 'Cadastrar ponto'),
              style: FilledButton.styleFrom(
                backgroundColor: forest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

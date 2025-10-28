import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/area_feature.dart';
import '../../models/rating.dart';
import '../../utils/price_color.dart';
import '../../utils/geo.dart';
import 'map_controller.dart';
import 'widgets/legend.dart';
import 'widgets/mode_toggle.dart';
import 'widgets/add_rating_sheet.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});
  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _controller;
  LatLng get _center => const LatLng(-26.485, -49.066);

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(modeProvider);
    final areasAsync = ref.watch(areasProvider);
    final legendVisible = ref.watch(legendVisibleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rate Living – Mapa')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'legendFab',
            onPressed: () {
              final current = ref.read(legendVisibleProvider);
              ref.read(legendVisibleProvider.notifier).state = !current;
            },
            icon: Icon(legendVisible ? Icons.visibility_off : Icons.visibility),
            label: Text(legendVisible ? 'Ocultar legenda' : 'Mostrar legenda'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'hintFab',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Dica: pressione e segure no mapa para adicionar uma avaliação.',
                  ),
                ),
              );
            },
            child: const Icon(Icons.touch_app),
          ),
        ],
      ),
      body: Stack(
        children: [
          areasAsync.when(
            data: (areas) => GoogleMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: 12),
              onMapCreated: (c) => _controller = c,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              polygons: _buildPolygons(areas, mode),
              markers: _buildMarkers(areas),
              onLongPress: (pos) => _onLongPressAddRating(context, areas, pos),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Erro: $e')),
          ),

          Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: [
                ModeToggle(
                  value: mode,
                  onChanged: (m) => ref.read(modeProvider.notifier).state = m,
                ),
                const SizedBox(width: 12),
                if (legendVisible) Legend(mode: mode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Set<Polygon> _buildPolygons(List<AreaFeature> areas, Mode mode) {
    final legendVisible = ref.watch(legendVisibleProvider);
    final set = <Polygon>{};
    for (final a in areas) {
      final price = mode == Mode.rent ? a.avgRent : a.avgBuy;
      final color = priceToColor(mode, price);
      final path = a.polygon.map((p) => LatLng(p[0], p[1])).toList();
      if (legendVisible) {
        set.add(
          Polygon(
            polygonId: PolygonId(a.id),
            points: path,
            strokeColor: const Color(0xFF111827),
            strokeWidth: 1,
            fillColor: Color(color).withOpacity(0.55),
            consumeTapEvents: true,
            onTap: () => _showAreaInfo(a, mode),
          ),
        );
      }
    }
    return set;
  }

  Set<Marker> _buildMarkers(List<AreaFeature> areas) {
    final markers = <Marker>{};
    for (final a in areas) {
      for (final r in a.ratings) {
        markers.add(
          Marker(
            markerId: MarkerId(r.id),
            position: LatLng(r.lat, r.lng),
            infoWindow: InfoWindow(
              title: '⭐' * r.score + '☆' * (5 - r.score),
              snippet: r.comment ?? '',
            ),
          ),
        );
      }
    }
    return markers;
  }

  void _showAreaInfo(AreaFeature a, Mode mode) {
    final lat =
        a.polygon.map((p) => p[0]).reduce((v, e) => v + e) / a.polygon.length;
    final lng =
        a.polygon.map((p) => p[1]).reduce((v, e) => v + e) / a.polygon.length;
    final price = mode == Mode.rent ? a.avgRent : a.avgBuy;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Média (${mode == Mode.rent ? 'aluguel' : 'compra'}): R\$ ${price.toStringAsFixed(0)}',
            ),
            Text('Avaliações: ${a.ratings.length}'),
          ],
        ),
      ),
    );
  }

  Future<void> _onLongPressAddRating(
    BuildContext context,
    List<AreaFeature> areas,
    LatLng pos,
  ) async {
    AreaFeature? target;
    for (final a in areas) {
      if (pointInPolygon(pos.latitude, pos.longitude, a.polygon)) {
        target = a;
        break;
      }
    }

    if (target == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toque fora dos bairros cadastrados.')),
      );
      return;
    }

    if (!mounted) return;
    final result = await showModalBottomSheet<AddRatingResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddRatingSheet(areaName: target!.name),
      ),
    );

    if (result == null) return;

    final store = ref.read(localStoreProvider);
    final newRating = Rating(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      lat: pos.latitude,
      lng: pos.longitude,
      score: result.score,
      comment: result.comment,
    );
    await store.add(target.id, newRating);

    if (!mounted) return;
    ref.invalidate(areasProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Avaliação adicionada!')));
  }
}

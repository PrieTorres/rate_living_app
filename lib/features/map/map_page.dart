import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/area_feature.dart';
import '../../utils/geo.dart';
import '../../utils/price_color.dart';

import 'map_controller.dart';
import 'widgets/legend.dart';
import 'widgets/mode_toggle.dart';
import 'widgets/add_rating_sheet.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _controller;

  LatLng get _center => const LatLng(-26.485, -49.066); // Jaraguá do Sul

  @override
  Widget build(BuildContext context) {
    final priceMode = ref.watch(priceModeProvider);       // ✅ novo enum
    final legendVisible = ref.watch(legendVisibleProvider);
    final addMode = ref.watch(addRatingModeProvider);
    final areasAsync = ref.watch(areasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rate Living – Mapa')),
      body: Stack(
        children: [
          areasAsync.when(
            data: (areas) => GoogleMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: 12),
              onMapCreated: (c) => _controller = c,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              polygons: _buildPolygons(areas, priceMode),   // 🔁 aqui trocamos mode → priceMode
              markers: _buildMarkers(areas),

              // tap normal → se modo adicionar estiver ativo, abre fluxo
              onTap: (pos) {
                if (addMode) {
                  _onTapAddRating(context, areas, pos);
                }
              },

              // se quiser manter long-press mesmo fora do modo
              onLongPress: (pos) {
                if (!addMode) {
                  _onLongPressAddRating(context, areas, pos);
                }
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Erro ao carregar mapa: $e')),
          ),

          // topo esquerdo: modo + legenda
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: [
                ModeToggle(
                  value: priceMode,                             // 🔁 aqui
                  onChanged: (m) =>
                      ref.read(priceModeProvider.notifier).state = m, // 🔁 aqui
                ),
                const SizedBox(width: 12),
                if (legendVisible) Legend(mode: priceMode),     // 🔁 aqui
              ],
            ),
          ),

          // indicador de modo adicionar
          if (addMode)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Modo adicionar ativo',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),

      // FABs (legenda + modo adicionar)
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'legendFab',
            onPressed: () {
              final current = ref.read(legendVisibleProvider);
              ref.read(legendVisibleProvider.notifier).state = !current;
            },
            icon: Icon(
                legendVisible ? Icons.visibility_off : Icons.visibility),
            label: Text(
                legendVisible ? 'Ocultar legenda' : 'Mostrar legenda'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'addModeFab',
            onPressed: () {
              final current = ref.read(addRatingModeProvider);
              ref.read(addRatingModeProvider.notifier).state = !current;

              if (!current) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Modo adicionar: toque no mapa para incluir uma avaliação.'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Modo adicionar desativado.')),
                );
              }
            },
            icon: Icon(addMode ? Icons.touch_app : Icons.edit_location_alt),
            label: Text(
                addMode ? 'Cancelar adicionar' : 'Adicionar por toque'),
            backgroundColor: addMode ? Colors.orange : null,
          ),
        ],
      ),
    );
  }

  // 🔁 troca Mode por PriceMode aqui também
  Set<Polygon> _buildPolygons(List<AreaFeature> areas, PriceMode mode) {
    final set = <Polygon>{};

    for (final a in areas) {
      final price = mode == PriceMode.rent ? a.avgRent : a.avgBuy;
      final color = priceToColor(mode, price);
      final path = a.polygon.map((p) => LatLng(p[0], p[1])).toList();

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

  // 🔁 aqui também: Mode → PriceMode
  void _showAreaInfo(AreaFeature a, PriceMode mode) {
    final lat = a.polygon
            .map((p) => p[0])
            .reduce((v, e) => v + e) /
        a.polygon.length;
    final lng = a.polygon
            .map((p) => p[1])
            .reduce((v, e) => v + e) /
        a.polygon.length;
    final price = mode == PriceMode.rent ? a.avgRent : a.avgBuy;

    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14),
    );

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
            Text(a.name,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Média (${mode == PriceMode.rent ? 'aluguel' : 'compra'}): R\$ ${price.toStringAsFixed(0)}',
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
    await _handleAddRatingFlow(context, areas, pos);
  }

  Future<void> _onTapAddRating(
    BuildContext context,
    List<AreaFeature> areas,
    LatLng pos,
  ) async {
    await _handleAddRatingFlow(context, areas, pos);

    if (mounted) {
      ref.read(addRatingModeProvider.notifier).state = false;
    }
  }

  Future<void> _handleAddRatingFlow(
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
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddRatingSheet(areaName: target!.name),
      ),
    );

    if (result == null) return;

    final api = ref.read(firestoreApiProvider);
    await api.addRating(
      areaId: target.id,
      lat: pos.latitude,
      lng: pos.longitude,
      score: result.score,
      comment: result.comment,
    );

    if (!mounted) return;
    ref.invalidate(areasProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avaliação adicionada!')),
    );
  }
}

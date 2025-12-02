import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../models/area_feature.dart';
import '../../utils/geo.dart';
import '../../utils/price_color.dart';

import '../auth/auth_providers.dart';
import '../../data/firestore_api.dart';

import 'map_controller.dart';
// Legend escondida por enquanto
// import 'widgets/legend.dart';
import 'widgets/mode_toggle.dart';
import 'widgets/add_rating_sheet.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _controller;

  bool _addingRating = false;

  static const _mapsApiKey = String.fromEnvironment('MAPS_API_KEY');

  LatLng get _center => const LatLng(-26.485, -49.066); // Jaraguá do Sul

  @override
  Widget build(BuildContext context) {
    final priceMode = ref.watch(priceModeProvider);
    final addMode = ref.watch(addRatingModeProvider);
    final areasAsync = ref.watch(areasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rate Living – Mapa')),
      body: Stack(
        children: [
          areasAsync.when(
            data: (areas) {
              debugPrint('[MAP] areas loaded: ${areas.length}');
              return GoogleMap(
                initialCameraPosition: CameraPosition(target: _center, zoom: 12),
                onMapCreated: (c) {
                  debugPrint('[MAP] onMapCreated');
                  _controller = c;
                },
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                polygons: _buildPolygons(areas, priceMode),
                markers: _buildMarkers(areas),
                onTap: (pos) {
                  debugPrint('[MAP] onTap at ${pos.latitude},${pos.longitude}');
                  if (addMode) {
                    _onTapAddRating(context, areas, pos);
                  }
                },
                onLongPress: (pos) {
                  debugPrint('[MAP] onLongPress at ${pos.latitude},${pos.longitude}');
                  if (!addMode) {
                    _onLongPressAddRating(context, areas, pos);
                  }
                },
              );
            },
            loading: () {
              debugPrint('[MAP] areas loading...');
              return const Center(child: CircularProgressIndicator());
            },
            error: (e, st) {
              debugPrint('[MAP] error loading areas: $e\n$st');
              return Center(child: Text('Erro ao carregar mapa: $e'));
            },
          ),

          // topo esquerdo: seletor de modo (aluguel/compra)
          Positioned(
            top: 12,
            left: 12,
            child: ModeToggle(
              value: priceMode,
              onChanged: (m) {
                debugPrint('[UI] priceMode changed to $m');
                ref.read(priceModeProvider.notifier).state = m;
              },
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

      // FABs
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // NOVA AVALIAÇÃO (sem endereço/CEP pré-preenchidos)
          FloatingActionButton.extended(
            heroTag: 'newRatingFab',
            onPressed: () async {
              debugPrint('[FAB] Nova avaliação clicado');
              final areasValue = ref.read(areasProvider);
              final areas = areasValue.maybeWhen(
                data: (value) => value,
                orElse: () => <AreaFeature>[],
              );

              if (areas.isEmpty) {
                debugPrint('[FAB] Nenhuma área carregada para nova avaliação');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nenhum bairro cadastrado no mapa ainda.'),
                  ),
                );
                return;
              }

              final pos = _center;
              await _handleAddRatingFlow(
                context,
                areas,
                pos,
                fromFab: true,
              );
            },
            icon: const Icon(Icons.rate_review),
            label: const Text('Nova avaliação'),
          ),
          const SizedBox(height: 12),

          // Modo adicionar por toque
          FloatingActionButton.extended(
            heroTag: 'addModeFab',
            onPressed: () {
              final current = ref.read(addRatingModeProvider);
              final next = !current;
              debugPrint('[FAB] addRatingMode toggled: $next');
              ref.read(addRatingModeProvider.notifier).state = next;

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

  /// Polígonos invisíveis (sem azul), mas ainda clicáveis para lógica de área.
  Set<Polygon> _buildPolygons(List<AreaFeature> areas, PriceMode mode) {
    final set = <Polygon>{};

    for (final a in areas) {
      // usamos apenas para limite de área; cor visual fica invisível
      final path = a.polygon.map((p) => LatLng(p[0], p[1])).toList();

      set.add(
        Polygon(
          polygonId: PolygonId(a.id),
          points: path,
          strokeColor: Colors.transparent,
          strokeWidth: 0,
          fillColor: Colors.transparent,
          consumeTapEvents: true,
          onTap: () {
            if (_addingRating) return;
            debugPrint('[MAP] polygon tapped: ${a.id} (${a.name})');
            _showAreaInfo(a, mode);
          },
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

    debugPrint('[MAP] markers count: ${markers.length}');
    return markers;
  }

  void _showAreaInfo(AreaFeature a, PriceMode mode) {
    final lat = a.polygon.map((p) => p[0]).reduce((v, e) => v + e) /
        a.polygon.length;
    final lng = a.polygon.map((p) => p[1]).reduce((v, e) => v + e) /
        a.polygon.length;
    final price = mode == PriceMode.rent ? a.avgRent : a.avgBuy;

    debugPrint('[INFO] showAreaInfo: ${a.id} (${a.name}), center=$lat,$lng');

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
    debugPrint('[FLOW] longPress addRating at ${pos.latitude},${pos.longitude}');
    await _handleAddRatingFlow(context, areas, pos);
  }

  Future<void> _onTapAddRating(
    BuildContext context,
    List<AreaFeature> areas,
    LatLng pos,
  ) async {
    debugPrint('[FLOW] tap addRating (modo adicionar) at ${pos.latitude},${pos.longitude}');
    await _handleAddRatingFlow(context, areas, pos);

    if (mounted) {
      ref.read(addRatingModeProvider.notifier).state = false;
      debugPrint('[FLOW] addRatingMode set to false after tap');
    }
  }

  Future<List<String>> _uploadRatingImages(
    String areaId,
    String? userId,
    List<XFile> images,
  ) async {
    final storage = FirebaseStorage.instance;
    final List<String> urls = [];

    debugPrint('[UPLOAD] start upload for ${images.length} image(s) '
        'areaId=$areaId userId=$userId');

    for (var i = 0; i < images.length; i++) {
      final file = images[i];
      final path =
          'ratings/$areaId/${userId ?? 'anon'}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

      try {
        debugPrint('[UPLOAD] uploading #$i to path: $path');
        final ref = storage.ref().child(path);
        final bytes = await file.readAsBytes();
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        final task = await ref.putData(bytes, metadata);
        debugPrint('[UPLOAD] upload complete, bytes: ${task.bytesTransferred}');
        final url = await ref.getDownloadURL();
        debugPrint('[UPLOAD] download URL: $url');
        urls.add(url);
      } catch (e, st) {
        debugPrint('[UPLOAD][ERROR] Failed to upload image #$i: $e\n$st');
        // não lança erro, só loga e segue
      }
    }

    debugPrint('[UPLOAD] finished with ${urls.length} URL(s)');
    return urls;
  }

  Future<(String? address, String? cep)> _reverseGeocode(
    double lat,
    double lng,
  ) async {
    if (_mapsApiKey.isEmpty) {
      debugPrint('[GEO] MAPS_API_KEY is empty, skipping reverse geocode');
      return (null, null);
    }

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {
          'latlng': '$lat,$lng',
          'key': _mapsApiKey,
          'language': 'pt-BR',
          'region': 'br',
        },
      );

      debugPrint('[GEO] reverse geocode request: $uri');

      final resp = await http.get(uri);
      debugPrint('[GEO] HTTP ${resp.statusCode}');

      if (resp.statusCode != 200) {
        debugPrint('[GEO][ERROR] Non-200 response: ${resp.body}');
        return (null, null);
      }

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final status = json['status'] as String?;
      debugPrint('[GEO] status: $status');

      if (status != 'OK') {
        final err = json['error_message'];
        debugPrint('[GEO][ERROR] status=$status error_message=$err');
        return (null, null);
      }

      final results = json['results'] as List<dynamic>;
      if (results.isEmpty) {
        debugPrint('[GEO][ERROR] No results');
        return (null, null);
      }

      final first = results[0] as Map<String, dynamic>;
      final formatted = first['formatted_address'] as String;
      debugPrint('[GEO] formatted_address: $formatted');

      String? cep;
      final components = first['address_components'] as List<dynamic>;
      for (final c in components) {
        final comp = c as Map<String, dynamic>;
        final types = (comp['types'] as List<dynamic>).cast<String>();
        if (types.contains('postal_code')) {
          cep = comp['short_name'] as String;
          debugPrint('[GEO] found postal_code: $cep');
          break;
        }
      }

      return (formatted, cep);
    } catch (e, st) {
      debugPrint('[GEO][EXCEPTION] $e\n$st');
      return (null, null);
    }
  }

  Future<void> _handleAddRatingFlow(
    BuildContext context,
    List<AreaFeature> areas,
    LatLng pos, {
    bool fromFab = false,
  }) async {
    if (_addingRating) {
      debugPrint('[FLOW] _handleAddRatingFlow aborted: already adding');
      return;
    }
    if (areas.isEmpty) {
      debugPrint('[FLOW][ERROR] no areas loaded');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum bairro cadastrado no mapa.')),
      );
      return;
    }

    debugPrint('[FLOW] _handleAddRatingFlow start at '
        '${pos.latitude},${pos.longitude} fromFab=$fromFab');

    _addingRating = true;
    try {
      // 1) achar área
      AreaFeature? target;
      for (final a in areas) {
        if (pointInPolygon(pos.latitude, pos.longitude, a.polygon)) {
          target = a;
          debugPrint('[FLOW] point inside polygon: ${a.id} (${a.name})');
          break;
        }
      }

      // fallback: área mais próxima
      if (target == null) {
        debugPrint('[FLOW] point outside all polygons, searching nearest area');
        double? bestDist;
        for (final a in areas) {
          final lat = a.polygon.map((p) => p[0]).reduce((v, e) => v + e) /
              a.polygon.length;
          final lng = a.polygon.map((p) => p[1]).reduce((v, e) => v + e) /
              a.polygon.length;

          final dLat = pos.latitude - lat;
          final dLng = pos.longitude - lng;
          final dist2 = dLat * dLat + dLng * dLng;

          if (bestDist == null || dist2 < bestDist) {
            bestDist = dist2;
            target = a;
          }
        }
        if (target != null) {
          debugPrint('[FLOW] nearest area: ${target!.id} (${target!.name})');
        }
      }

      if (target == null) {
        debugPrint('[FLOW][ERROR] still no target area');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível identificar um bairro.')),
        );
        return;
      }

      // posição default p/ marker
      LatLng ratingPos = pos;
      if (fromFab) {
        final lat = target!.polygon.map((p) => p[0]).reduce((v, e) => v + e) /
            target!.polygon.length;
        final lng = target!.polygon.map((p) => p[1]).reduce((v, e) => v + e) /
            target!.polygon.length;
        ratingPos = LatLng(lat, lng);
        debugPrint('[FLOW] fromFab: using area center $lat,$lng as ratingPos');
      }

      // 2) endereço inicial / CEP
      String? initialAddress;
      String? initialCep;

      if (fromFab) {
        // Botão "Nova avaliação" → não preencher nada
        debugPrint('[FLOW] fromFab=true: skipping reverseGeocode, '
            'initialAddress/CEP vazios');
        initialAddress = '';
        initialCep = '';
      } else {
        // Clique no mapa → tenta reverse geocode
        debugPrint('[FLOW] calling reverseGeocode for '
            '${ratingPos.latitude},${ratingPos.longitude}');
        final (addr, cep) =
            await _reverseGeocode(ratingPos.latitude, ratingPos.longitude);
        initialAddress = addr ?? target.name;
        initialCep = cep ?? '';
        debugPrint('[FLOW] initialAddress="$initialAddress", '
            'initialCep="$initialCep"');
      }

      if (!mounted) return;

      final auth = ref.read(firebaseAuthProvider);
      final user = auth.currentUser;
      debugPrint('[FLOW] currentUser: ${user?.uid} (${user?.email})');

      // 3) abrir bottom sheet (modal travado)
      final result = await showModalBottomSheet<AddRatingResult>(
        context: context,
        isScrollControlled: true,
        isDismissible: false, // não fecha clicando fora
        enableDrag: false, // não arrasta pra fechar
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => AddRatingSheet(
          areaName: target!.name,
          initialLocationType: 'bairro',
          initialAddress: initialAddress,
          initialCep: initialCep,
        ),
      );

      debugPrint('[FLOW] bottom sheet closed, result is ${result == null ? 'null' : 'not null'}');

      if (result == null) return;

      // 4) upload imagens
      List<String> uploadedUrls = [];
      if (result.localImages.isNotEmpty) {
        debugPrint('[FLOW] uploading ${result.localImages.length} image(s)');
        uploadedUrls =
            await _uploadRatingImages(target.id, user?.uid, result.localImages);
      } else {
        debugPrint('[FLOW] no localImages to upload');
      }

      final allPhotoUrls = [
        ...result.photoUrls,
        ...uploadedUrls,
      ];

      final api = ref.read(firestoreApiProvider);

      debugPrint('[FLOW] saving rating to Firestore for areaId=${target.id}');
      try {
        await api.addRating(
          areaId: target.id,
          lat: ratingPos.latitude,
          lng: ratingPos.longitude,
          score: result.score,
          comment: result.comment,
          userId: user?.uid,
          locationType: result.locationType,
          address: result.address,
          cep: result.cep,
          buyPrice: result.buyPrice,
          rentPrice: result.rentPrice,
          listingLinks: result.listingLinks,
          photoUrls: allPhotoUrls,
          bedrooms: result.bedrooms,
          areaM2: result.areaM2,
          bathrooms: result.bathrooms,
        );
        debugPrint('[FLOW] rating saved successfully');
      } catch (e, st) {
        debugPrint('[FLOW][ERROR] Failed to save rating: $e\n$st');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar avaliação no Firebase.'),
          ),
        );
        return;
      }

      if (!mounted) return;
      ref.invalidate(areasProvider);
      debugPrint('[FLOW] areasProvider invalidated (reload areas)');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação adicionada!')),
      );
    } catch (e, st) {
      debugPrint('[FLOW][UNCAUGHT] $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Erro inesperado ao adicionar avaliação. Veja logs.'),
          ),
        );
      }
    } finally {
      _addingRating = false;
      debugPrint('[FLOW] _handleAddRatingFlow end, _addingRating=false');
    }
  }
}

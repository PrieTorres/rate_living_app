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
  LatLng get _center => const LatLng(-26.485, -49.066);

  // Armazena a posição central atual da câmera do mapa
  LatLng? _currentCenter;

  @override
  Widget build(BuildContext context) {
    final priceMode = ref.watch(priceModeProvider);
    final addMode = ref.watch(addRatingModeProvider);
    final areasAsync = ref.watch(areasProvider);
    const primary = Color(0xFFE46B3F);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Living – Mapa'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final auth = ref.watch(firebaseAuthProvider);
              final user = auth.currentUser;
              if (user != null) {
                final initial = (user.displayName?.isNotEmpty ?? false)
                    ? user.displayName!.substring(0, 1).toUpperCase()
                    : (user.email?.isNotEmpty ?? false)
                        ? user.email!.substring(0, 1).toUpperCase()
                        : 'U';
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed('/profile');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          areasAsync.when(
            data: (areas) {
              return GoogleMap(
                initialCameraPosition: CameraPosition(target: _center, zoom: 12),
                onMapCreated: (c) {
                  _controller = c;
                },
                onCameraMove: (position) {
                  // Atualiza a posição central atual do mapa para usar no FAB
                  _currentCenter = position.target;
                },
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                polygons: _buildPolygons(areas, priceMode),
                markers: _buildMarkers(areas),
                onTap: (pos) {
                  if (addMode) {
                    _onTapAddRating(context, areas, pos);
                  }
                },
                onLongPress: (pos) {
                  if (!addMode) {
                    _onLongPressAddRating(context, areas, pos);
                  }
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Erro ao carregar mapa: $e')),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: ModeToggle(
              value: priceMode,
              onChanged: (m) {
                ref.read(priceModeProvider.notifier).state = m;
              },
            ),
          ),
          if (addMode)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'newRatingFab',
            onPressed: () async {
              final areasValue = ref.read(areasProvider);
              final areas = areasValue.maybeWhen(
                data: (value) => value,
                orElse: () => <AreaFeature>[],
              );
              if (areas.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nenhum bairro cadastrado no mapa ainda.'),
                  ),
                );
                return;
              }
              // Usa a posição atual do centro da câmera, se disponível, ao invés de um valor fixo
              final pos = _currentCenter ?? _center;
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
          FloatingActionButton.extended(
            heroTag: 'addModeFab',
            onPressed: () {
              final current = ref.read(addRatingModeProvider);
              final next = !current;
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
            icon:
                Icon(addMode ? Icons.touch_app : Icons.edit_location_alt),
            label: Text(
                addMode ? 'Cancelar adicionar' : 'Adicionar por toque'),
            backgroundColor: addMode ? Colors.orange : null,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey.shade600,
        onTap: (index) {
          if (index == 0) {
            return;
          } else if (index == 1) {
            Navigator.of(context).pushNamed('/ranking');
          } else if (index == 2) {
            Navigator.of(context).pushNamed('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            label: 'Rankings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Usuário',
          ),
        ],
      ),
    );
  }

  Set<Polygon> _buildPolygons(List<AreaFeature> areas, PriceMode mode) {
    final set = <Polygon>{};
    for (final a in areas) {
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
    return markers;
  }

  void _showAreaInfo(AreaFeature a, PriceMode mode) {
    final lat =
        a.polygon.map((p) => p[0]).reduce((v, e) => v + e) / a.polygon.length;
    final lng =
        a.polygon.map((p) => p[1]).reduce((v, e) => v + e) / a.polygon.length;
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

  Future<List<String>> _uploadRatingImages(
    String areaId,
    String? userId,
    List<XFile> images,
  ) async {
    final storage = FirebaseStorage.instance;
    final List<String> urls = [];
    for (var i = 0; i < images.length; i++) {
      final file = images[i];
      final path =
          'ratings/$areaId/${userId ?? 'anon'}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      try {
        final ref = storage.ref().child(path);
        final bytes = await file.readAsBytes();
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        await ref.putData(bytes, metadata);
        final url = await ref.getDownloadURL();
        urls.add(url);
      } catch (_) {}
    }
    return urls;
  }

  // Realiza geocodificação a partir de um CEP para obter lat/lng
  Future<LatLng?> _geocodeCep(String cep) async {
    if (_mapsApiKey.isEmpty) return null;
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {
          'address': cep,
          'key': _mapsApiKey,
          'language': 'pt-BR',
          'region': 'br',
        },
      );
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if ((json['status'] as String?) != 'OK') return null;
      final results = json['results'] as List<dynamic>;
      if (results.isEmpty) return null;
      final first = results[0] as Map<String, dynamic>;
      final location = first['geometry']['location'] as Map<String, dynamic>;
      final lat = (location['lat'] as num).toDouble();
      final lng = (location['lng'] as num).toDouble();
      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }

  Future<(String? address, String? cep)> _reverseGeocode(
    double lat,
    double lng,
  ) async {
    if (_mapsApiKey.isEmpty) {
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
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        return (null, null);
      }
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final status = json['status'] as String?;
      if (status != 'OK') {
        return (null, null);
      }
      final results = json['results'] as List<dynamic>;
      if (results.isEmpty) {
        return (null, null);
      }
      final first = results[0] as Map<String, dynamic>;
      final formatted = first['formatted_address'] as String;
      String? cep;
      final components = first['address_components'] as List<dynamic>;
      for (final c in components) {
        final comp = c as Map<String, dynamic>;
        final types = (comp['types'] as List<dynamic>).cast<String>();
        if (types.contains('postal_code')) {
          cep = comp['short_name'] as String;
          break;
        }
      }
      return (formatted, cep);
    } catch (_) {
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
      return;
    }
    if (areas.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum bairro cadastrado no mapa.')),
      );
      return;
    }
    _addingRating = true;
    try {
      // Define área inicial a partir da posição clicada
      AreaFeature? target;
      for (final a in areas) {
        if (pointInPolygon(pos.latitude, pos.longitude, a.polygon)) {
          target = a;
          break;
        }
      }
      // Caso não esteja dentro de nenhum polígono, usa o mais próximo
      if (target == null) {
        double? bestDist;
        for (final a in areas) {
          final lat =
              a.polygon.map((p) => p[0]).reduce((v, e) => v + e) / a.polygon.length;
          final lng =
              a.polygon.map((p) => p[1]).reduce((v, e) => v + e) / a.polygon.length;
          final dLat = pos.latitude - lat;
          final dLng = pos.longitude - lng;
          final dist2 = dLat * dLat + dLng * dLng;
          if (bestDist == null || dist2 < bestDist) {
            bestDist = dist2;
            target = a;
          }
        }
      }
      if (target == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível identificar um bairro.')),
        );
        return;
      }

      // Ajusta a posição de avaliação se o usuário clicou no FAB (centro do bairro)
      LatLng ratingPos = pos;
      if (fromFab) {
        final lat = target!.polygon.map((p) => p[0]).reduce((v, e) => v + e) /
            target!.polygon.length;
        final lng = target!.polygon.map((p) => p[1]).reduce((v, e) => v + e) /
            target!.polygon.length;
        ratingPos = LatLng(lat, lng);
      }

      // Preenche endereço/CEP padrão via reverse geocode, exceto se for pelo FAB
      String? initialAddress;
      String? initialCep;
      if (fromFab) {
        initialAddress = '';
        initialCep = '';
      } else {
        final (addr, cep) =
            await _reverseGeocode(ratingPos.latitude, ratingPos.longitude);
        initialAddress = addr ?? target.name;
        initialCep = cep ?? '';
      }

      if (!mounted) return;
      final auth = ref.read(firebaseAuthProvider);
      final user = auth.currentUser;
      final result = await showModalBottomSheet<AddRatingResult>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
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
      if (result == null) return;

      // Se o usuário inseriu um CEP, geocodifica para obter a latitude/longitude
      LatLng? geocodePos;
      if (result.cep != null && result.cep!.trim().isNotEmpty) {
        geocodePos = await _geocodeCep(result.cep!.trim());
      }
      if (geocodePos != null) {
        ratingPos = geocodePos;
        // Recalcula o bairro com base na nova posição
        AreaFeature? newTarget;
        for (final a in areas) {
          if (pointInPolygon(ratingPos.latitude, ratingPos.longitude, a.polygon)) {
            newTarget = a;
            break;
          }
        }
        if (newTarget != null) {
          target = newTarget;
        }
      }

      List<String> uploadedUrls = [];
      if (result.localImages.isNotEmpty) {
        uploadedUrls =
            await _uploadRatingImages(target.id, user?.uid, result.localImages);
      }
      final allPhotoUrls = [
        ...result.photoUrls,
        ...uploadedUrls,
      ];
      final api = ref.read(firestoreApiProvider);
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
      } catch (_) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação adicionada!')),
      );
    } catch (_) {
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
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/area_feature.dart';
import '../../data/mock_api.dart';
import '../../services/local_store.dart';
import '../../models/rating.dart';

final modeProvider = StateProvider<Mode>((ref) => Mode.rent);
final legendVisibleProvider = StateProvider<bool>((ref) => false);

final _areasMockProvider = FutureProvider<List<AreaFeature>>((ref) async {
  final api = MockApi();
  return api.fetchAreas();
});

final localStoreProvider = Provider<LocalRatingsStore>((ref) => LocalRatingsStore());

final areasProvider = FutureProvider<List<AreaFeature>>((ref) async {
  final areas = await ref.watch(_areasMockProvider.future);
  final store = ref.read(localStoreProvider);
  final localAll = await store.getAll();

  return areas.map((a) {
    final extra = localAll[a.id] ?? const <Rating>[];
    return AreaFeature(
      id: a.id,
      name: a.name,
      polygon: a.polygon,
      avgRent: a.avgRent,
      avgBuy: a.avgBuy,
      ratings: [...a.ratings, ...extra],
    );
  }).toList();
});

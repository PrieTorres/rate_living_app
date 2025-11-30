import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/area_feature.dart';
import '../../data/firestore_api.dart';

enum PriceMode { rent, buy }

final priceModeProvider = StateProvider<PriceMode>((ref) => PriceMode.rent);

final legendVisibleProvider = StateProvider<bool>((ref) => true);

final addRatingModeProvider = StateProvider<bool>((ref) => false);

final firestoreApiProvider = Provider<FirestoreApi>((ref) => FirestoreApi());

final areasProvider = FutureProvider<List<AreaFeature>>((ref) async {
  final api = ref.read(firestoreApiProvider);
  return api.fetchAreas();
});

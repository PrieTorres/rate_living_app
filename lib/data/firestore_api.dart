import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/area_feature.dart';
import '../models/rating.dart';

class FirestoreApi {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<AreaFeature>> fetchAreas() async {
    final areasSnap = await _db.collection('areas').get();

    final List<AreaFeature> areas = [];

    for (final doc in areasSnap.docs) {
      final data = doc.data();

      final polygon = (data['polygon'] as List)
          .map((p) => [
                (p['lat'] as num).toDouble(),
                (p['lng'] as num).toDouble(),
              ])
          .toList();

      final ratingsSnap = await doc.reference.collection('ratings').get();
      final ratings = ratingsSnap.docs.map((rDoc) {
        final rd = rDoc.data();
        return Rating(
          id: rDoc.id,
          lat: (rd['lat'] as num).toDouble(),
          lng: (rd['lng'] as num).toDouble(),
          score: rd['score'] as int,
          comment: rd['comment'] as String?,
        );
      }).toList();

      areas.add(
        AreaFeature(
          id: doc.id,
          name: data['name'] as String,
          polygon: polygon,
          avgRent: (data['avgRent'] as num).toInt(),
          avgBuy: (data['avgBuy'] as num).toInt(),
          ratings: ratings,
        ),
      );
    }

    return areas;
  }

  Future<void> addRating({
    required String areaId,
    required double lat,
    required double lng,
    required int score,
    String? comment,
  }) async {
    final docRef = _db.collection('areas').doc(areaId);
    await docRef.collection('ratings').add({
      'lat': lat,
      'lng': lng,
      'score': score,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'user',
    });
  }
}

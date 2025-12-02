import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/area_feature.dart';
import '../models/rating.dart';

class FirestoreApi {
  late final FirebaseFirestore _db;
  FirestoreApi() {
    final app = Firebase.app();
    _db = FirebaseFirestore.instanceFor(app: app, databaseId: 'ratelivingdb');
  }

  Future<List<AreaFeature>> fetchAreas() async {
    final areasSnap = await _db.collection('areas').get();
    final List<AreaFeature> areas = [];
    for (final doc in areasSnap.docs) {
      final data = doc.data();
      final polygon = (data['polygon'] as List)
          .map((p) => [(p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()])
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
          userId: rd['userId'] as String?,
          locationType: rd['locationType'] as String?,
          address: rd['address'] as String?,
          cep: rd['cep'] as String?,
          buyPrice: (rd['buyPrice'] as num?)?.toDouble(),
          rentPrice: (rd['rentPrice'] as num?)?.toDouble(),
          listingLinks: (rd['listingLinks'] as List?)?.map((e) => e.toString()).toList() ?? const [],
          photoUrls: (rd['photoUrls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
          bedrooms: (rd['bedrooms'] as num?)?.toInt(),
          areaM2: (rd['areaM2'] as num?)?.toDouble(),
          bathrooms: (rd['bathrooms'] as num?)?.toInt(),
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
    String? userId,
    required String locationType,
    required String address,
    required String cep,
    double? buyPrice,
    double? rentPrice,
    List<String>? listingLinks,
    List<String>? photoUrls,
    int? bedrooms,
    double? areaM2,
    int? bathrooms,
  }) async {
    final docRef = _db.collection('areas').doc(areaId);
    await docRef.collection('ratings').add({
      'lat': lat,
      'lng': lng,
      'score': score,
      'comment': comment,
      'userId': userId,
      'locationType': locationType,
      'address': address,
      'cep': cep,
      'buyPrice': buyPrice,
      'rentPrice': rentPrice,
      'listingLinks': listingLinks ?? [],
      'photoUrls': photoUrls ?? [],
      'bedrooms': bedrooms,
      'areaM2': areaM2,
      'bathrooms': bathrooms,
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'user',
    });
  }

  Future<void> updateRating({
    required String areaId,
    required String ratingId,
    required int score,
    String? comment,
  }) async {
    final docRef = _db.collection('areas').doc(areaId).collection('ratings').doc(ratingId);
    await docRef.update({'score': score, 'comment': comment});
  }

  Future<void> deleteRating({
    required String areaId,
    required String ratingId,
  }) async {
    await _db.collection('areas').doc(areaId).collection('ratings').doc(ratingId).delete();
  }
}

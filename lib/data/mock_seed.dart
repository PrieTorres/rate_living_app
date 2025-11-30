import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/area_feature.dart';
import '../models/rating.dart';

/// Mocks de áreas/bairros de Jaraguá do Sul
final List<AreaFeature> mockAreas = [
  AreaFeature(
    id: 'centro',
    name: 'Centro',
    polygon: [
      [-26.4870, -49.0840],
      [-26.4870, -49.0700],
      [-26.4770, -49.0700],
      [-26.4770, -49.0840],
    ],
    avgRent: 2800,
    avgBuy: 420000,
    ratings: [
      Rating(
        id: 'centro_r1',
        lat: -26.4820,
        lng: -49.0780,
        score: 5,
        comment: 'Ótima região para comércio e serviços.',
      ),
      Rating(
        id: 'centro_r2',
        lat: -26.4810,
        lng: -49.0760,
        score: 4,
        comment: 'Movimentado, mas com bom acesso.',
      ),
    ],
  ),
  // ... outras áreas ...
];

Future<void> seedMockAreasToFirestore() async {
  final app = Firebase.app();
  final db = FirebaseFirestore.instanceFor(
    app: app,
    databaseId: 'ratelivingdb',
  );

  print('🔥 [SEED] Iniciando seed de áreas mockadas...');

  try {
    // 0) TESTE SIMPLES DE ESCRITA
    print('🧪 [SEED] Testando escrita simples em /debug/ping...');
    await db
        .collection('debug')
        .doc('ping')
        .set({
          'ok': true,
          'time': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 10));
    print('✅ [SEED] Teste /debug/ping OK!');

    // 1) AGORA VAMOS PARA AS ÁREAS
    for (final area in mockAreas) {
      print('📍 [SEED] Gravando área: ${area.id} (${area.name})');

      final docRef = db.collection('areas').doc(area.id);

      print('   📝 [SEED] Antes do set() da área ${area.id}');
      await docRef
          .set({
            'name': area.name,
            'avgRent': area.avgRent,
            'avgBuy': area.avgBuy,
            'polygon': area.polygon
                .map((p) => {
                      'lat': p[0],
                      'lng': p[1],
                    })
                .toList(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
      print('   ✅ [SEED] Depois do set() da área ${area.id}');

      final ratingsRef = docRef.collection('ratings');
      print('   ⭐ [SEED] Gravando ratings da área ${area.id}...');

      for (final r in area.ratings) {
        print('      🔸 [SEED] Antes do set() do rating ${r.id}');
        await ratingsRef
            .doc(r.id)
            .set({
              'lat': r.lat,
              'lng': r.lng,
              'score': r.score,
              'comment': r.comment,
              'createdAt': FieldValue.serverTimestamp(),
              'source': 'mock',
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));
        print('      ✅ [SEED] Depois do set() do rating ${r.id}');
      }

      print('✅ [SEED] Ratings da área ${area.id} finalizados.');
    }

    print('🎉 [SEED] Seed concluído sem erros!');
  } on TimeoutException catch (e) {
    print('⏰ [SEED] TIMEOUT ao falar com o Firestore: $e');
  } catch (e, st) {
    print('❌ [SEED] ERRO ao rodar seed: $e');
    print('🔍 [SEED] Stacktrace:\n$st');
  }
}

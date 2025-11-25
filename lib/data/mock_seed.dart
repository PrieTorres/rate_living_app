import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/area_feature.dart';
import '../models/rating.dart';

/// Mocks de áreas/bairros de Jaraguá do Sul
final List<AreaFeature> mockAreas = [
  AreaFeature(
    id: 'centro',
    name: 'Centro',
    // polígono bem aproximado, ajuste se quiser
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
  AreaFeature(
    id: 'jaragua_esquerdo',
    name: 'Jaraguá Esquerdo',
    polygon: [
      [-26.4920, -49.0760],
      [-26.4920, -49.0600],
      [-26.4820, -49.0600],
      [-26.4820, -49.0760],
    ],
    avgRent: 2300,
    avgBuy: 380000,
    ratings: [
      Rating(
        id: 'je_r1',
        lat: -26.4880,
        lng: -49.0700,
        score: 4,
        comment: 'Bairro tranquilo e residencial.',
      ),
      Rating(
        id: 'je_r2',
        lat: -26.4860,
        lng: -49.0720,
        score: 3,
        comment: 'Boa vizinhança, trânsito um pouco lento em horário de pico.',
      ),
    ],
  ),
  AreaFeature(
    id: 'amizade',
    name: 'Amizade',
    polygon: [
      [-26.4900, -49.0920],
      [-26.4900, -49.0800],
      [-26.4800, -49.0800],
      [-26.4800, -49.0920],
    ],
    avgRent: 2000,
    avgBuy: 350000,
    ratings: [
      Rating(
        id: 'amizade_r1',
        lat: -26.4860,
        lng: -49.0880,
        score: 5,
        comment: 'Muito bom para famílias, bairro calmo.',
      ),
      Rating(
        id: 'amizade_r2',
        lat: -26.4840,
        lng: -49.0860,
        score: 4,
        comment: 'Boa relação custo-benefício.',
      ),
    ],
  ),
];

Future<void> seedMockAreasToFirestore() async {
  final db = FirebaseFirestore.instance;

  print('🔥 [SEED] Iniciando seed de áreas mockadas...');

  try {
    for (final area in mockAreas) {
      print('📍 [SEED] Gravando área: ${area.id} (${area.name})');

      final docRef = db.collection('areas').doc(area.id);

      await docRef.set({
        'name': area.name,
        'avgRent': area.avgRent,
        'avgBuy': area.avgBuy,
        'polygon': area.polygon
            .map((p) => {
                  'lat': p[0],
                  'lng': p[1],
                })
            .toList(),
      }, SetOptions(merge: true));

      print('✅ [SEED] Área ${area.id} gravada. Agora gravando ratings...');

      final ratingsRef = docRef.collection('ratings');

      for (final r in area.ratings) {
        print('   ⭐ [SEED] Gravando rating ${r.id} (score ${r.score})');
        await ratingsRef.doc(r.id).set({
          'lat': r.lat,
          'lng': r.lng,
          'score': r.score,
          'comment': r.comment,
          'createdAt': FieldValue.serverTimestamp(),
          'source': 'mock',
        }, SetOptions(merge: true));
      }

      print('✅ [SEED] Ratings da área ${area.id} finalizados.');
    }

    print('🎉 [SEED] Seed concluído sem erros!');
  } catch (e, st) {
    print('❌ [SEED] ERRO ao rodar seed: $e');
    print('🔍 [SEED] Stacktrace:\n$st');
  }
}

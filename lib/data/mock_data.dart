import '../models/area_feature.dart';
import '../models/rating.dart';

final mockAreas = <AreaFeature>[
  AreaFeature(
    id: 'centro',
    name: 'Centro',
    polygon: [
      [-26.483, -49.078],
      [-26.483, -49.056],
      [-26.476, -49.056],
      [-26.476, -49.078],
    ],
    avgRent: 2800,
    avgBuy: 420000,
    ratings: [
      Rating(id: 'r1', lat: -26.480, lng: -49.068, score: 5, comment: 'Bom comércio'),
      Rating(id: 'r2', lat: -26.482, lng: -49.070, score: 4),
    ],
  ),
  AreaFeature(
    id: 'vila-nova',
    name: 'Vila Nova',
    polygon: [
      [-26.494, -49.081],
      [-26.494, -49.060],
      [-26.488, -49.060],
      [-26.488, -49.081],
    ],
    avgRent: 2200,
    avgBuy: 360000,
    ratings: [
      Rating(id: 'r3', lat: -26.491, lng: -49.070, score: 4, comment: 'Tranquilo'),
      Rating(id: 'r4', lat: -26.492, lng: -49.075, score: 3),
    ],
  ),
  AreaFeature(
    id: 'jaragua-esquerdo',
    name: 'Jaraguá Esquerdo',
    polygon: [
      [-26.491, -49.060],
      [-26.491, -49.040],
      [-26.480, -49.040],
      [-26.480, -49.060],
    ],
    avgRent: 2500,
    avgBuy: 390000,
    ratings: [
      Rating(id: 'r5', lat: -26.486, lng: -49.052, score: 5, comment: 'Perto do trabalho'),
      Rating(id: 'r6', lat: -26.489, lng: -49.048, score: 4),
    ],
  ),
];

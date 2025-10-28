import 'dart:math';

/// Retorna true se (lat,lng) estiver dentro do polígono (lista de [lat,lng])
bool pointInPolygon(double lat, double lng, List<List<double>> polygon) {
  // Ray casting
  bool inside = false;
  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i][1], yi = polygon[i][0]; // x=lng, y=lat
    final xj = polygon[j][1], yj = polygon[j][0];

    final intersect = ((yi > lat) != (yj > lat)) &&
        (lng < (xj - xi) * (lat - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

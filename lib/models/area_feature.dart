import 'rating.dart';

enum Mode { rent, buy }

class AreaFeature {
  final String id;
  final String name;                 
  final List<List<double>> polygon;  
  final int avgRent;                 
  final int avgBuy;                  
  final List<Rating> ratings;

  const AreaFeature({
    required this.id,
    required this.name,
    required this.polygon,
    required this.avgRent,
    required this.avgBuy,
    required this.ratings,
  });
}

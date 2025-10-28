import 'mock_data.dart';
import '../models/area_feature.dart';

class MockApi {
  Future<List<AreaFeature>> fetchAreas() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockAreas;
  }
}

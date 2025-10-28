import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rating.dart';

/// chave base onde guardamos avaliações locais por bairro
const _kLocalRatingsPrefix = 'local_ratings_v1'; // guardamos por areaId

class LocalRatingsStore {
  /// Lê todas as avaliações locais (por areaId)
  Future<Map<String, List<Rating>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('$_kLocalRatingsPrefix:'));
    final Map<String, List<Rating>> out = {};
    for (final k in keys) {
      final areaId = k.split(':').last;
      final raw = prefs.getString(k);
      if (raw != null) {
        final list = (jsonDecode(raw) as List).map((e) {
          final m = e as Map<String, dynamic>;
          return Rating(
            id: m['id'] as String,
            lat: (m['lat'] as num).toDouble(),
            lng: (m['lng'] as num).toDouble(),
            score: m['score'] as int,
            comment: m['comment'] as String?,
          );
        }).toList();
        out[areaId] = list;
      }
    }
    return out;
  }

  /// Adiciona 1 avaliação local a um bairro
  Future<void> add(String areaId, Rating rating) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kLocalRatingsPrefix:$areaId';
    final raw = prefs.getString(key);
    final list = raw != null ? (jsonDecode(raw) as List) : <dynamic>[];
    list.add({
      'id': rating.id,
      'lat': rating.lat,
      'lng': rating.lng,
      'score': rating.score,
      'comment': rating.comment,
    });
    await prefs.setString(key, jsonEncode(list));
  }
}

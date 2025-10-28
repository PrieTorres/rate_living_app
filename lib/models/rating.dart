class Rating {
  final String id;
  final double lat;
  final double lng;
  final int score; // 1..5
  final String? comment;

  Rating({
    required this.id,
    required this.lat,
    required this.lng,
    required this.score,
    this.comment,
  });
}

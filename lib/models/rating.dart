class Rating {
  final String id;
  final double lat;
  final double lng;
  final int score;
  final String? comment;

  /// ID do usuário logado (Firebase Auth)
  final String? userId;

  /// Tipo de local: imóvel, condomínio, bairro, cidade
  final String? locationType;

  /// Endereço textual (rua + número, etc.)
  final String? address;

  /// CEP do local
  final String? cep;

  /// Preço de compra (opcional)
  final double? buyPrice;

  /// Preço de aluguel (opcional)
  final double? rentPrice;

  /// Links de imobiliárias (opcional)
  final List<String> listingLinks;

  /// URLs de fotos (ou referências no Storage) — opcional
  final List<String> photoUrls;

  /// Número de quartos (para imóvel/condomínio) — opcional
  final int? bedrooms;

  /// Área em m² (para imóvel/condomínio) — opcional
  final double? areaM2;

  /// Número de banheiros — opcional
  final int? bathrooms;

  Rating({
    required this.id,
    required this.lat,
    required this.lng,
    required this.score,
    this.comment,
    this.userId,
    this.locationType,
    this.address,
    this.cep,
    this.buyPrice,
    this.rentPrice,
    List<String>? listingLinks,
    List<String>? photoUrls,
    this.bedrooms,
    this.areaM2,
    this.bathrooms,
  })  : listingLinks = listingLinks ?? const [],
        photoUrls = photoUrls ?? const [];
}

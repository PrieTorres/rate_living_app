import 'package:flutter/material.dart';
import '../../models/rating.dart';

class PropertyDetailPage extends StatefulWidget {
  final Rating rating;
  final List<Rating>? reviews;
  const PropertyDetailPage({super.key, required this.rating, this.reviews});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(color: Colors.grey.shade300, child: const Center(child: Icon(Icons.photo, size: 64, color: Colors.white54)));
    }
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

  String _formatPrice(double? buyPrice, double? rentPrice) {
    if (buyPrice != null && buyPrice > 0) {
      return 'R\$ ${buyPrice.toStringAsFixed(0)}';
    }
    if (rentPrice != null && rentPrice > 0) {
      return 'R\$ ${rentPrice.toStringAsFixed(0)}/mês';
    }
    return 'Preço não informado';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rating;
    final photos = r.photoUrls.isNotEmpty ? r.photoUrls : [null];
    final bedrooms = r.bedrooms?.toString() ?? '-';
    final bathrooms = r.bathrooms?.toString() ?? '-';
    final vagas = '-';
    final description = r.comment ?? 'Descrição não disponível.';
    final reviews = widget.reviews ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detalhes do Imóvel', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      final url = photos[index];
                      return _buildImage(url);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(photos.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? Colors.orange : Colors.orange.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatPrice(r.buyPrice, r.rentPrice), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(r.address ?? 'Endereço não informado', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bed, color: Colors.orange, size: 28),
                                  const SizedBox(height: 6),
                                  Text('$bedrooms quartos', style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bathtub, color: Colors.orange, size: 28),
                                  const SizedBox(height: 6),
                                  Text('$bathrooms banheiros', style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_parking, color: Colors.orange, size: 28),
                                  const SizedBox(height: 6),
                                  Text('$vagas vagas', style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Avaliações (${reviews.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.sort, size: 18), label: const Text('Ordenar')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (reviews.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: const [
                              Icon(Icons.reviews, size: 40, color: Colors.orange),
                              SizedBox(height: 8),
                              Text('Nenhuma avaliação ainda.', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('Seja o primeiro a avaliar este imóvel.', style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: reviews.map((rev) {
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.12))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.2), child: Text((rev.userId?.isNotEmpty ?? false) ? rev.userId![0].toUpperCase() : 'U', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700))),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(rev.userId ?? 'Usuário', style: const TextStyle(fontWeight: FontWeight.w700))),
                                      Text(rev.cep ?? '', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: List.generate(5, (i) {
                                      final filled = i < rev.score;
                                      return Icon(filled ? Icons.star : Icons.star_border, color: Colors.orange, size: 18);
                                    }),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(rev.comment ?? '', style: const TextStyle(color: Colors.black87)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abrir fluxo para adicionar avaliação')));
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                child: Text('Adicionar Avaliação', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
              ),
            ),
          )
        ],
      ),
    );
  }
}

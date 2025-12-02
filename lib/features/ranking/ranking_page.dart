import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/area_feature.dart';
import '../../models/rating.dart';
import '../map/map_controller.dart';

enum RankingTab { city, neighborhood, property }

class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> {
  RankingTab _tab = RankingTab.city;
  String? _selectedCity = 'Jaraguá do Sul';
  AreaFeature? _selectedArea;

  @override
  Widget build(BuildContext context) {
    final areasAsync = ref.watch(areasProvider);

    const primary = Color(0xFFE46B3F);
    const bgLight = Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Rankings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Busca de rankings será implementada depois.')));
          }),
        ],
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: _buildSegmentedControl(primary)),
          Expanded(
            child: areasAsync.when(
              data: (areas) {
                if (areas.isEmpty) {
                  return const Center(child: Text('Nenhum bairro cadastrado ainda.'));
                }
                switch (_tab) {
                  case RankingTab.city:
                    return _buildCityView(context, areas);
                  case RankingTab.neighborhood:
                    return _buildNeighborhoodView(context, areas);
                  case RankingTab.property:
                    return _buildPropertyView(context, areas);
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Erro ao carregar rankings: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(Color primary) {
    const secondaryContainer = Color(0xFFE8E6D8);
    const onSecondary = Color(0xFF5F534E);

    Widget buildTab(RankingTab tab, String label) {
      final selected = _tab == tab;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _tab = tab;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? primary : secondaryContainer,
              borderRadius: BorderRadius.circular(999),
              boxShadow: selected
                  ? [BoxShadow(color: Colors.black.withOpacity(0.12), offset: const Offset(0, 2), blurRadius: 4)]
                  : [],
            ),
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : onSecondary)),
          ),
        ),
      );
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: secondaryContainer.withOpacity(0.7), borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          buildTab(RankingTab.city, 'Cidade'),
          const SizedBox(width: 4),
          buildTab(RankingTab.neighborhood, 'Bairro'),
          const SizedBox(width: 4),
          buildTab(RankingTab.property, 'Imóveis'),
        ],
      ),
    );
  }

  Widget _buildCityView(BuildContext context, List<AreaFeature> areas) {
    final allRatings = areas.expand((a) => a.ratings).toList();
    final totalCount = allRatings.length;
    final avg = totalCount == 0 ? 0.0 : allRatings.map((r) => r.score).fold<int>(0, (sum, v) => sum + v) / totalCount;
    final formattedAvg = avg.toStringAsFixed(1);

    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          _FilterChipButton(icon: Icons.filter_list, label: 'Filtros', onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Filtros avançados serão adicionados depois.')));
          }),
        ]),
      ),
      const SizedBox(height: 4),
      _CityCard(cityName: _selectedCity ?? 'Jaraguá do Sul', average: formattedAvg, reviewsCount: totalCount, onTap: () {
        _onSelectCity(_selectedCity ?? 'Jaraguá do Sul');
      }),
    ]);
  }

  void _onSelectCity(String cityName) {
    setState(() {
      _selectedCity = cityName;
      _selectedArea = null;
      _tab = RankingTab.neighborhood;
    });
  }

  Widget _buildNeighborhoodView(BuildContext context, List<AreaFeature> areas) {
    final items = <_NeighborhoodRankingItem>[];
    for (final a in areas) {
      final count = a.ratings.length;
      final avg = count == 0 ? 0.0 : a.ratings.fold<int>(0, (s, r) => s + r.score) / count;
      items.add(_NeighborhoodRankingItem(area: a, averageScore: avg, ratingCount: count));
    }
    items.sort((a, b) => b.averageScore.compareTo(a.averageScore));

    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          _FilterChipButton(icon: Icons.attach_money, label: 'Preço', onTap: () {}),
          const SizedBox(width: 8),
          _FilterChipButton(icon: Icons.home_outlined, label: 'Tipo', onTap: () {}),
          const SizedBox(width: 8),
          _FilterChipButton(icon: Icons.bed_outlined, label: 'Quartos', onTap: () {}),
          const SizedBox(width: 8),
          _FilterChipButton(icon: Icons.square_foot, label: 'Área (m²)', onTap: () {}),
        ]),
      ),
      const SizedBox(height: 4),
      if (_selectedCity != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _FilterTagChip(icon: Icons.location_city, label: _selectedCity!, onDeleted: () {
            setState(() {
              _selectedCity = null;
              _selectedArea = null;
              _tab = RankingTab.city;
            });
          }),
        ),
      ...items.map((item) => _NeighborhoodCard(item: item, onTap: () {
            setState(() {
              _selectedArea = item.area;
              _selectedCity ??= 'Jaraguá do Sul';
              _tab = RankingTab.property;
            });
          })).toList()
    ]);
  }

  Widget _buildPropertyView(BuildContext context, List<AreaFeature> areas) {
    final entries = <_PropertyEntry>[];
    for (final a in areas) {
      for (final r in a.ratings) {
        entries.add(_PropertyEntry(area: a, rating: r));
      }
    }
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.info_outline, size: 40, color: Colors.grey),
            SizedBox(height: 12),
            Text('Ainda não há avaliações para listar imóveis.', textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    Iterable<_PropertyEntry> filtered = entries;
    if (_selectedArea != null) {
      filtered = filtered.where((e) => e.area.id == _selectedArea!.id);
    }
    final sorted = filtered.toList()..sort((a, b) => b.rating.score.compareTo(a.rating.score));
    final top = sorted.take(100).toList();

    if (top.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.info_outline, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_selectedArea == null ? 'Ainda não há avaliações para listar imóveis.' : 'Ainda não há imóveis avaliados em ${_selectedArea!.name}.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (_selectedArea != null)
              ElevatedButton.icon(onPressed: () {
                setState(() {
                  _selectedArea = null;
                });
              }, icon: const Icon(Icons.clear), label: const Text('Limpar filtro de bairro')),
          ]),
        ),
      );
    }

    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          _FilterChipButton(icon: Icons.attach_money, label: 'Preço', onTap: () {}),
          const SizedBox(width: 8),
          _FilterChipButton(icon: Icons.home_outlined, label: 'Tipo', onTap: () {}),
          const SizedBox(width: 8),
          _FilterChipButton(icon: Icons.bed_outlined, label: 'Quartos', onTap: () {}),
          const SizedBox(width: 8),
          _FilterChipButton(icon: Icons.square_foot, label: 'Área (m²)', onTap: () {}),
        ]),
      ),
      const SizedBox(height: 4),
      if (_selectedCity != null || _selectedArea != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(spacing: 8, children: [
            if (_selectedCity != null) _FilterTagChip(icon: Icons.location_city, label: _selectedCity!, onDeleted: () {
              setState(() {
                _selectedCity = null;
                _selectedArea = null;
                _tab = RankingTab.city;
              });
            }),
            if (_selectedArea != null) _FilterTagChip(icon: Icons.house, label: _selectedArea!.name, onDeleted: () {
              setState(() {
                _selectedArea = null;
              });
            }),
          ]),
        ),
      ...top.map((e) {
        return _PropertyCard(
          entry: e,
          onTap: () {
            Navigator.of(context).pushNamed('/property', arguments: e.rating);
          },
        );
      }).toList(),
    ]);
  }
}

class _FilterChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FilterChipButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [Icon(icon, size: 16), const SizedBox(width: 8), Text(label)]),
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  final String cityName;
  final String average;
  final int reviewsCount;
  final VoidCallback onTap;
  const _CityCard({required this.cityName, required this.average, required this.reviewsCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(cityName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('$reviewsCount avaliações', style: const TextStyle(color: Colors.black54))])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(average, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Text('Média', style: TextStyle(color: Colors.black45))]),
          ],
        ),
      ),
    );
  }
}

class _FilterTagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onDeleted;
  const _FilterTagChip({required this.icon, required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onDeleted: onDeleted,
      backgroundColor: Colors.grey.shade100,
    );
  }
}

class _NeighborhoodRankingItem {
  final AreaFeature area;
  final double averageScore;
  final int ratingCount;
  _NeighborhoodRankingItem({required this.area, required this.averageScore, required this.ratingCount});
}

class _NeighborhoodCard extends StatelessWidget {
  final _NeighborhoodRankingItem item;
  final VoidCallback onTap;
  const _NeighborhoodCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.area.name, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('${item.ratingCount} avaliações • Média ${item.averageScore.toStringAsFixed(1)}', style: const TextStyle(color: Colors.black54))])),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _PropertyEntry {
  final AreaFeature area;
  final Rating rating;
  _PropertyEntry({required this.area, required this.rating});
}

class _PropertyCard extends StatelessWidget {
  final _PropertyEntry entry;
  final VoidCallback onTap;
  const _PropertyCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = entry.rating;
    final thumb = r.photoUrls.isNotEmpty ? r.photoUrls.first : null;
    final score = r.score;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8), image: thumb != null ? DecorationImage(image: NetworkImage(thumb), fit: BoxFit.cover) : null),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.address ?? entry.area.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(entry.area.name, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Row(children: List.generate(5, (i) {
                  final filled = i < score;
                  return Icon(filled ? Icons.star : Icons.star_border, color: Colors.orange, size: 16);
                })),
              ]),
            ),
            const SizedBox(width: 8),
            Column(children: [Text('⭐ ${score.toString()}', style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), const Icon(Icons.chevron_right)]),
          ],
        ),
      ),
    );
  }
}

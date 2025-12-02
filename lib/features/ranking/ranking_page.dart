import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/area_feature.dart';
import '../map/map_controller.dart';

enum RankingTab { city, neighborhood, property }

class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> {
  RankingTab _tab = RankingTab.city;
  String? _selectedCity;
  AreaFeature? _selectedArea;

  // Helper: extrai "Bairro, Cidade" a partir do endereço completo
  String _extractDistrictCity(String? address, String defaultValue) {
    if (address == null || address.isEmpty) {
      return defaultValue;
    }
    // Ex.: "Rua X, 123 - Bairro, Cidade - UF, CEP, Brasil"
    final dashParts = address.split(' - ');
    if (dashParts.length >= 3) {
      return dashParts[1].trim();
    }
    // fallback: tenta pegar último "Bairro, Cidade"
    final commaParts = address.split(',');
    if (commaParts.length >= 3) {
      final district = commaParts[commaParts.length - 3].trim();
      final cityPart = commaParts[commaParts.length - 2];
      final cityPieces = cityPart.split(' - ');
      final city = cityPieces.first.trim();
      return '$district, $city';
    }
    return defaultValue;
    }

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Rankings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Busca de rankings será implementada depois.'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _buildSegmentedControl(primary),
          ),
          Expanded(
            child: areasAsync.when(
              data: (areas) {
                if (areas.isEmpty) {
                  return const Center(
                    child: Text('Nenhum bairro cadastrado ainda.'),
                  );
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Text('Erro ao carregar rankings: $e'),
              ),
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
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      )
                    ]
                  : [],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : onSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: secondaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
      ),
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
    final avg = totalCount == 0
        ? 0.0
        : allRatings
                .map((r) => r.score)
                .fold<int>(0, (sum, v) => sum + v) /
            totalCount;

    final formattedAvg = avg.toStringAsFixed(1);
    final cityName = _selectedCity ?? 'Cidade';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              _FilterChipButton(
                icon: Icons.filter_list,
                label: 'Filtros',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Filtros avançados serão adicionados depois.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _CityCard(
          cityName: cityName,
          average: formattedAvg,
          reviewsCount: totalCount,
          onTap: () {
            _onSelectCity(cityName);
          },
        ),
      ],
    );
  }

  void _onSelectCity(String cityName) {
    setState(() {
      _selectedCity = cityName;
      _selectedArea = null;
      _tab = RankingTab.neighborhood;
    });
  }

  Widget _buildNeighborhoodView(
      BuildContext context, List<AreaFeature> areas) {
    final items = <_NeighborhoodRankingItem>[];

    for (final a in areas) {
      final count = a.ratings.length;
      final avg =
          count == 0 ? 0.0 : a.ratings.fold<int>(0, (s, r) => s + r.score) / count;
      items.add(
        _NeighborhoodRankingItem(
          area: a,
          averageScore: avg,
          ratingCount: count,
        ),
      );
    }

    items.sort((a, b) => b.averageScore.compareTo(a.averageScore));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              _FilterChipButton(
                icon: Icons.attach_money,
                label: 'Preço',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _FilterChipButton(
                icon: Icons.home_outlined,
                label: 'Tipo',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _FilterChipButton(
                icon: Icons.bed_outlined,
                label: 'Quartos',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _FilterChipButton(
                icon: Icons.square_foot,
                label: 'Área (m²)',
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (_selectedCity != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FilterTagChip(
              icon: Icons.location_city,
              label: _selectedCity!,
              onDeleted: () {
                setState(() {
                  _selectedCity = null;
                  _selectedArea = null;
                  _tab = RankingTab.city;
                });
              },
            ),
          ),
        ...items.map(
          (item) => _NeighborhoodCard(
            item: item,
            onTap: () {
              setState(() {
                _selectedArea = item.area;
                _tab = RankingTab.property;
              });
            },
          ),
        ),
      ],
    );
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.info_outline, size: 40, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Ainda não há avaliações para listar imóveis.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    Iterable<_PropertyEntry> filtered = entries;

    if (_selectedArea != null) {
      filtered = filtered.where((e) => e.area.id == _selectedArea!.id);
    }

    final sorted = filtered.toList()
      ..sort((a, b) => b.rating.score.compareTo(a.rating.score));
    final top = sorted.take(100).toList();

    if (top.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 40, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                _selectedArea == null
                    ? 'Ainda não há avaliações para listar imóveis.'
                    : 'Ainda não há imóveis avaliados em ${_selectedArea!.name}.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_selectedArea != null)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedArea = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpar filtro de bairro'),
                ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              _FilterChipButton(
                icon: Icons.attach_money,
                label: 'Preço',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _FilterChipButton(
                icon: Icons.home_outlined,
                label: 'Tipo',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _FilterChipButton(
                icon: Icons.bed_outlined,
                label: 'Quartos',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _FilterChipButton(
                icon: Icons.square_foot,
                label: 'Área (m²)',
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_selectedCity != null)
              _FilterTagChip(
                icon: Icons.location_city,
                label: _selectedCity!,
                onDeleted: () {
                  setState(() {
                    _selectedCity = null;
                    _selectedArea = null;
                    _tab = RankingTab.city;
                  });
                },
              ),
            if (_selectedArea != null)
              _FilterTagChip(
                icon: Icons.location_on,
                label: _selectedArea!.name,
                onDeleted: () {
                  setState(() {
                    _selectedArea = null;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...top.map(
          (entry) {
            final rating = entry.rating;
            final addr = rating.address;
            final displayName = _extractDistrictCity(addr, entry.area.name);
            return _PropertyCard(
              areaName: displayName,
              score: rating.score,
              comment: rating.comment,
            );
          },
        ),
      ],
    );
  }
}

class _NeighborhoodRankingItem {
  final AreaFeature area;
  final double averageScore;
  final int ratingCount;

  _NeighborhoodRankingItem({
    required this.area,
    required this.averageScore,
    required this.ratingCount,
  });
}

class _PropertyEntry {
  final AreaFeature area;
  final dynamic rating;

  _PropertyEntry({
    required this.area,
    required this.rating,
  });
}

class _FilterChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const secondaryContainer = Color(0xFFE8E6D8);
    const onSurface = Color(0xFF4E423D);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: onSurface),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 18, color: onSurface),
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

  const _FilterTagChip({
    required this.icon,
    required this.label,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFE46B3F);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 300,
      ),
      child: IntrinsicWidth(
        child: Container(
          height: 36,
          padding: const EdgeInsets.only(left: 10, right: 4),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDeleted,
                icon: const Icon(Icons.cancel, size: 18, color: primary),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 28, height: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  final String cityName;
  final String average;
  final int reviewsCount;
  final VoidCallback onTap;

  const _CityCard({
    required this.cityName,
    required this.average,
    required this.reviewsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFF8F8F8);
    const secondaryContainer = Color(0xFFE8E6D8);
    const onSurface = Color(0xFF4E423D);
    const onSecondary = Color(0xFF5F534E);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 4,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.location_city,
                size: 32,
                color: onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cityName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 18,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        average,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: onSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviewsCount avaliações)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: onSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: onSecondary),
          ],
        ),
      ),
    );
  }
}

class _NeighborhoodCard extends StatelessWidget {
  final _NeighborhoodRankingItem item;
  final VoidCallback onTap;

  const _NeighborhoodCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFF8F8F8);
    const secondaryContainer = Color(0xFFE8E6D8);
    const onSurface = Color(0xFF4E423D);
    const onSecondary = Color(0xFF5F534E);

    final avgStr = item.averageScore.toStringAsFixed(1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 4,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.home_work,
                size: 32,
                color: onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.area.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 18,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        avgStr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: onSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${item.ratingCount} avaliações)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: onSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: onSecondary),
          ],
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final String areaName;
  final int score;
  final String? comment;

  const _PropertyCard({
    required this.areaName,
    required this.score,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFF8F8F8);
    const border = Color(0x1F000000);
    const onSurface = Color(0xFF4E423D);
    const onSecondary = Color(0xFF5F534E);

    final stars = '⭐' * score + '☆' * (5 - score);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 4,
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 40,
                color: Colors.grey,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Imóvel em $areaName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '$score.0',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: onSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stars,
                      style: const TextStyle(
                        fontSize: 12,
                        color: onSecondary,
                      ),
                    ),
                  ],
                ),
                if (comment != null && comment!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    comment!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: onSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

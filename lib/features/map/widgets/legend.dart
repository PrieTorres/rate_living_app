import 'package:flutter/material.dart';
import 'package:rate_living_app/features/map/map_controller.dart';
import '../../../models/area_feature.dart';
import '../../../utils/price_color.dart';

class Legend extends StatelessWidget {
  final PriceMode mode;
  const Legend({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final items = legend(mode);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Média por bairro (${mode == Mode.rent ? 'aluguel' : 'compra'})',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (it) => Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Color(it['color']),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(it['label']),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

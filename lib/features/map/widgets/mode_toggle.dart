import 'package:flutter/material.dart';
import 'package:rate_living_app/features/map/map_controller.dart';
import '../../../models/area_feature.dart';

class ModeToggle extends StatelessWidget {
  final PriceMode value;
  final ValueChanged<PriceMode> onChanged;
  const ModeToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(context, 'Aluguel', PriceMode.rent),
          _button(context, 'Compra', PriceMode.buy),
        ],
      ),
    );
  }

  Widget _button(BuildContext ctx, String label, PriceMode m) {
    final selected = value == m;
    return InkWell(
      onTap: () => onChanged(m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Theme.of(ctx).colorScheme.primary : Colors.white,
          borderRadius: m == Mode.rent
              ? const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12))
              : const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

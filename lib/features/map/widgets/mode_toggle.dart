import 'package:flutter/material.dart';
import '../../../models/area_feature.dart';

class ModeToggle extends StatelessWidget {
  final Mode value;
  final ValueChanged<Mode> onChanged;
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
          _button(context, 'Aluguel', Mode.rent),
          _button(context, 'Compra', Mode.buy),
        ],
      ),
    );
  }

  Widget _button(BuildContext ctx, String label, Mode m) {
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

import '../models/area_feature.dart';

const _stopsRent = [1500, 2200, 2800, 3500];
const _stopsBuy  = [300000, 360000, 420000, 550000];

const _palette = [
  0xFFE1F5FE,
  0xFF81D4FA,
  0xFF29B6F6,
  0xFF0288D1,
  0xFF01579B,
];

int priceToColor(Mode mode, int value) {
  final s = mode == Mode.rent ? _stopsRent : _stopsBuy;
  if (value <= s[0]) return _palette[0];
  if (value <= s[1]) return _palette[1];
  if (value <= s[2]) return _palette[2];
  if (value <= s[3]) return _palette[3];
  return _palette[4];
}

List<Map<String, dynamic>> legend(Mode mode) {
  final s = mode == Mode.rent ? _stopsRent : _stopsBuy;
  String fmt(num n) => 'R\$ ${n.toStringAsFixed(0)}';
  return [
    { 'label': '≤ ${fmt(s[0])}', 'color': _palette[0] },
    { 'label': '${fmt(s[0]+1)}–${fmt(s[1])}', 'color': _palette[1] },
    { 'label': '${fmt(s[1]+1)}–${fmt(s[2])}', 'color': _palette[2] },
    { 'label': '${fmt(s[2]+1)}–${fmt(s[3])}', 'color': _palette[3] },
    { 'label': '> ${fmt(s[3])}', 'color': _palette[4] },
  ];
}

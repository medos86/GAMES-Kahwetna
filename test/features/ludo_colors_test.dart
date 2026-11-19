import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';

const _cream = Color(0xFFFFF8E7);

double _lin(double v) {
  if (v <= 0.03928) return v / 12.92;
  return math.pow((v + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color c) =>
    0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

double _distance(Color a, Color b) {
  final dr = a.r - b.r;
  final dg = a.g - b.g;
  final db = a.b - b.b;
  return math.sqrt(dr * dr + dg * dg + db * db);
}

void main() {
  test('#597 : les quatre couleurs de joueurs sont bien distinctes', () {
    final colors = kLudoFills.values.toList();
    for (var i = 0; i < colors.length; i++) {
      for (var j = i + 1; j < colors.length; j++) {
        expect(_distance(colors[i], colors[j]), greaterThan(0.2));
      }
    }
  });

  test('#597 : chaque couleur de joueur reste lisible sur le crème', () {
    for (final color in kLudoFills.values) {
      expect(_contrast(color, _cream), greaterThanOrEqualTo(2));
    }
  });
}

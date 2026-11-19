import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';

double _lin(double v) {
  if (v <= 0.03928) return v / 12.92;
  return math.pow((v + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color c) {
  return 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('#596 : étoile des cases sûres, contraste ≥ 3:1 sur le crème', () {
    // Fond crème du plateau Ludo (ludo_screen.dart, _cream).
    const cream = Color(0xFFFFF8E7);
    expect(_contrast(kLudoSafeStarColor, cream), greaterThanOrEqualTo(3));
  });
}

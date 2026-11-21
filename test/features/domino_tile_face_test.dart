// Pierres de domino intégrées au tapis (#686) : pas de blanc isolé, points lisibles (WCAG AA).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/domino/domino_tiles.dart';

double _channel(double v) {
  if (v <= 0.03928) {
    return v / 12.92;
  }
  return math.pow((v + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color c) {
  return 0.2126 * _channel(c.r) +
      0.7152 * _channel(c.g) +
      0.0722 * _channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('#686 : les points restent lisibles sur la face', () {
    final ratio = _contrast(dominoPipColor, dominoFaceColor);
    expect(ratio, greaterThanOrEqualTo(4.5));
  });

  test('#686 : la face n est plus un blanc crème isolé', () {
    expect(dominoFaceColor, isNot(const Color(0xFFFFF9E9)));
    expect(dominoFaceColor, isNot(Colors.white));
  });
}

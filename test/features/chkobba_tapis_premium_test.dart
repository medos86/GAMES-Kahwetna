// Tapis Chkobba bleu premium à nuances (#955).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/scoba_palette.dart';

void main() {
  test('#955 : le tapis est un dégradé radial bleu', () {
    final deco = ScobaPalette.tapisPremiumDecoration;
    final gradient = deco.gradient! as RadialGradient;
    expect(gradient.colors.length, 3);
    for (final c in gradient.colors) {
      expect(c.b, greaterThan(c.r), reason: 'teinte bleue');
      expect(c.b, greaterThan(c.g), reason: 'teinte bleue');
    }
  });

  test('#955 : les nuances vont du bleu roi au bleu nuit', () {
    final luminance = [
      ScobaPalette.tapisBleuRoi,
      ScobaPalette.tapisBleuMilieu,
      ScobaPalette.tapisBleuNuit,
    ].map((c) => c.computeLuminance()).toList();
    expect(luminance[0], greaterThan(luminance[1]));
    expect(luminance[1], greaterThan(luminance[2]));
  });
}

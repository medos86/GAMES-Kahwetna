import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/comic_palette.dart';
import 'package:kahwetne/core/theme/game_style.dart';

/// Issue #311 : le tapis Chkobba (style cartoon) doit contraster avec ses motifs.
void main() {
  const style = GameStyle.cartoon;

  test('le tapis n\'est plus violet (teinte bleue tunisienne)', () {
    final hsl = HSLColor.fromColor(style.felt);
    expect(hsl.hue, inInclusiveRange(190, 230));
  });

  test('zellige lisible sur le tapis', () {
    expect(
      contrastRatio(style.zellige, style.felt),
      greaterThanOrEqualTo(3.0),
    );
  });

  test('accent blanc lisible sur le tapis', () {
    expect(
      contrastRatio(style.zelligeAccent, style.felt),
      greaterThanOrEqualTo(3.0),
    );
  });
}

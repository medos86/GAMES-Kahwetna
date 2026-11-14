import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/comic_palette.dart';
import 'package:kahwetne/core/theme/scoba_palette.dart';

/// Issue #289 : la palette Scoba doit rester lisible (WCAG AA, contraste ≥ 4,5).
void main() {
  const minContrast = 4.5;

  test('encre sur tapis clair', () {
    expect(
      contrastRatio(ScobaPalette.ink, ScobaPalette.felt),
      greaterThanOrEqualTo(minContrast),
    );
    expect(
      contrastRatio(ScobaPalette.ink, ScobaPalette.feltDeep),
      greaterThanOrEqualTo(minContrast),
    );
  });

  test('encre sur papier des panneaux', () {
    expect(
      contrastRatio(ScobaPalette.ink, ScobaPalette.panel),
      greaterThanOrEqualTo(minContrast),
    );
  });

  test('scores bleu et rouge sur papier et sur blanc', () {
    for (final bg in [ScobaPalette.panel, Colors.white]) {
      expect(
        contrastRatio(ScobaPalette.blueText, bg),
        greaterThanOrEqualTo(minContrast),
      );
      expect(
        contrastRatio(ScobaPalette.redText, bg),
        greaterThanOrEqualTo(minContrast),
      );
    }
  });

  test('encre sur jaune des badges', () {
    expect(
      contrastRatio(ScobaPalette.ink, ScobaPalette.yellow),
      greaterThanOrEqualTo(minContrast),
    );
  });
}

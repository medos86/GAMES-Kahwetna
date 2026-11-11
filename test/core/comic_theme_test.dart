import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/comic_palette.dart';
import 'package:kahwetne/core/theme/comic_theme.dart';

void main() {
  test('texte encre sur papier : contraste >= 4,5', () {
    expect(contrastRatio(ComicPalette.ink, ComicPalette.paper), greaterThanOrEqualTo(4.5));
  });

  test('texte encre sur jaune (bouton) : contraste >= 4,5', () {
    expect(contrastRatio(ComicPalette.ink, ComicPalette.yellow), greaterThanOrEqualTo(4.5));
  });

  test('le thème utilise la palette BD', () {
    final theme = buildComicTheme();
    expect(theme.scaffoldBackgroundColor, ComicPalette.paper);
    expect(theme.colorScheme.onSurface, ComicPalette.ink);
    expect(theme.colorScheme.primary, ComicPalette.yellow);
  });

  test('contrastRatio est symétrique et vaut 21 pour noir sur blanc', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrastRatio(Colors.white, Colors.black), closeTo(21, 0.01));
  });
}

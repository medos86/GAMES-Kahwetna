import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/comic_palette.dart';
import 'package:kahwetne/core/theme/game_style.dart';

/// Issue #324 : tapis Chkobba en couleur BD comics, sans motif zellige.
void main() {
  const style = GameStyle.cartoon;

  test('zellige retiré du tapis', () {
    expect(style.showZellige, isFalse);
  });

  test('tapis en couleur BD (rouge comics)', () {
    expect(style.felt, ComicPalette.red);
  });

  test('tapis lisible sur le papier BD', () {
    expect(
      contrastRatio(ComicPalette.paper, style.felt),
      greaterThanOrEqualTo(3.0),
    );
  });
}

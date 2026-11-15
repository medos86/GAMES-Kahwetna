import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

/// Issue #392 : le tapis affiche davantage de cartes sans défiler.
void main() {
  test('un tapis de 6 paquets tient avec de plus grandes cartes', () {
    final sizes = [3, 3, 3, 3, 3, 3];
    final tight = ramiTableCardWidth(sizes, 320, 260, 80);
    expect(tight, greaterThanOrEqualTo(60));
  });

  test('un tapis vide garde la largeur demandée', () {
    expect(ramiTableCardWidth(const [], 320, 260, 80), 80);
  });
}

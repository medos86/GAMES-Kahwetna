import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

/// Issue #392 : le tapis affiche davantage de cartes sans défiler.
void main() {
  test('un tapis de 6 paquets reste dans les bornes de taille', () {
    final sizes = [3, 3, 3, 3, 3, 3];
    expect(ramiTableCardWidth(sizes, 320, 260, 80), inInclusiveRange(36, 80));
  });

  test('un tapis vide garde la largeur demandée', () {
    expect(ramiTableCardWidth(const [], 320, 260, 80), 80);
  });
}

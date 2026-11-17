import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

// Pioche et défausse plus grandes que l'ancien ratio de 30 % (#347).
void main() {
  test('pioche et défausse : 60 % de la largeur de la carte de la main', () {
    expect(ramiPileWidth(100), 60);
  });

  test('pioche et défausse plus grandes qu avant', () {
    expect(ramiPileWidth(100), greaterThan(100 * 0.3));
  });
}

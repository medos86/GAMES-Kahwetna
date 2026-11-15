import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

// Pioche et défausse plus grandes que l'ancien ratio de 30 % (#347).
void main() {
  test('pioche et défausse : 40 % de la largeur d une carte de la main', () {
    expect(ramiPileWidth(100), 40);
  });

  test('pioche et défausse plus grandes qu avant', () {
    expect(ramiPileWidth(100), greaterThan(100 * 0.3));
  });
}

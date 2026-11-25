// La main du joueur ne déborde jamais la largeur et ne défile pas (#922).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

void main() {
  test('la main tient sur la largeur quel que soit le nombre de cartes (#922)', () {
    for (var n = 1; n <= 25; n++) {
      final step = ramiHandStep(n, 100, 400);
      final total = n == 0 ? 0.0 : 100 + step * (n - 1);
      expect(total, lessThanOrEqualTo(400 + 1e-9), reason: '$n cartes');
    }
  });

  test('pas jamais négatif (#922)', () {
    expect(ramiHandStep(40, 100, 300), greaterThanOrEqualTo(0));
  });
}

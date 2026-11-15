import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

/// Issue #314 : les cartes de la main du joueur sont plus grandes qu'avant (1,35).
void main() {
  test('cartes de la main agrandies', () {
    expect(ramiHandCardScale, greaterThan(1.35));
  });
}

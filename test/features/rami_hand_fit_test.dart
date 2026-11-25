import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

/// Issue #906 : cartes de la main réduites pour tenir sur le tapis, et place
/// réservée au-dessus pour qu'une carte sélectionnée qui monte ne soit pas tronquée.
void main() {
  test('cartes de la main moins grandes qu avant (#906)', () {
    expect(ramiHandCardScale, lessThan(1.85));
    expect(ramiHandCardScale, greaterThan(1.35));
  });

  test('remontée de la carte sélectionnée modeste (#906)', () {
    expect(ramiSelectLift, greaterThan(0));
    expect(ramiSelectLift, lessThanOrEqualTo(0.3));
  });
}

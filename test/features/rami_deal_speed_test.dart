import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

// Distribution ralentie (#876) : constantes de rythme du tour de table.
void main() {
  test('la distribution est plus lente qu\'avant', () {
    expect(
      ramiDealStep,
      greaterThanOrEqualTo(const Duration(milliseconds: 200)),
    );
    expect(
      ramiDealSeatStagger,
      greaterThanOrEqualTo(const Duration(milliseconds: 60)),
    );
    expect(
      ramiDealFlight,
      greaterThanOrEqualTo(const Duration(milliseconds: 400)),
    );
  });

  test('dans un tour, les sièges se succèdent avant le tour suivant', () {
    expect(ramiDealSeatStagger < ramiDealStep, isTrue);
  });
}

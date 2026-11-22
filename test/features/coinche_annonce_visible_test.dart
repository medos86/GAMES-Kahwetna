import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/coinche/coinche_screen.dart';
import 'package:kahwetne/game/coinche.dart';

/// Issue #733 : l'annonce reste visible sur la place de l'annonceur pendant le jeu.
void main() {
  test('libellé : valeur, couleur, équipe', () {
    const c = Contract(
      seat: Seat.north,
      value: 130,
      mode: CoincheSuit.coupes,
      multiplier: 1,
    );
    expect(coincheContractLabel(c), '130 ♥ · Nous');
  });

  test('libellé : multiplicateur contré, équipe adverse', () {
    const c = Contract(
      seat: Seat.west,
      value: 80,
      mode: CoincheSuit.epees,
      multiplier: 2,
    );
    expect(coincheContractLabel(c), '80 ♠ ×2 · Eux');
  });
}

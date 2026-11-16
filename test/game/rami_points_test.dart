import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

// Valeur des paquets selon leur position (#422) et valeur en main (#416).
RamiCard _c(RamiSuit suit, int rank, [String? id]) =>
    RamiCard(id: id ?? '${suit.name}-$rank', suit: suit, rank: rank);

const _joker = RamiCard(id: 'joker', suit: null, rank: 0);

void main() {
  test('A-K-Q-J-10-9 de la même couleur vaut 59', () {
    final cards = [
      _c(RamiSuit.epees, 1),
      _c(RamiSuit.epees, 13),
      _c(RamiSuit.epees, 12),
      _c(RamiSuit.epees, 11),
      _c(RamiSuit.epees, 10),
      _c(RamiSuit.epees, 9),
    ];
    expect(pointsOf(cards), 59);
  });

  test('suite basse A-2-3 : l as vaut 1', () {
    final cards = [
      _c(RamiSuit.deniers, 1),
      _c(RamiSuit.deniers, 2),
      _c(RamiSuit.deniers, 3),
    ];
    expect(pointsOf(cards), 6);
  });

  test('brelan d as : chaque as vaut 10', () {
    final cards = [
      _c(RamiSuit.epees, 1),
      _c(RamiSuit.coupes, 1),
      _c(RamiSuit.batons, 1),
    ];
    expect(pointsOf(cards), 30);
  });

  test('le joker vaut la carte qu il remplace (roi dans une suite haute)', () {
    final cards = [
      _c(RamiSuit.epees, 9),
      _c(RamiSuit.epees, 10),
      _c(RamiSuit.epees, 11),
      _c(RamiSuit.epees, 12),
      _joker,
      _c(RamiSuit.epees, 1),
    ];
    // 9 + 10 + J + Q + K (joker) + A (haut) = 9 + 10*5
    expect(pointsOf(cards), 59);
  });

  test('le joker vaut l as quand il remplace l as bas', () {
    final cards = [_joker, _c(RamiSuit.coupes, 2), _c(RamiSuit.coupes, 3)];
    expect(pointsOf(cards), 6);
  });

  test('le joker dans un brelan de rois vaut 10', () {
    final cards = [
      _c(RamiSuit.epees, 13),
      _c(RamiSuit.coupes, 13),
      _joker,
    ];
    expect(pointsOf(cards), 30);
  });

  test('en main : as = 1 et joker = 20 (#416)', () {
    expect(handPointsOf([_c(RamiSuit.epees, 1), _joker]), 21);
  });

  test('un ensemble invalide compte ses cartes en main', () {
    expect(pointsOf([_c(RamiSuit.epees, 1), _c(RamiSuit.epees, 13)]), 11);
  });
}

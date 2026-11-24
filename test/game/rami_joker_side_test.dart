// Joker posé à droite d'une suite = carte la plus haute (issue #838).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard _c(RamiSuit suit, int rank) =>
    RamiCard(id: '${suit.name}-$rank', suit: suit, rank: rank);

const _joker = RamiCard(id: 'joker-0', suit: null, rank: 0);

void main() {
  groupJokerSideTests();
  final fiveSixSeven = [
    _c(RamiSuit.coupes, 5),
    _c(RamiSuit.coupes, 6),
    _c(RamiSuit.coupes, 7),
  ];

  test('joker à droite : il prend la carte la plus haute (8)', () {
    final arranged = arrangeMeld([...fiveSixSeven, _joker]);
    expect(arranged.last.isJoker, isTrue);
    expect(pointsOf(arranged), 5 + 6 + 7 + 8);
  });

  test('joker à gauche : il prend la carte la plus basse (4)', () {
    final arranged = arrangeMeld([_joker, ...fiveSixSeven]);
    expect(arranged.first.isJoker, isTrue);
    expect(pointsOf(arranged), 4 + 5 + 6 + 7);
  });

  test('la position du joker reste à droite quand on ajoute une carte', () {
    final right = arrangeMeld([...fiveSixSeven, _joker]);
    final extended = arrangeMeld(extendMeld(right, _c(RamiSuit.coupes, 8)));
    expect(isValidMeld(extended), isTrue);
    expect(extended.last.isJoker, isTrue);
    expect(pointsOf(extended), 5 + 6 + 7 + 8 + 9);
  });

  test('extendMeld sans joker en fin de liste ajoute la carte à la fin', () {
    final cards = extendMeld(fiveSixSeven, _c(RamiSuit.coupes, 8));
    expect(cards.last.rank, 8);
  });
}

// #844 : le côté du joker suit sa position dans l'ordre de la main, pas le dernier élément.
void groupJokerSideTests() {
  final fourFiveSix = [
    _c(RamiSuit.coupes, 4),
    _c(RamiSuit.coupes, 5),
    _c(RamiSuit.coupes, 6),
  ];

  test('4-5-6 + joker à droite du 6 : le joker vaut 7, pas 3', () {
    final arranged = arrangeMeld([...fourFiveSix, _joker]);
    expect(arranged.last.isJoker, isTrue);
    expect(pointsOf(arranged), 4 + 5 + 6 + 7);
  });

  test('joker placé avant le 4 : il reste à gauche et vaut 3', () {
    final arranged = arrangeMeld([_joker, ...fourFiveSix]);
    expect(arranged.first.isJoker, isTrue);
    expect(pointsOf(arranged), 3 + 4 + 5 + 6);
  });

  test('joker au milieu de la main (entre 4 et 5) reste à gauche', () {
    final arranged = arrangeMeld([
      fourFiveSix[0],
      _joker,
      fourFiveSix[1],
      fourFiveSix[2],
    ]);
    expect(arranged.first.isJoker, isTrue);
    expect(pointsOf(arranged), 3 + 4 + 5 + 6);
  });

  test('reprise d\'une carte : le joker au milieu garde sa place (6)', () {
    final stored = arrangeMeld([
      fourFiveSix[0],
      fourFiveSix[1],
      _joker,
      _c(RamiSuit.coupes, 7),
    ]);
    expect(stored[2].isJoker, isTrue);
    final remaining = [
      for (final card in stored)
        if (card.rank != 7) card,
    ];
    final after = arrangeMeld(remaining);
    expect(after[2].isJoker, isTrue);
    expect(pointsOf(after), 4 + 5 + 6);
  });
}

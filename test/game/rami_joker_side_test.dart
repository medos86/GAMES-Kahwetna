// Joker posé à droite d'une suite = carte la plus haute (issue #838).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard _c(RamiSuit suit, int rank) =>
    RamiCard(id: '${suit.name}-$rank', suit: suit, rank: rank);

const _joker = RamiCard(id: 'joker-0', suit: null, rank: 0);

void main() {
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

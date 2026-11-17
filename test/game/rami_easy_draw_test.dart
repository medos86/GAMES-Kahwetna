// Régression #439 : le facile ne pioche plus la défausse au hasard.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank) =>
    RamiCard(id: '${suit.name}-$rank', suit: suit, rank: rank);

RamiState drawState({
  required RamiCard top,
  required List<RamiCard> hand,
}) {
  final base = dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0);
  return base.copyWith(
    phase: RamiPhase.draw,
    turn: 0,
    hands: [hand, base.hands[1], base.hands[2], base.hands[3]],
    discard: [top],
    opened: [true, false, false, false],
    staged: const [],
    takenId: null,
    firstTour: false,
  );
}

void main() {
  group('Rami facile : pioche (#439)', () {
    final top = c(RamiSuit.epees, 9);
    final hand = [c(RamiSuit.epees, 7), c(RamiSuit.epees, 8), c(RamiSuit.coupes, 2)];

    test('prend la défausse utile quand le tirage est favorable', () {
      final state = drawState(top: top, hand: hand);
      final next = aiStep(state, RamiAiLevel.facile, () => 0.0);
      expect(next.takenId, top.id);
    });

    test('pioche dans le talon quand le tirage est défavorable', () {
      final state = drawState(top: top, hand: hand);
      final next = aiStep(state, RamiAiLevel.facile, () => 0.99);
      expect(next.takenId, isNull);
      expect(next.stock.length, state.stock.length - 1);
    });

    test('ne prend jamais une défausse inutile', () {
      final useless = c(RamiSuit.batons, 2);
      final state = drawState(top: useless, hand: hand);
      final next = aiStep(state, RamiAiLevel.facile, () => 0.0);
      expect(next.takenId, isNull);
    });
  });
}

// Régression #450 : deux combinaisons de même id sur la table ne doivent pas bloquer l'IA.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank) =>
    RamiCard(id: '${suit.name}-$rank', suit: suit, rank: rank);

void main() {
  group('Rami : ids de combinaisons (#450)', () {
    test('une carte qui ne peut aller que sur la 2e combinaison ne bloque pas l IA', () {
      final base = dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0);
      // Deux combinaisons partagent l'id « a » : layOff ne voit que la première.
      final state = base.copyWith(
        phase: RamiPhase.play,
        turn: 0,
        hands: [
          [c(RamiSuit.coupes, 5), c(RamiSuit.batons, 12)],
          base.hands[1],
          base.hands[2],
          base.hands[3],
        ],
        table: [
          Meld(id: 'a', cards: [
            c(RamiSuit.epees, 7),
            c(RamiSuit.epees, 8),
            c(RamiSuit.epees, 9),
          ]),
          Meld(id: 'a', cards: [
            c(RamiSuit.coupes, 2),
            c(RamiSuit.coupes, 3),
            c(RamiSuit.coupes, 4),
          ]),
        ],
        opened: [true, true, true, true],
        staged: const [],
        takenId: null,
        firstTour: false,
      );

      final next = aiStep(state, RamiAiLevel.facile, () => 0.99);

      expect(identical(next, state), isFalse,
          reason: "l'IA doit jouer (pose ou défausse), jamais rester bloquée");
    });
  });
}

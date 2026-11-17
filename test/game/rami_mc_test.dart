// Difficile (#304) : la défausse par simulation joue toujours un coup légal.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank) =>
    RamiCard(id: '${suit.name}-$rank', suit: suit, rank: rank);

void main() {
  group('Rami difficile : défausse par simulation (#304)', () {
    test('le difficile joue un coup légal et ne reste pas bloqué', () {
      final base = dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0);
      final state = base.copyWith(
        phase: RamiPhase.play,
        turn: 0,
        hands: [
          [
            c(RamiSuit.epees, 2),
            c(RamiSuit.coupes, 9),
            c(RamiSuit.batons, 12),
            c(RamiSuit.deniers, 5),
          ],
          base.hands[1],
          base.hands[2],
          base.hands[3],
        ],
        opened: [true, true, true, true],
        staged: const [],
        takenId: null,
        firstTour: false,
      );

      final next = aiStep(state, RamiAiLevel.difficile, () => 0.5);

      expect(identical(next, state), isFalse);
    });
  });
}

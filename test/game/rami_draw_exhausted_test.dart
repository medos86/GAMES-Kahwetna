// Régression #458 : pioche épuisée = manche terminée sans gagnant.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank) =>
    RamiCard(id: '${suit.name}-$rank', suit: suit, rank: rank);

void main() {
  group('Rami : pioche épuisée (#458)', () {
    test('pioche vide : la manche se termine sans gagnant', () {
      final base = dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0);
      final state = base.copyWith(
        phase: RamiPhase.draw,
        turn: 0,
        stock: const [],
        discard: [
          c(RamiSuit.epees, 2),
          c(RamiSuit.coupes, 3),
          c(RamiSuit.batons, 4),
        ],
      );

      final next = drawStock(state);

      expect(next.phase, RamiPhase.end);
      expect(next.roundResult!.winner, isNull);
    });
  });
}

// Animation du recyclage de la défausse (#646) : détection des coups et calcul des vols.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank) =>
    RamiCard(id: '${suit.name}-$rank', suit: suit, rank: rank);

void main() {
  RamiState aiTurn({required List<RamiCard> stock, required List<RamiCard> discard}) {
    final base = dealRound([0, 0, 0, 0], 0, 1, 100, () => 0.0);
    return base.copyWith(
      phase: RamiPhase.draw,
      turn: 1,
      stock: stock,
      discard: discard,
    );
  }

  final pile = [
    c(RamiSuit.epees, 2),
    c(RamiSuit.coupes, 3),
    c(RamiSuit.batons, 4),
  ];

  group('Rami : animation du recyclage', () {
    test('recyclage IA : recyclage puis pioche, sans prise de défausse', () {
      final prev = aiTurn(stock: const [], discard: pile);
      final next = drawStock(prev, () => 0.0);

      expect(
        ramiAiMoves(prev, next),
        [RamiAiMove.recycle, RamiAiMove.drawStock],
      );
    });

    test('pioche normale : aucun recyclage détecté', () {
      final prev = aiTurn(stock: [c(RamiSuit.epees, 9)], discard: pile);
      final next = drawStock(prev, () => 0.0);

      expect(ramiAiMoves(prev, next), [RamiAiMove.drawStock]);
    });

    test('nombre de cartes animées borné et sans carte du dessus', () {
      expect(ramiRecycleFlightCount(0), 0);
      expect(ramiRecycleFlightCount(1), 0);
      expect(ramiRecycleFlightCount(3), 2);
      expect(ramiRecycleFlightCount(40), ramiRecycleVisualCards);
    });

    test('durée totale : décalage entre cartes puis vol final', () {
      expect(ramiRecycleTotal(0), Duration.zero);
      expect(
        ramiRecycleTotal(3),
        ramiRecycleStagger * 2 + ramiRecycleFlight,
      );
    });
  });
}

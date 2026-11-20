// Pioche vide : la défausse (sauf sa carte du dessus) redevient pioche (#646).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank) =>
    RamiCard(id: '${suit.name}-$rank', suit: suit, rank: rank);

void main() {
  RamiState drawPhase({
    required List<RamiCard> stock,
    required List<RamiCard> discard,
    int recycles = 0,
  }) {
    final base = dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0);
    return base.copyWith(
      phase: RamiPhase.draw,
      turn: 0,
      stock: stock,
      discard: discard,
      recycles: recycles,
    );
  }

  final pile = [
    c(RamiSuit.epees, 2),
    c(RamiSuit.coupes, 3),
    c(RamiSuit.batons, 4),
  ];

  group('Rami : recyclage de la défausse', () {
    test('pioche vide : la défausse redevient pioche', () {
      final before = drawPhase(stock: const [], discard: pile);
      final next = drawStock(before, () => 0.0);

      expect(next.phase, RamiPhase.play);
      expect(next.discard, [pile.last]);
      expect(next.stock.length, 1);
      expect(next.recycles, 1);
      expect(next.hands[0].length, before.hands[0].length + 1);
    });

    test('le recyclage conserve toutes les cartes', () {
      final before = drawPhase(stock: const [], discard: pile);
      final next = drawStock(before, () => 0.0);

      final idsBefore = {
        for (final card in [...before.discard, ...before.hands[0]]) card.id,
      };
      final idsAfter = {
        for (final card in [
          ...next.discard,
          ...next.stock,
          ...next.hands[0],
        ])
          card.id,
      };
      expect(idsAfter, idsBefore);
    });

    test('défausse d une seule carte : la manche se termine', () {
      final state = drawPhase(stock: const [], discard: [pile.last]);
      final next = drawStock(state);

      expect(next.phase, RamiPhase.end);
      expect(next.roundResult!.winner, isNull);
    });

    test('garde-fou : au maximum ramiMaxRecycles recyclages par manche', () {
      final state = drawPhase(
        stock: const [],
        discard: pile,
        recycles: ramiMaxRecycles,
      );
      final next = drawStock(state);

      expect(next.phase, RamiPhase.end);
      expect(next.roundResult!.winner, isNull);
    });

    test('le compteur de recyclages survit à la sauvegarde', () {
      final state = drawPhase(stock: const [], discard: pile, recycles: 1);
      final restored = RamiState.fromJson(state.toJson());

      expect(restored.recycles, 1);
    });
  });
}

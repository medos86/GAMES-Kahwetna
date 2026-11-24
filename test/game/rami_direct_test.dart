// Rami directe (#867) : poser toute la main d'un coup fait gagner la manche, sans seuil
// d'ouverture. Si ce n'est pas possible, la tentative est annulée (état identique).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank, String id) =>
    RamiCard(id: id, suit: suit, rank: rank);

const joker = RamiCard(id: 'joker', suit: null, rank: 0);

RamiState play(
  List<RamiCard> hand, {
  List<bool>? opened,
  bool firstTour = false,
  List<Meld> table = const [],
}) =>
    dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0).copyWith(
      phase: RamiPhase.play,
      turn: 0,
      hands: [
        hand,
        [c(RamiSuit.epees, 2, 'o1'), c(RamiSuit.coupes, 9, 'o2')],
        [c(RamiSuit.epees, 4, 'o3')],
        [c(RamiSuit.batons, 8, 'o4')],
      ],
      discard: const [],
      opened: opened ?? [false, false, false, false],
      table: table,
      staged: const [],
      takenId: null,
      firstTour: firstTour,
    );

void main() {
  group('rami directe', () {
    test('brelan seul : toute la main posée, victoire sans ouverture', () {
      final state = play([
        c(RamiSuit.epees, 1, 'a1'),
        c(RamiSuit.coupes, 1, 'a2'),
        c(RamiSuit.batons, 1, 'a3'),
      ]);
      final out = ramiDirect(state);
      expect(identical(out, state), isFalse);
      expect(out.phase, RamiPhase.end);
      expect(out.roundResult?.winner, 0);
      expect(out.hands[0], isEmpty);
      expect(out.table.length, 1);
    });

    test('suite avec un joker : gagnée même sous le seuil de 51', () {
      final state = play([
        c(RamiSuit.epees, 5, 'e5'),
        c(RamiSuit.epees, 6, 'e6'),
        joker,
      ]);
      final out = ramiDirect(state);
      expect(out.phase, RamiPhase.end);
      expect(out.roundResult?.winner, 0);
      expect(out.table.every((meld) => isValidMeld(meld.cards)), isTrue);
    });

    test('plusieurs combinaisons : toute la main est recouverte', () {
      final state = play([
        c(RamiSuit.epees, 3, 'e3'),
        c(RamiSuit.epees, 4, 'e4'),
        c(RamiSuit.epees, 5, 'e5'),
        c(RamiSuit.deniers, 9, 'd9'),
        c(RamiSuit.coupes, 9, 'c9'),
        c(RamiSuit.batons, 9, 'b9'),
      ]);
      final out = ramiDirect(state);
      expect(out.phase, RamiPhase.end);
      expect(out.roundResult?.winner, 0);
      expect(out.table.length, 2);
    });

    test('main non entièrement posable : tentative annulée (état identique)', () {
      final state = play([
        c(RamiSuit.epees, 1, 'a1'),
        c(RamiSuit.coupes, 1, 'a2'),
        c(RamiSuit.epees, 12, 'q1'),
      ]);
      final out = ramiDirect(state);
      expect(identical(out, state), isTrue);
    });

    test('une carte restante sans combinaison : rien ne change', () {
      final state = play([
        c(RamiSuit.epees, 5, 'e5'),
        c(RamiSuit.epees, 6, 'e6'),
        c(RamiSuit.epees, 7, 'e7'),
        c(RamiSuit.coupes, 2, 'c2'),
      ]);
      final out = ramiDirect(state);
      expect(identical(out, state), isTrue);
      expect(out.hands[0].length, 4);
    });

    test('refusée si le joueur a déjà ouvert', () {
      final state = play(
        [
          c(RamiSuit.epees, 1, 'a1'),
          c(RamiSuit.coupes, 1, 'a2'),
          c(RamiSuit.batons, 1, 'a3'),
        ],
        opened: [true, false, false, false],
      );
      expect(identical(ramiDirect(state), state), isTrue);
    });

    test('refusée au premier tour', () {
      final state = play(
        [
          c(RamiSuit.epees, 1, 'a1'),
          c(RamiSuit.coupes, 1, 'a2'),
          c(RamiSuit.batons, 1, 'a3'),
        ],
        firstTour: true,
      );
      expect(identical(ramiDirect(state), state), isTrue);
    });

    test('refusée hors phase de jeu (pioche à faire)', () {
      final state = play(
        [
          c(RamiSuit.epees, 1, 'a1'),
          c(RamiSuit.coupes, 1, 'a2'),
          c(RamiSuit.batons, 1, 'a3'),
        ],
      ).copyWith(phase: RamiPhase.draw);
      expect(identical(ramiDirect(state), state), isTrue);
    });

    test('ne prend pas de joker sur la table avant ouverture', () {
      final table = [
        Meld(id: 'm1', cards: [
          c(RamiSuit.epees, 5, 'e5'),
          c(RamiSuit.epees, 6, 'e6'),
          joker,
          c(RamiSuit.epees, 8, 'e8'),
        ]),
      ];
      final state = play([c(RamiSuit.epees, 7, 'e7')], table: table);
      expect(identical(takeJoker(state, 'e7', 'm1'), state), isTrue);
      expect(identical(ramiDirect(state), state), isTrue);
    });
  });
}

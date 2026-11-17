// Issue #496 : pose sans bouton, seuil automatique, jokers et défausse obligatoire.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank, String id) =>
    RamiCard(id: id, suit: suit, rank: rank);

const joker = RamiCard(id: 'joker', suit: null, rank: 0);

RamiState play(List<List<RamiCard>> hands, {List<Meld>? table}) =>
    dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0).copyWith(
      phase: RamiPhase.play,
      turn: 0,
      hands: hands,
      table: table ?? const [],
      opened: [false, false, false, false],
      staged: const [],
      takenId: null,
      firstTour: false,
      pendingPoints: [0, 0, 0, 0],
    );

final kings = [
  c(RamiSuit.epees, 13, 'ks'),
  c(RamiSuit.coupes, 13, 'kh'),
  c(RamiSuit.batons, 13, 'kc'),
];

final queens = [
  c(RamiSuit.epees, 12, 'qs'),
  c(RamiSuit.coupes, 12, 'qh'),
  c(RamiSuit.batons, 12, 'qb'),
];

void main() {
  group('pose sous le seuil (#496)', () {
    test('une pose sous le seuil reste en attente, la main n\'est pas finie', () {
      final s = play([
        [...kings, c(RamiSuit.batons, 2, 'z')],
        [],
        [],
        [],
      ]);
      final next = poseMeld(s, ['ks', 'kh', 'kc']);
      expect(next.opened[0], isFalse);
      expect(next.staged.length, 1);
      expect(next.hands[0].map((x) => x.id), ['z']);
    });

    test('on ne peut pas poser sa dernière carte', () {
      final s = play([
        [...kings],
        [],
        [],
        [],
      ]);
      expect(identical(poseMeld(s, ['ks', 'kh', 'kc']), s), isTrue);
    });

    test('défausser sous le seuil fixe les poses sur la table sans ouvrir', () {
      final s = play([
        [...kings, c(RamiSuit.batons, 2, 'z'), c(RamiSuit.coupes, 2, 'y')],
        [],
        [],
        [],
      ]);
      final staged = poseMeld(s, ['ks', 'kh', 'kc']);
      final next = discardCard(staged, 'z');
      expect(next.staged, isEmpty);
      expect(next.table.length, 1);
      expect(next.opened[0], isFalse);
      expect(next.pendingPoints[0], 30);
      expect(next.hands[0].map((x) => x.id), ['y']);
    });
  });

  group('franchir le seuil (#496)', () {
    test('dépasser 51 ouvre automatiquement, sans bouton', () {
      final s = play([
        [...kings, ...queens, c(RamiSuit.batons, 2, 'z')],
        [],
        [],
        [],
      ]);
      final afterKings = poseMeld(s, ['ks', 'kh', 'kc']);
      final next = poseMeld(afterKings, ['qs', 'qh', 'qb']);
      expect(next.opened[0], isTrue);
      expect(next.staged, isEmpty);
      expect(next.table.length, 2);
      expect(next.hands[0].map((x) => x.id), ['z']);
    });
  });

  group('jokers (#496)', () {
    // Table : suite 4-[joker]-6 de bâtons, posée par le joueur 0 sous le seuil.
    final run = Meld(
      id: 'm1',
      cards: [c(RamiSuit.batons, 4, 'b4'), joker, c(RamiSuit.batons, 6, 'b6')],
    );

    test('pas de reprise de joker tant que le seuil n\'est pas dépassé', () {
      final s = play(
        [
          [c(RamiSuit.batons, 5, 'n')],
          [],
          [],
          [],
        ],
        table: [run],
      );
      expect(identical(takeJoker(s, 'n', 'm1'), s), isTrue);
    });

    test('après ouverture, le joker posé avant revient dans la main', () {
      final s = play(
        [
          [c(RamiSuit.batons, 5, 'n')],
          [],
          [],
          [],
        ],
        table: [run],
      ).copyWith(opened: [true, false, false, false]);
      final next = takeJoker(s, 'n', 'm1');
      expect(next.hands[0].any((x) => x.isJoker), isTrue);
    });
  });
}

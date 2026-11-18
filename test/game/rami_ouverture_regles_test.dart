// Règles de l'ouverture sans boutons, jokers et défausse obligatoire (#496).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank, [String? id]) =>
    RamiCard(id: id ?? '${suit.name}-$rank', suit: suit, rank: rank);

const joker = RamiCard(id: 'joker', suit: null, rank: 0);

RamiState inPlay(List<List<RamiCard>> hands) => dealRound(
      [0, 0, 0, 0],
      3,
      1,
      100,
      () => 0.0,
    ).copyWith(
      phase: RamiPhase.play,
      turn: 0,
      hands: hands,
      opened: [false, false, false, false],
      staged: const [],
      firstTour: false,
    );

// Table : suite 4-5-[joker]-7 de bâtons, posée par le joueur 1.
RamiState withRun(RamiState s, {required bool opened}) => s.copyWith(
      table: [
        Meld(id: 'm1', cards: [
          c(RamiSuit.batons, 4, 'b4'),
          c(RamiSuit.batons, 5, 'b5'),
          joker,
          c(RamiSuit.batons, 7, 'b7'),
        ]),
      ],
      opened: [opened, false, false, false],
    );

void main() {
  final kings = [
    c(RamiSuit.epees, 13, 'ks'),
    c(RamiSuit.coupes, 13, 'kh'),
    c(RamiSuit.batons, 13, 'kc'),
  ];

  test('pose sous le seuil : reprise de joker refusée', () {
    final s = withRun(
      inPlay([
        [c(RamiSuit.batons, 6, 'b6'), c(RamiSuit.deniers, 2, 'x')],
        [c(RamiSuit.coupes, 2)],
        [c(RamiSuit.coupes, 3)],
        [c(RamiSuit.coupes, 4)],
      ]),
      opened: false,
    );
    expect(takeJoker(s, 'b6', 'm1'), same(s));
  });

  test('seuil dépassé : reprise de joker autorisée, y compris posé avant', () {
    final s = withRun(
      inPlay([
        [c(RamiSuit.batons, 6, 'b6'), c(RamiSuit.deniers, 2, 'x')],
        [c(RamiSuit.coupes, 2)],
        [c(RamiSuit.coupes, 3)],
        [c(RamiSuit.coupes, 4)],
      ]),
      opened: true,
    );
    final next = takeJoker(s, 'b6', 'm1');
    expect(next, isNot(same(s)));
    expect(next.hands[0].any((card) => card.id == 'joker'), isTrue);
  });

  test('impossible de poser sa dernière carte', () {
    final s = inPlay([
      kings,
      [c(RamiSuit.coupes, 2)],
      [c(RamiSuit.coupes, 3)],
      [c(RamiSuit.coupes, 4)],
    ]).copyWith(opened: [true, false, false, false]);
    expect(poseMeld(s, ['ks', 'kh', 'kc']), same(s));
  });

  test('victoire seulement par défausse de la dernière carte', () {
    final s = inPlay([
      [...kings, c(RamiSuit.deniers, 2, 'x')],
      [c(RamiSuit.coupes, 2)],
      [c(RamiSuit.coupes, 3)],
      [c(RamiSuit.coupes, 4)],
    ]).copyWith(opened: [true, false, false, false]);
    final posed = poseMeld(s, ['ks', 'kh', 'kc']);
    expect(posed.phase, RamiPhase.play);
    expect(posed.hands[0].length, 1);

    final won = discardCard(posed, 'x');
    expect(won.phase, RamiPhase.end);
    expect(won.roundResult?.winner, 0);
  });

  test('annuler : les poses du tour reviennent en main', () {
    final s = inPlay([
      [
        c(RamiSuit.epees, 7, 'a'),
        c(RamiSuit.epees, 8, 'b'),
        c(RamiSuit.epees, 9, 'c'),
        c(RamiSuit.deniers, 2, 'x'),
      ],
      [c(RamiSuit.coupes, 2)],
      [c(RamiSuit.coupes, 3)],
      [c(RamiSuit.coupes, 4)],
    ]);
    final posed = poseMeld(s, ['a', 'b', 'c']);
    expect(posed.table.length, 1);
    final cancelled = cancelStaged(posed);
    expect(cancelled.table, isEmpty);
    expect(cancelled.staged, isEmpty);
    expect(cancelled.hands[0].length, 4);
    expect(identical(cancelStaged(s), s), isTrue);
  });
}

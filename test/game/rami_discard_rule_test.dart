// Règle de la défausse : on ne prend la carte du dessus que si on peut la poser ce tour,
// elle doit être posée, et elle peut être remise sur la défausse tant qu'elle n'est pas posée.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank, String id) =>
    RamiCard(id: id, suit: suit, rank: rank);

RamiState withDiscard(
  List<List<RamiCard>> hands,
  RamiCard top, {
  List<bool>? opened,
  List<Meld> table = const [],
}) =>
    fixedDeal().copyWith(
      phase: RamiPhase.draw,
      turn: 0,
      hands: hands,
      discard: [top],
      opened: opened ?? [false, false, false, false],
      table: table,
      staged: const [],
      takenId: null,
    );

void main() {
  // Hors ouverture : 4 dames (40 pts) + 3 rois (30 pts) = 70 pts, dont la dame du dessus.
  final openHand = [
    c(RamiSuit.epees, 12, 'qs'),
    c(RamiSuit.coupes, 12, 'qh'),
    c(RamiSuit.batons, 12, 'qc'),
    c(RamiSuit.epees, 13, 'ks'),
    c(RamiSuit.coupes, 13, 'kh'),
    c(RamiSuit.batons, 13, 'kc'),
  ];
  final queenTop = c(RamiSuit.deniers, 12, 'qd');

  group('prise de la défausse', () {
    test('refusée si la carte du dessus ne sert à rien', () {
      final state = withDiscard(
        [
          [c(RamiSuit.epees, 3, 'a'), c(RamiSuit.coupes, 5, 'b')],
          [],
          [],
          [],
        ],
        c(RamiSuit.deniers, 2, 'top'),
      );
      expect(canUseDiscardTop(state), isFalse);
      expect(drawDiscard(state), same(state));
    });

    test('hors ouverture, acceptée si elle ouvre avec la main', () {
      final state = withDiscard([openHand, [], [], []], queenTop);
      expect(canUseDiscardTop(state), isTrue);
      final drawn = drawDiscard(state);
      expect(drawn.phase, RamiPhase.play);
      expect(drawn.takenId, 'qd');
      expect(drawn.hands[0].any((card) => card.id == 'qd'), isTrue);
      expect(drawn.discard, isEmpty);
    });

    test('hors ouverture, refusée si les points sont insuffisants', () {
      // Seule la dame du dessus forme un brelan avec deux dames : 30 pts < 51.
      final state = withDiscard(
        [
          [
            c(RamiSuit.epees, 12, 'qs'),
            c(RamiSuit.coupes, 12, 'qh'),
            c(RamiSuit.epees, 3, 'x'),
          ],
          [],
          [],
          [],
        ],
        c(RamiSuit.batons, 12, 'qc'),
      );
      expect(canUseDiscardTop(state), isFalse);
      expect(drawDiscard(state), same(state));
    });

    test('après ouverture, acceptée si elle se pose sur la table', () {
      final table = [
        Meld(id: 'm1', cards: [
          c(RamiSuit.epees, 5, 'e5'),
          c(RamiSuit.epees, 6, 'e6'),
          c(RamiSuit.epees, 7, 'e7'),
        ]),
      ];
      final state = withDiscard(
        [
          [c(RamiSuit.coupes, 2, 'h2'), c(RamiSuit.batons, 9, 'c9')],
          [],
          [],
          [],
        ],
        c(RamiSuit.epees, 8, 'e8'),
        opened: [true, false, false, false],
        table: table,
      );
      expect(canUseDiscardTop(state), isTrue);
      expect(drawDiscard(state).takenId, 'e8');
    });

    test('après ouverture, refusée si elle ne se pose nulle part', () {
      final table = [
        Meld(id: 'm1', cards: [
          c(RamiSuit.epees, 5, 'e5'),
          c(RamiSuit.epees, 6, 'e6'),
          c(RamiSuit.epees, 7, 'e7'),
        ]),
      ];
      final state = withDiscard(
        [
          [c(RamiSuit.coupes, 2, 'h2'), c(RamiSuit.batons, 9, 'c9')],
          [],
          [],
          [],
        ],
        c(RamiSuit.deniers, 2, 'd2'),
        opened: [true, false, false, false],
        table: table,
      );
      expect(canUseDiscardTop(state), isFalse);
      expect(drawDiscard(state), same(state));
    });
  });

  group('remettre la carte prise', () {
    test('remet la carte sur la défausse et revient en phase de pioche', () {
      final drawn = drawDiscard(withDiscard([openHand, [], [], []], queenTop));
      final back = returnTaken(drawn);
      expect(back.phase, RamiPhase.draw);
      expect(back.takenId, isNull);
      expect(back.discard.last.id, 'qd');
      expect(back.hands[0].any((card) => card.id == 'qd'), isFalse);
    });

    test('refusée une fois la carte posée', () {
      final drawn = drawDiscard(withDiscard(
        [openHand, [], [], []],
        queenTop,
      ));
      // Après la prise, la carte est en main : on la pose en combinaison puis on tente de la remettre.
      final posed = poseMeld(drawn, ['qd', 'qs', 'qh']);
      expect(posed.hands[0].any((card) => card.id == 'qd'), isFalse);
      expect(returnTaken(posed), same(posed));
    });

    test('refusée pendant une ouverture en cours', () {
      final drawn = drawDiscard(withDiscard([openHand, [], [], []], queenTop));
      final staged = drawn.copyWith(
        staged: [
          [c(RamiSuit.epees, 3, 'x')],
        ],
      );
      expect(returnTaken(staged), same(staged));
    });
  });

  group('la carte prise doit être posée', () {
    test('défausser la carte prise est refusé tant qu’elle est en main', () {
      final drawn = drawDiscard(withDiscard([openHand, [], [], []], queenTop));
      expect(discardCard(drawn, 'qd'), same(drawn));
    });
  });

  group('IA', () {
    test("l'IA ne prend pas une défausse inutile", () {
      final state = withDiscard(
        [
          [c(RamiSuit.epees, 3, 'a'), c(RamiSuit.coupes, 5, 'b')],
          [c(RamiSuit.epees, 9, 'x')],
          [c(RamiSuit.epees, 10, 'y')],
          [c(RamiSuit.epees, 11, 'z')],
        ],
        c(RamiSuit.deniers, 2, 'top'),
      );
      final next = aiStep(state, RamiAiLevel.difficile, () => 0.0);
      expect(next.takenId, isNull);
    });

    test("l'IA prend une défausse posable et la pose sur la table", () {
      final table = [
        Meld(id: 'm1', cards: [
          c(RamiSuit.epees, 5, 'e5'),
          c(RamiSuit.epees, 6, 'e6'),
          c(RamiSuit.epees, 7, 'e7'),
        ]),
      ];
      final state = withDiscard(
        [
          [c(RamiSuit.coupes, 2, 'h2'), c(RamiSuit.batons, 9, 'c9')],
          [],
          [],
          [],
        ],
        c(RamiSuit.epees, 8, 'e8'),
        opened: [true, false, false, false],
        table: table,
      );
      final drawn = aiStep(state, RamiAiLevel.difficile, () => 0.0);
      expect(drawn.takenId, 'e8');
      final played = aiStep(drawn, RamiAiLevel.difficile, () => 0.0);
      expect(played.table.first.cards.any((card) => card.id == 'e8'), isTrue);
      expect(played.hands[0].any((card) => card.id == 'e8'), isFalse);
    });
  });
}

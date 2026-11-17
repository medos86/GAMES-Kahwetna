// Règle de la défausse (#315) : le joueur peut toujours prendre la carte du dessus.
// Avant ouverture, il doit la poser ou la remettre (rien d'autre ne se défausse en attendant).
// Après ouverture, il n'est pas obligé de la poser. L'IA garde sa règle (canUseDiscardTop).
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
    dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0).copyWith(
      phase: RamiPhase.draw,
      turn: 0,
      hands: hands,
      discard: [top],
      opened: opened ?? [false, false, false, false],
      table: table,
      staged: const [],
      takenId: null,
      firstTour: false,
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

  final table = [
    Meld(id: 'm1', cards: [
      c(RamiSuit.epees, 5, 'e5'),
      c(RamiSuit.epees, 6, 'e6'),
      c(RamiSuit.epees, 7, 'e7'),
    ]),
  ];

  group('prise de la défausse', () {
    test('acceptée même si la carte ne sert à rien (#315)', () {
      final state = withDiscard(
        [
          [c(RamiSuit.epees, 3, 'a'), c(RamiSuit.coupes, 5, 'b')],
          [],
          [],
          [],
        ],
        c(RamiSuit.deniers, 2, 'top'),
      );
      final drawn = drawDiscard(state);
      expect(drawn.phase, RamiPhase.play);
      expect(drawn.takenId, 'top');
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

    test('après ouverture, acceptée même si elle ne se pose nulle part', () {
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
      expect(drawDiscard(state).takenId, 'd2');
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

  group('blocage tant que la carte prise est en main', () {
    test('hors ouverture, défausser une autre carte est refusé', () {
      final drawn = drawDiscard(withDiscard(
        [
          [c(RamiSuit.epees, 3, 'a'), c(RamiSuit.coupes, 5, 'b')],
          [],
          [],
          [],
        ],
        c(RamiSuit.deniers, 2, 'top'),
      ));
      expect(discardCard(drawn, 'a'), same(drawn));
    });

    test('défausser la carte prise est refusé tant qu’elle est en main', () {
      final drawn = drawDiscard(withDiscard([openHand, [], [], []], queenTop));
      expect(discardCard(drawn, 'qd'), same(drawn));
    });

    test('après ouverture, défausser une autre carte reste permis', () {
      final drawn = drawDiscard(withDiscard(
        [
          [c(RamiSuit.coupes, 2, 'h2'), c(RamiSuit.batons, 9, 'c9')],
          [],
          [],
          [],
        ],
        c(RamiSuit.deniers, 2, 'd2'),
        opened: [true, false, false, false],
        table: table,
      ));
      final next = discardCard(drawn, 'h2');
      expect(next, isNot(same(drawn)));
      expect(next.phase, RamiPhase.draw);
      expect(next.discard.last.id, 'h2');
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

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank) =>
    RamiCard(id: '${suit.name}-$rank', suit: suit, rank: rank);

/// Table : paquet A posé pendant le tour (7-8-9-10 de pique), paquet B existant (4-5-6 de pique).
RamiState scene({
  required List<RamiCard> handSeat0,
  required List<RamiCard> meldA,
  bool opened = true,
}) {
  final base = dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0);
  return base.copyWith(
    phase: RamiPhase.play,
    turn: 0,
    firstTour: false,
    hands: [handSeat0, [], [], []],
    table: [
      Meld(id: 'A', cards: meldA, owner: 0),
      Meld(
        id: 'B',
        cards: [
          c(RamiSuit.epees, 4),
          c(RamiSuit.epees, 5),
          c(RamiSuit.epees, 6),
        ],
        owner: 1,
      ),
    ],
    opened: [opened, false, false, false],
    staged: opened ? const [] : [meldA],
    turnMeldIds: const ['A'],
    turnOpenMin: 0,
  );
}

final meldA = [
  c(RamiSuit.epees, 7),
  c(RamiSuit.epees, 8),
  c(RamiSuit.epees, 9),
  c(RamiSuit.epees, 10),
];

void main() {
  group('moveBetweenMelds (#898)', () {
    test('déplace une carte du tour vers un paquet existant valide', () {
      final state = scene(
        handSeat0: [c(RamiSuit.coupes, 9), c(RamiSuit.deniers, 12)],
        meldA: meldA,
      );
      final next = moveBetweenMelds(state, 'epees-7', 'A', 'B');
      expect(identical(next, state), isFalse);
      final a = next.table.firstWhere((m) => m.id == 'A');
      final b = next.table.firstWhere((m) => m.id == 'B');
      expect(a.cards.map((x) => x.id), isNot(contains('epees-7')));
      expect(b.cards.map((x) => x.id), contains('epees-7'));
      expect(isValidMeld(a.cards), isTrue);
      expect(isValidMeld(b.cards), isTrue);
    });

    test('refuse si le paquet d\'origine deviendrait invalide', () {
      final state = scene(
        handSeat0: [c(RamiSuit.coupes, 9), c(RamiSuit.deniers, 12)],
        meldA: meldA,
      );
      // Retirer le 8 laisse 7-9-10 : invalide.
      expect(identical(moveBetweenMelds(state, 'epees-8', 'A', 'B'), state),
          isTrue);
    });

    test('refuse si la carte ne s\'accroche pas au paquet cible', () {
      final state = scene(
        handSeat0: [c(RamiSuit.coupes, 9), c(RamiSuit.deniers, 12)],
        meldA: meldA,
      );
      expect(identical(moveBetweenMelds(state, 'epees-10', 'A', 'B'), state),
          isTrue);
    });

    test('même paquet : sans effet', () {
      final state = scene(
        handSeat0: [c(RamiSuit.coupes, 9), c(RamiSuit.deniers, 12)],
        meldA: meldA,
      );
      expect(identical(moveBetweenMelds(state, 'epees-7', 'A', 'A'), state),
          isTrue);
    });

    test('avant ouverture : pas de dépôt sur un paquet non posé ce tour', () {
      final state = scene(
        handSeat0: [c(RamiSuit.coupes, 9), c(RamiSuit.deniers, 12)],
        meldA: meldA,
        opened: false,
      );
      expect(identical(moveBetweenMelds(state, 'epees-7', 'A', 'B'), state),
          isTrue);
    });
  });
}

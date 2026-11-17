// Issue #496 : pose sans bouton, seuil automatique, jokers, défausse.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank, String id) {
  return RamiCard(id: id, suit: suit, rank: rank);
}

const joker = RamiCard(id: 'joker', suit: null, rank: 0);
const noCards = <RamiCard>[];

RamiState play(List<List<RamiCard>> hands, List<Meld> table) {
  final base = dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0);
  return base.copyWith(
    phase: RamiPhase.play,
    turn: 0,
    hands: hands,
    table: table,
    opened: [false, false, false, false],
    staged: const [],
    takenId: null,
    firstTour: false,
    pendingPoints: [0, 0, 0, 0],
  );
}

RamiState solo(List<RamiCard> hand) {
  return play([hand, noCards, noCards, noCards], const []);
}

final ks = c(RamiSuit.epees, 13, 'ks');
final kh = c(RamiSuit.coupes, 13, 'kh');
final kc = c(RamiSuit.batons, 13, 'kc');
final qs = c(RamiSuit.epees, 12, 'qs');
final qh = c(RamiSuit.coupes, 12, 'qh');
final qb = c(RamiSuit.batons, 12, 'qb');
final spare = c(RamiSuit.batons, 2, 'z');
final yy = c(RamiSuit.coupes, 2, 'y');
final b4 = c(RamiSuit.batons, 4, 'b4');
final b6 = c(RamiSuit.batons, 6, 'b6');
final five = c(RamiSuit.batons, 5, 'n');
final run = Meld(id: 'm1', cards: [b4, joker, b6]);

void main() {
  group('pose sous le seuil (#496)', () {
    test('une pose sous le seuil reste en attente', () {
      final s = solo([ks, kh, kc, spare]);
      final next = poseMeld(s, ['ks', 'kh', 'kc']);
      expect(next.opened[0], isFalse);
      expect(next.staged.length, 1);
      expect(next.hands[0].map((x) => x.id), ['z']);
    });

    test('on ne peut pas poser sa dernière carte', () {
      final s = solo([ks, kh, kc]);
      expect(identical(poseMeld(s, ['ks', 'kh', 'kc']), s), isTrue);
    });

    test('défausser sous le seuil fixe les poses sans ouvrir', () {
      final staged =
          poseMeld(solo([ks, kh, kc, spare, yy]), ['ks', 'kh', 'kc']);
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
      final s = solo([ks, kh, kc, qs, qh, qb, spare]);
      final afterKings = poseMeld(s, ['ks', 'kh', 'kc']);
      final next = poseMeld(afterKings, ['qs', 'qh', 'qb']);
      expect(next.opened[0], isTrue);
      expect(next.staged, isEmpty);
      expect(next.table.length, 2);
      expect(next.hands[0].map((x) => x.id), ['z']);
    });
  });

  group('jokers (#496)', () {
    test('pas de reprise de joker sous le seuil', () {
      final s = play([[five], noCards, noCards, noCards], [run]);
      expect(identical(takeJoker(s, 'n', 'm1'), s), isTrue);
    });

    test('après ouverture, le joker posé avant revient', () {
      final base = play([[five], noCards, noCards, noCards], [run]);
      final s = base.copyWith(opened: [true, false, false, false]);
      final next = takeJoker(s, 'n', 'm1');
      expect(next.hands[0].any((x) => x.isJoker), isTrue);
    });
  });
}

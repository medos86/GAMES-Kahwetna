// Issue #496 : pose sans bouton, seuil automatique, jokers, défausse.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank, String id) {
  return RamiCard(id: id, suit: suit, rank: rank);
}

const joker = RamiCard(id: 'joker', suit: null, rank: 0);

RamiState withHand(List<RamiCard> hand) {
  final base = dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0);
  return base.copyWith(
    phase: RamiPhase.play,
    turn: 0,
    hands: [hand, [], [], []],
    staged: const [],
    takenId: null,
    firstTour: false,
    pendingPoints: [0, 0, 0, 0],
  );
}

void main() {
  final ks = c(RamiSuit.epees, 13, 'ks');
  final kh = c(RamiSuit.coupes, 13, 'kh');
  final kc = c(RamiSuit.batons, 13, 'kc');
  final spare = c(RamiSuit.batons, 2, 'z');
  final b4 = c(RamiSuit.batons, 4, 'b4');
  final b6 = c(RamiSuit.batons, 6, 'b6');
  final five = c(RamiSuit.batons, 5, 'n');
  final run = Meld(id: 'm1', cards: [b4, joker, b6]);

  test('une pose sous le seuil reste en attente', () {
    final s = withHand([ks, kh, kc, spare]);
    final next = poseMeld(s, ['ks', 'kh', 'kc']);
    expect(next.opened[0], isFalse);
    expect(next.staged.length, 1);
  });

  test('on ne peut pas poser sa dernière carte', () {
    final s = withHand([ks, kh, kc]);
    expect(identical(poseMeld(s, ['ks', 'kh', 'kc']), s), isTrue);
  });

  test('pas de reprise de joker sous le seuil', () {
    final s = withHand([five]).copyWith(table: [run]);
    expect(identical(takeJoker(s, 'n', 'm1'), s), isTrue);
  });

  test('après ouverture, le joker posé avant revient', () {
    final base = withHand([five]).copyWith(table: [run]);
    final s = base.copyWith(opened: [true, false, false, false]);
    final next = takeJoker(s, 'n', 'm1');
    expect(next.hands[0].any((x) => x.isJoker), isTrue);
  });
}

// Ouvertures à la hausse : chaque ouverture doit dépasser la précédente de la manche.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank, String id) =>
    RamiCard(id: id, suit: suit, rank: rank);

RamiState playing(RamiState base, {required int turn, required int last}) =>
    base.copyWith(
      phase: RamiPhase.play,
      turn: turn,
      staged: const [],
      opened: [false, false, false, false],
      lastOpening: last,
    );

/// Une pose de `points` points : 3 rois (30) et 2 dames (20), plus des as (1 chacun).
List<List<RamiCard>> stagedFor(int points) {
  final kings = [
    c(RamiSuit.epees, 13, 'ks'),
    c(RamiSuit.coupes, 13, 'kh'),
    c(RamiSuit.batons, 13, 'kc'),
  ];
  final queens = [
    c(RamiSuit.epees, 12, 'qs'),
    c(RamiSuit.coupes, 12, 'qh'),
  ];
  final aces = [
    for (var i = 0; i < points - 50; i++) c(RamiSuit.deniers, 1, 'a$i'),
  ];
  return [kings, queens, ...aces.map((ace) => [ace])];
}

void main() {
  final base = dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0);

  test('la première ouverture de la manche demande 51 points', () {
    expect(minOpening(base), 51);
    expect(base.lastOpening, 0);
  });

  test('après une ouverture à 67, la suivante demande 68', () {
    expect(minOpening(base.copyWith(lastOpening: 67)), 68);
  });

  test('première ouverture refusée sous 51, acceptée à 51', () {
    final state = playing(base, turn: 0, last: 0);
    final low = state.copyWith(staged: stagedFor(50));
    expect(commitOpening(low), same(low));

    final ok = commitOpening(state.copyWith(staged: stagedFor(51)));
    expect(ok.opened[0], isTrue);
    expect(ok.lastOpening, 51);
  });

  test('ouverture suivante : refusée à la même valeur, acceptée à +1', () {
    final state = playing(base, turn: 1, last: 51);
    final same51 = state.copyWith(staged: stagedFor(51));
    expect(commitOpening(same51), same(same51));

    final ok = commitOpening(state.copyWith(staged: stagedFor(52)));
    expect(ok.opened[1], isTrue);
    expect(ok.lastOpening, 52);
  });

  test("le seuil est remis à 51 à la manche suivante", () {
    final ended = base.copyWith(lastOpening: 80);
    expect(minOpening(ended), 81);
    final fresh = dealRound([0, 0, 0, 0], 3, 2, 100, () => 0.0);
    expect(fresh.lastOpening, 0);
  });

  test('lastOpening absent d’une sauvegarde : valeur 0 à la lecture', () {
    final json = base.toJson()..remove('lastOpening');
    expect(RamiState.fromJson(json).lastOpening, 0);
  });

  // 4 dames (40) + 3 rois (30) = 70 points, avec deux cartes sans combinaison.
  final strongHand = [
    for (final suit in [RamiSuit.epees, RamiSuit.coupes, RamiSuit.batons])
      c(suit, 12, 'q${suit.name}'),
    c(RamiSuit.deniers, 12, 'qd'),
    for (final suit in [RamiSuit.epees, RamiSuit.coupes, RamiSuit.batons])
      c(suit, 13, 'k${suit.name}'),
    c(RamiSuit.epees, 2, 'e2'),
    c(RamiSuit.epees, 3, 'e3'),
  ];

  test("l'IA ouvre si son ouverture dépasse la précédente", () {
    final state = playing(base, turn: 1, last: 51).copyWith(
      hands: [base.hands[0], strongHand, base.hands[2], base.hands[3]],
    );
    // 70 points : au-dessus de 52, ouverture.
    final next = aiStep(state, RamiAiLevel.difficile, () => 0.0);
    expect(next.opened[1], isTrue);
    expect(next.lastOpening, 70);
  });

  test("l'IA n'ouvre pas si son ouverture ne dépasse pas la précédente", () {
    final state = playing(base, turn: 1, last: 75).copyWith(
      hands: [base.hands[0], strongHand, base.hands[2], base.hands[3]],
    );
    final next = aiStep(state, RamiAiLevel.difficile, () => 0.0);
    expect(next.opened[1], isFalse);
    expect(next.lastOpening, 75);
    expect(next.table, isEmpty);
  });
}

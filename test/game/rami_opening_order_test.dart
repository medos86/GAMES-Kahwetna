// Ouvertures à la hausse : chaque ouverture doit dépasser la précédente de la manche.
// Les points sont posés sur la table (#496) : l'ouverture se fait dès que le seuil est atteint.
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
      firstTour: false,
    );

RamiState withHand(RamiState s, int seat, List<RamiCard> hand) => s.copyWith(
      hands: [
        for (var i = 0; i < s.hands.length; i++) i == seat ? hand : s.hands[i],
      ],
    );

// Trois rois (30) et trois dames (30) : deux combinaisons valides.
final kings3 = [
  c(RamiSuit.epees, 13, 'ks'),
  c(RamiSuit.coupes, 13, 'kh'),
  c(RamiSuit.batons, 13, 'kc'),
];
final queens3 = [
  c(RamiSuit.epees, 12, 'qs'),
  c(RamiSuit.coupes, 12, 'qh'),
  c(RamiSuit.deniers, 12, 'qd'),
];
final fives3 = [
  c(RamiSuit.epees, 5, 'fs'),
  c(RamiSuit.coupes, 5, 'fh'),
  c(RamiSuit.batons, 5, 'fc'),
];
final extra = c(RamiSuit.deniers, 2, 'x');

void main() {
  final base = dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0);

  test('la première ouverture de la manche demande 51 points', () {
    expect(minOpening(base), 51);
    expect(base.lastOpening, 0);
  });

  test('après une ouverture à 67, la suivante demande 68', () {
    expect(minOpening(base.copyWith(lastOpening: 67)), 68);
  });

  test('points posés sous 51 dans le tour : pas encore ouvert', () {
    final state = withHand(
      playing(base, turn: 0, last: 0),
      0,
      [...kings3, ...fives3, extra],
    );
    final low = poseMeld(
      poseMeld(state, ['ks', 'kh', 'kc']),
      ['fs', 'fh', 'fc'],
    );
    expect(low.opened[0], isFalse);
    expect(low.lastOpening, 0);
  });

  test('ouverture automatique dès que le total du tour atteint 51', () {
    final state = withHand(
      playing(base, turn: 0, last: 0),
      0,
      [...kings3, ...queens3, extra],
    );
    final ok = poseMeld(
      poseMeld(state, ['ks', 'kh', 'kc']),
      ['qs', 'qh', 'qd'],
    );
    expect(ok.opened[0], isTrue);
    expect(ok.lastOpening, 60);
    expect(ok.staged, isEmpty);
  });

  test('ouverture suivante : refusée à 60, acceptée à 61 et plus', () {
    final state = withHand(
      playing(base, turn: 1, last: 60),
      1,
      [...kings3, ...queens3, extra],
    );
    final same = poseMeld(
      poseMeld(state, ['ks', 'kh', 'kc']),
      ['qs', 'qh', 'qd'],
    );
    expect(same.opened[1], isFalse);

    final hand = [
      ...kings3,
      c(RamiSuit.deniers, 13, 'kd'),
      ...queens3,
      extra,
    ];
    final ok = poseMeld(
      poseMeld(withHand(state, 1, hand), ['ks', 'kh', 'kc', 'kd']),
      ['qs', 'qh', 'qd'],
    );
    expect(ok.opened[1], isTrue);
    expect(ok.lastOpening, 70);
  });

  test('le seuil est remis à 51 à la manche suivante', () {
    final ended = base.copyWith(lastOpening: 80);
    expect(minOpening(ended), 81);
    final fresh = dealRound([0, 0, 0, 0], 3, 2, 100, () => 0.0);
    expect(fresh.lastOpening, 0);
  });

  test('lastOpening absent d’une sauvegarde : valeur 0 à la lecture', () {
    final json = base.toJson()..remove('lastOpening');
    expect(RamiState.fromJson(json).lastOpening, 0);
  });

  test("l'IA ouvre si son ouverture dépasse la précédente", () {
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
    final state = playing(base, turn: 1, last: 51).copyWith(
      hands: [base.hands[0], strongHand, base.hands[2], base.hands[3]],
    );
    final next = aiStep(state, RamiAiLevel.difficile, () => 0.0);
    expect(next.opened[1], isTrue);
    expect(next.lastOpening, 70);
  });

  test("l'IA n'ouvre pas si son ouverture ne dépasse pas la précédente", () {
    final strongHand = [
      for (final suit in [RamiSuit.epees, RamiSuit.coupes, RamiSuit.batons])
        c(suit, 12, 'q${suit.name}'),
      c(RamiSuit.deniers, 12, 'qd'),
      for (final suit in [RamiSuit.epees, RamiSuit.coupes, RamiSuit.batons])
        c(suit, 13, 'k${suit.name}'),
      c(RamiSuit.epees, 2, 'e2'),
      c(RamiSuit.epees, 3, 'e3'),
    ];
    final state = playing(base, turn: 1, last: 75).copyWith(
      hands: [base.hands[0], strongHand, base.hands[2], base.hands[3]],
    );
    final next = aiStep(state, RamiAiLevel.difficile, () => 0.0);
    expect(next.opened[1], isFalse);
    expect(next.lastOpening, 75);
    expect(next.table, isEmpty);
  });
}

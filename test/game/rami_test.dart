import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank, [String? id]) =>
    RamiCard(id: id ?? '${suit.name}-$rank', suit: suit, rank: rank);

const joker = RamiCard(id: 'joker', suit: null, rank: 0);

RamiState inPlay(
  RamiState base, {
  required List<List<RamiCard>> hands,
  String? takenId,
  bool firstTour = false,
}) =>
    base.copyWith(
      phase: RamiPhase.play,
      turn: 0,
      hands: hands,
      opened: [false, false, false, false],
      staged: const [],
      takenId: takenId,
      firstTour: firstTour,
    );

/// Donne déterministe : le hasard vaut toujours 0.
RamiState fixedDeal() => dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0);

void main() {
  group('isValidMeld', () {
    test('suite de trois cartes de même couleur', () {
      expect(
        isValidMeld([
          c(RamiSuit.epees, 7),
          c(RamiSuit.epees, 8),
          c(RamiSuit.epees, 9),
        ]),
        isTrue,
      );
    });

    test('As bas : A-2-3 est valide', () {
      expect(
        isValidMeld([
          c(RamiSuit.coupes, 1),
          c(RamiSuit.coupes, 2),
          c(RamiSuit.coupes, 3),
        ]),
        isTrue,
      );
    });

    test('As haut : Q-K-A est valide', () {
      expect(
        isValidMeld([
          c(RamiSuit.coupes, 12),
          c(RamiSuit.coupes, 13),
          c(RamiSuit.coupes, 1),
        ]),
        isTrue,
      );
    });

    test('R-A-2 ne boucle pas et est refusé', () {
      expect(
        isValidMeld([
          c(RamiSuit.coupes, 13),
          c(RamiSuit.coupes, 1),
          c(RamiSuit.coupes, 2),
        ]),
        isFalse,
      );
    });

    test('suite de couleurs mélangées refusée', () {
      expect(
        isValidMeld([
          c(RamiSuit.coupes, 4),
          c(RamiSuit.epees, 5),
          c(RamiSuit.coupes, 6),
        ]),
        isFalse,
      );
    });

    test('brelan de trois couleurs différentes valide', () {
      expect(
        isValidMeld([
          c(RamiSuit.coupes, 9),
          c(RamiSuit.epees, 9),
          c(RamiSuit.batons, 9),
        ]),
        isTrue,
      );
    });

    test('brelan avec une couleur répétée refusé', () {
      expect(
        isValidMeld([
          c(RamiSuit.coupes, 9, 'a'),
          c(RamiSuit.coupes, 9, 'b'),
          c(RamiSuit.epees, 9),
        ]),
        isFalse,
      );
    });

    test('carré de quatre couleurs valide, cinq cartes refusées', () {
      final four = [for (final s in RamiSuit.values) c(s, 5)];
      expect(isValidMeld(four), isTrue);
      expect(isValidMeld([...four, joker]), isFalse);
    });

    test('un joker comble un trou dans une suite', () {
      expect(
        isValidMeld([c(RamiSuit.batons, 4), joker, c(RamiSuit.batons, 6)]),
        isTrue,
      );
    });

    test('moins de deux cartes naturelles refusé', () {
      expect(isValidMeld([c(RamiSuit.batons, 4), joker, joker]), isFalse);
    });
  });

  group('meldGroups', () {
    test('trouve la suite dans une main triée', () {
      final hand = [
        c(RamiSuit.epees, 2),
        c(RamiSuit.epees, 3),
        c(RamiSuit.epees, 4),
        c(RamiSuit.batons, 12),
      ];
      final groups = meldGroups(hand);
      expect(groups.length, 1);
      expect(groups.first.map((card) => card.id), [
        'epees-2',
        'epees-3',
        'epees-4',
      ]);
    });
  });

  group('donne', () {
    test(
      'quatre mains de 14, une pioche et une défausse, 108 cartes au total',
      () {
        final s = fixedDeal();
        expect([for (final h in s.hands) h.length], [14, 14, 14, 14]);
        expect(s.discard.length, 1);
        expect(s.stock.length, 51);
        final ids = {
          for (final h in s.hands) ...h.map((card) => card.id),
          ...s.stock.map((card) => card.id),
          ...s.discard.map((card) => card.id),
        };
        expect(ids.length, 108);
      },
    );

    test('quatre jokers dans le jeu', () {
      final s = fixedDeal();
      final all = [
        for (final h in s.hands) ...h,
        ...s.stock,
        ...s.discard,
      ];
      final jokers = all.where((card) => card.suit == null).toList();
      expect(jokers.length, 4);
      expect(jokers.map((card) => card.id).toSet().length, 4);
    });
  });

  group('ouverture', () {
    test('ouverture sous 51 points refusée (retour identique)', () {
      var s = inPlay(
        fixedDeal(),
        hands: [
          [
            c(RamiSuit.epees, 7, 'a'),
            c(RamiSuit.epees, 8, 'b'),
            c(RamiSuit.epees, 9, 'c'),
            c(RamiSuit.batons, 2),
          ],
          [c(RamiSuit.coupes, 2)],
          [c(RamiSuit.coupes, 3)],
          [c(RamiSuit.coupes, 4)],
        ],
      );
      s = poseMeld(s, ['a', 'b', 'c']);
      expect(s.staged.length, 1);
      expect(identical(commitOpening(s), s), isTrue);
    });

    test('annuler remet les cartes en main', () {
      final before = inPlay(
        fixedDeal(),
        hands: [
          [
            c(RamiSuit.epees, 7, 'a'),
            c(RamiSuit.epees, 8, 'b'),
            c(RamiSuit.epees, 9, 'c'),
            c(RamiSuit.batons, 2),
          ],
          [c(RamiSuit.coupes, 2)],
          [c(RamiSuit.coupes, 3)],
          [c(RamiSuit.coupes, 4)],
        ],
      );
      final staged = poseMeld(before, ['a', 'b', 'c']);
      final restored = cancelStaged(staged);
      expect(restored.staged, isEmpty);
      expect(restored.hands[0].length, 4);
    });
  });

  group('défausse', () {
    test('carte prise à la défausse refusée si la main a plus d une carte', () {
      final s = inPlay(
        fixedDeal(),
        takenId: 'taken',
        hands: [
          [c(RamiSuit.epees, 2, 'taken'), c(RamiSuit.batons, 5)],
          [c(RamiSuit.coupes, 2)],
          [c(RamiSuit.coupes, 3)],
          [c(RamiSuit.coupes, 4)],
        ],
      );
      expect(identical(discardCard(s, 'taken'), s), isTrue);
    });

    test('défausse normale passe le tour', () {
      final s = inPlay(
        fixedDeal(),
        hands: [
          [c(RamiSuit.epees, 2), c(RamiSuit.batons, 5)],
          [c(RamiSuit.coupes, 2)],
          [c(RamiSuit.coupes, 3)],
          [c(RamiSuit.coupes, 4)],
        ],
      );
      final next = discardCard(s, 'epees-2');
      expect(next.turn, 1);
      expect(next.phase, RamiPhase.draw);
      expect(next.discard.last.id, 'epees-2');
    });
  });

  group('points d\'ouverture par joueur (#369)', () {
    test('ouverture : points du joueur enregistrés', () {
      final s = inPlay(
        fixedDeal(),
        hands: [
          [c(RamiSuit.batons, 2, 'z')],
          [c(RamiSuit.coupes, 2)],
          [c(RamiSuit.coupes, 3)],
          [c(RamiSuit.coupes, 4)],
        ],
      ).copyWith(
        staged: [
          [
            c(RamiSuit.epees, 13, 'k1'),
            c(RamiSuit.coupes, 13, 'k2'),
            c(RamiSuit.batons, 13, 'k3'),
          ],
          [
            c(RamiSuit.epees, 12, 'q1'),
            c(RamiSuit.coupes, 12, 'q2'),
            c(RamiSuit.deniers, 1, 'a1'),
          ],
        ],
      );
      final next = commitOpening(s);
      expect(next.openings, [51, 0, 0, 0]);
      expect(next.opened[0], isTrue);
    });

    test('les points d\'ouverture survivent à la sérialisation', () {
      final s = fixedDeal().copyWith(openings: [60, 0, 52, 0]);
      final back = RamiState.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
      );
      expect(back.openings, [60, 0, 52, 0]);
    });
  });

  group('reprise d\'un joker sur la table (#390)', () {
    // Table : suite 4-5-[joker]-7 de bâtons, ouvert, tour du joueur 0.
    RamiState withRun(List<RamiCard> hand) => inPlay(
          fixedDeal(),
          hands: [
            hand,
            [c(RamiSuit.coupes, 2)],
            [c(RamiSuit.coupes, 3)],
            [c(RamiSuit.coupes, 4)],
          ],
        ).copyWith(
          opened: [true, false, false, false],
          table: [
            Meld(
              id: 'm1',
              cards: [
                c(RamiSuit.batons, 4, 'b4'),
                c(RamiSuit.batons, 5, 'b5'),
                joker,
                c(RamiSuit.batons, 7, 'b7'),
              ],
            ),
          ],
        );

    test('la carte naturelle prend la place du joker, le joker revient', () {
      final s = withRun([
        c(RamiSuit.batons, 6, 'b6'),
        c(RamiSuit.coupes, 9, 'x'),
      ]);
      final next = layOff(s, 'b6', 'm1');
      expect(next.table.single.cards.length, 4);
      expect(next.table.single.cards.any((card) => card.isJoker), isFalse);
      expect(next.hands[0].any((card) => card.isJoker), isTrue);
      expect(next.hands[0].any((card) => card.id == 'b6'), isFalse);
    });

    test('une carte qui ne convient pas au paquet ne reprend rien', () {
      final s = withRun([
        c(RamiSuit.coupes, 9, 'x'),
        c(RamiSuit.coupes, 2, 'y'),
      ]);
      final next = layOff(s, 'x', 'm1');
      expect(identical(next, s), isTrue);
    });

    // Table : brelan de dames [dame, dame, joker] (#443).
    RamiState withSet(List<RamiCard> hand) => inPlay(
          fixedDeal(),
          hands: [
            hand,
            [c(RamiSuit.coupes, 2)],
            [c(RamiSuit.coupes, 3)],
            [c(RamiSuit.coupes, 4)],
          ],
        ).copyWith(
          opened: [true, false, false, false],
          table: [
            Meld(
              id: 'm1',
              cards: [
                c(RamiSuit.batons, 12, 'd1'),
                c(RamiSuit.coupes, 12, 'd2'),
                joker,
              ],
            ),
          ],
        );

    test('brelan dame dame joker : une dame posée ne reprend pas le joker', () {
      final s = withSet([c(RamiSuit.epees, 12, 'd3')]);
      final next = takeJoker(s, 'd3', 'm1');
      expect(identical(next, s), isTrue);
      final laid = layOff(s, 'd3', 'm1');
      expect(laid.table.single.cards.any((card) => card.isJoker), isTrue);
      expect(laid.table.single.cards.length, 4);
    });

    test('carré dame dame dame joker : une dame posée reprend le joker', () {
      final s = withSet([c(RamiSuit.epees, 12, 'd3')]).copyWith(
        table: [
          Meld(
            id: 'm1',
            cards: [
              c(RamiSuit.batons, 12, 'd1'),
              c(RamiSuit.coupes, 12, 'd2'),
              c(RamiSuit.deniers, 12, 'd4'),
              joker,
            ],
          ),
        ],
      );
      final next = takeJoker(s, 'd3', 'm1');
      expect(identical(next, s), isFalse);
      expect(next.table.single.cards.any((card) => card.isJoker), isFalse);
      expect(next.hands[0].any((card) => card.isJoker), isTrue);
    });

    test('pas de reprise avant ouverture', () {
      final s = withRun([c(RamiSuit.batons, 6, 'b6')]).copyWith(
        opened: [false, false, false, false],
      );
      final next = takeJoker(s, 'b6', 'm1');
      expect(identical(next, s), isTrue);
    });
  });

  group('première tournée', () {
    final run = [
      c(RamiSuit.epees, 7, 'a'),
      c(RamiSuit.epees, 8, 'b'),
      c(RamiSuit.epees, 9, 'c'),
    ];

    test('la donne commence en première tournée', () {
      expect(fixedDeal().firstTour, isTrue);
    });

    test('pas de pose de combinaison pendant la première tournée', () {
      final s = inPlay(
        fixedDeal(),
        hands: [
          [...run, c(RamiSuit.batons, 2)],
          [c(RamiSuit.coupes, 2)],
          [c(RamiSuit.coupes, 3)],
          [c(RamiSuit.coupes, 4)],
        ],
        firstTour: true,
      );
      expect(poseMeld(s, ['a', 'b', 'c']), same(s));
    });

    test('pas de prise de la défausse pendant la première tournée', () {
      final s = inPlay(
        fixedDeal(),
        hands: [
          [c(RamiSuit.batons, 2)],
          [c(RamiSuit.coupes, 2)],
          [c(RamiSuit.coupes, 3)],
          [c(RamiSuit.coupes, 4)],
        ],
        firstTour: true,
      ).copyWith(phase: RamiPhase.draw);
      expect(canUseDiscardTop(s), isFalse);
      expect(drawDiscard(s), same(s));
    });

    test('la première tournée se termine au passage du donneur', () {
      RamiState playAt(int seat) {
        final hands = [
          [c(RamiSuit.coupes, 2)],
          [c(RamiSuit.coupes, 3)],
          [c(RamiSuit.coupes, 4)],
          [c(RamiSuit.coupes, 5)],
        ];
        hands[seat] = [c(RamiSuit.epees, 2, 'x'), c(RamiSuit.coupes, 6, 'y')];
        final s = inPlay(fixedDeal(), hands: hands, firstTour: true);
        return s.copyWith(turn: seat);
      }

      expect(discardCard(playAt(1), 'x').firstTour, isTrue);
      expect(discardCard(playAt(3), 'x').firstTour, isFalse);
    });

    test('le drapeau survit à la sérialisation', () {
      final s = fixedDeal();
      final back = RamiState.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
      );
      expect(back.firstTour, isTrue);
    });
  });

  group('sérialisation', () {
    test('aller-retour JSON', () {
      final s = fixedDeal();
      final back = RamiState.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
      );
      expect(jsonEncode(back.toJson()), jsonEncode(s.toJson()));
    });
  });
  group('score de manche (#416)', () {
    test('gagnant -10, perdant sans paquet +100', () {
      final s = inPlay(
        fixedDeal(),
        hands: [
          [c(RamiSuit.batons, 2, 'z')],
          [c(RamiSuit.coupes, 2)],
          [c(RamiSuit.coupes, 3)],
          [c(RamiSuit.coupes, 4)],
        ],
      ).copyWith(scores: [0, 0, 0, 0]);
      final next = discardCard(s, 'z');
      expect(next.phase, RamiPhase.end);
      expect(next.scores, [-10, 100, 100, 100]);
    });

    test('perdant ayant posé : points des cartes en main', () {
      final s = inPlay(
        fixedDeal(),
        hands: [
          [c(RamiSuit.batons, 2, 'z')],
          [joker, c(RamiSuit.coupes, 10), c(RamiSuit.coupes, 2)],
          [c(RamiSuit.coupes, 3)],
          [c(RamiSuit.coupes, 4)],
        ],
      ).copyWith(scores: [0, 0, 0, 0], opened: [false, true, false, false]);
      final next = discardCard(s, 'z');
      expect(next.scores, [-10, 32, 100, 100]);
    });
  });
}

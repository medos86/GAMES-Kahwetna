import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

RamiCard c(RamiSuit suit, int rank, [String? id]) =>
    RamiCard(id: id ?? '${suit.name}-$rank', suit: suit, rank: rank);

const joker = RamiCard(id: 'joker', suit: null, rank: 0);

RamiState inPlay(RamiState base, {required List<List<RamiCard>> hands, String? takenId}) =>
    base.copyWith(
      phase: RamiPhase.play,
      turn: 0,
      hands: hands,
      opened: [false, false, false, false],
      staged: const [],
      takenId: takenId,
    );

/// Donne déterministe : le hasard vaut toujours 0.
RamiState fixedDeal() => dealRound([0, 0, 0, 0], 3, 1, 100, () => 0.0);

void main() {
  group('isValidMeld', () {
    test('suite de trois cartes de même couleur', () {
      expect(
        isValidMeld([c(RamiSuit.epees, 7), c(RamiSuit.epees, 8), c(RamiSuit.epees, 9)]),
        isTrue,
      );
    });

    test('As bas : A-2-3 est valide', () {
      expect(
        isValidMeld([c(RamiSuit.coupes, 1), c(RamiSuit.coupes, 2), c(RamiSuit.coupes, 3)]),
        isTrue,
      );
    });

    test('As haut : Q-K-A est valide', () {
      expect(
        isValidMeld([c(RamiSuit.coupes, 12), c(RamiSuit.coupes, 13), c(RamiSuit.coupes, 1)]),
        isTrue,
      );
    });

    test('R-A-2 ne boucle pas et est refusé', () {
      expect(
        isValidMeld([c(RamiSuit.coupes, 13), c(RamiSuit.coupes, 1), c(RamiSuit.coupes, 2)]),
        isFalse,
      );
    });

    test('suite de couleurs mélangées refusée', () {
      expect(
        isValidMeld([c(RamiSuit.coupes, 4), c(RamiSuit.epees, 5), c(RamiSuit.coupes, 6)]),
        isFalse,
      );
    });

    test('brelan de trois couleurs différentes valide', () {
      expect(
        isValidMeld([c(RamiSuit.coupes, 9), c(RamiSuit.epees, 9), c(RamiSuit.batons, 9)]),
        isTrue,
      );
    });

    test('brelan avec une couleur répétée refusé', () {
      expect(
        isValidMeld([c(RamiSuit.coupes, 9, 'a'), c(RamiSuit.coupes, 9, 'b'), c(RamiSuit.epees, 9)]),
        isFalse,
      );
    });

    test('carré de quatre couleurs valide, cinq cartes refusées', () {
      final four = [
        for (final s in RamiSuit.values) c(s, 5),
      ];
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
      expect(groups.first.map((card) => card.id), ['epees-2', 'epees-3', 'epees-4']);
    });
  });

  group('donne', () {
    test('quatre mains de 13, une pioche et une défausse, 106 cartes au total', () {
      final s = fixedDeal();
      expect([for (final h in s.hands) h.length], [13, 13, 13, 13]);
      expect(s.discard.length, 1);
      expect(s.stock.length, 53);
      final ids = {
        for (final h in s.hands) ...h.map((card) => card.id),
        ...s.stock.map((card) => card.id),
        ...s.discard.map((card) => card.id),
      };
      expect(ids.length, 106);
    });
  });

  group('ouverture', () {
    test('ouverture sous 51 points refusée (retour identique)', () {
      var s = inPlay(fixedDeal(), hands: [
        [c(RamiSuit.epees, 7, 'a'), c(RamiSuit.epees, 8, 'b'), c(RamiSuit.epees, 9, 'c'), c(RamiSuit.batons, 2)],
        [c(RamiSuit.coupes, 2)],
        [c(RamiSuit.coupes, 3)],
        [c(RamiSuit.coupes, 4)],
      ]);
      s = poseMeld(s, ['a', 'b', 'c']);
      expect(s.staged.length, 1);
      expect(identical(commitOpening(s), s), isTrue);
    });

    test('annuler remet les cartes en main', () {
      final before = inPlay(fixedDeal(), hands: [
        [c(RamiSuit.epees, 7, 'a'), c(RamiSuit.epees, 8, 'b'), c(RamiSuit.epees, 9, 'c'), c(RamiSuit.batons, 2)],
        [c(RamiSuit.coupes, 2)],
        [c(RamiSuit.coupes, 3)],
        [c(RamiSuit.coupes, 4)],
      ]);
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

  group('sérialisation', () {
    test('aller-retour JSON', () {
      final s = fixedDeal();
      final back = RamiState.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(jsonEncode(back.toJson()), jsonEncode(s.toJson()));
    });
  });
}

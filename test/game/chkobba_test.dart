import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';

ChkobbaCard card(int rank, [ChkobbaSuit suit = ChkobbaSuit.batons]) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

/// Construit un état de jeu précis, sans tirage aléatoire.
ChkobbaState makeState({
  Map<Player, List<ChkobbaCard>>? hands,
  List<ChkobbaCard> table = const [],
  List<ChkobbaCard> deck = const [],
  Player turn = Player.player,
  Player? lastCapturer,
  Map<Player, List<ChkobbaCard>>? won,
  Map<Player, int>? scores,
  int target = 11,
}) {
  return ChkobbaState(
    targetScore: target,
    deck: deck,
    hands: hands ?? {Player.player: [], Player.opponent: []},
    table: table,
    won: won ?? {Player.player: [], Player.opponent: []},
    chkobbas: {Player.player: 0, Player.opponent: 0},
    scores: scores ?? {Player.player: 0, Player.opponent: 0},
    lastCapturer: lastCapturer,
    turn: turn,
    starter: Player.player,
    round: 1,
    winner: null,
  );
}

void main() {
  group('distribution', () {
    test('3 cartes par joueur, 4 sur la table, 30 au paquet', () {
      final s = newMatch(random: () => 0.5);
      expect(s.hands[Player.player]!.length, 3);
      expect(s.hands[Player.opponent]!.length, 3);
      expect(s.table.length, 4);
      expect(s.deck.length, 30);
    });

    test('les 40 cartes sont distinctes', () {
      final s = newMatch(random: () => 0.3);
      final all = [
        ...s.hands[Player.player]!,
        ...s.hands[Player.opponent]!,
        ...s.table,
        ...s.deck,
      ];
      expect(all.length, 40);
      expect(all.map((c) => c.id).toSet().length, 40);
    });
  });

  group('prises', () {
    test('une carte de même valeur sur la table se prend seule', () {
      final s = makeState(
        hands: {
          Player.player: [card(5)],
          Player.opponent: [card(9)],
        },
        table: [card(5, ChkobbaSuit.coupes), card(2), card(3)],
        deck: [card(1)],
      );
      final r = playCard(s, Player.player, 'batons-5');
      expect(r.captured.map((c) => c.id), ['coupes-5']);
      expect(r.state.table.map((c) => c.id), ['batons-2', 'batons-3']);
      expect(r.chkobba, isFalse);
    });

    test('un 7 prend 3 + 4 quand c\'est la seule combinaison', () {
      final s = makeState(
        hands: {
          Player.player: [card(7)],
          Player.opponent: [card(9)],
        },
        table: [card(3), card(4)],
        deck: [card(1)],
      );
      final r = playCard(s, Player.player, 'batons-7');
      expect(r.captured.map((c) => c.id).toSet(), {'batons-3', 'batons-4'});
      expect(r.state.table, isEmpty);
    });

    test(
      'ramasser toute la table fait une Chkobba, sauf avec la dernière carte',
      () {
        final avecPaquet = makeState(
          hands: {
            Player.player: [card(5)],
            Player.opponent: [card(9)],
          },
          table: [card(5)],
          deck: [card(1)],
        );
        final chkobba = playCard(avecPaquet, Player.player, 'batons-5');
        expect(chkobba.chkobba, isTrue);
        expect(chkobba.state.chkobbas[Player.player], 1);

        final derniere = makeState(
          hands: {
            Player.player: [card(5)],
            Player.opponent: [],
          },
          table: [card(5)],
          deck: [],
        );
        final sansPoint = playCard(derniere, Player.player, 'batons-5');
        expect(sansPoint.chkobba, isFalse);
        expect(sansPoint.state.chkobbas[Player.player], 0);
      },
    );

    test('une carte sans prise pose sur la table et passe la main', () {
      final s = makeState(
        hands: {
          Player.player: [card(8)],
          Player.opponent: [card(9)],
        },
        table: [card(2)],
        deck: [card(1)],
      );
      final r = playCard(s, Player.player, 'batons-8');
      expect(r.captured, isEmpty);
      expect(r.state.table.map((c) => c.id), ['batons-2', 'batons-8']);
      expect(r.state.turn, Player.opponent);
    });

    test('le 7 de deniers ramassé déclenche la Haya', () {
      final s = makeState(
        hands: {
          Player.player: [card(7, ChkobbaSuit.deniers)],
          Player.opponent: [card(9)],
        },
        table: [card(7, ChkobbaSuit.coupes)],
        deck: [card(1)],
      );
      final r = playCard(s, Player.player, 'deniers-7');
      expect(r.haya, isTrue);
    });
  });

  group('fin de manche', () {
    test('plus de cartes ramassées donne le point « Cartes »', () {
      final s = makeState(
        won: {
          Player.player: [card(1), card(2), card(3)],
          Player.opponent: [card(4)],
        },
      );
      final r = scoreRound(s);
      expect(r.points[Player.player]!.map((p) => p.label), ['Cartes']);
      expect(r.state.scores[Player.player], 1);
    });

    test('les cartes restées sur la table vont au dernier ramasseur', () {
      final s = makeState(
        table: [card(9)],
        lastCapturer: Player.opponent,
        won: {
          Player.player: [card(1)],
          Player.opponent: [card(4)],
        },
      );
      final r = scoreRound(s);
      expect(r.state.table, isEmpty);
      expect(
        r.points[Player.opponent]!.map((p) => p.label),
        contains('Cartes'),
      );
    });

    test('atteindre le score cible désigne le gagnant', () {
      final s = makeState(
        scores: {Player.player: 10, Player.opponent: 0},
        won: {
          Player.player: [card(1), card(2), card(3)],
          Player.opponent: [card(4)],
        },
      );
      final r = scoreRound(s);
      expect(r.state.scores[Player.player], 11);
      expect(r.state.winner, Player.player);
    });
  });

  group('adversaire', () {
    test('le niveau facile joue une carte de sa main', () {
      final s = makeState(
        hands: {
          Player.player: [card(1)],
          Player.opponent: [card(2), card(3), card(4)],
        },
        table: [card(6)],
      );
      final id = chooseOpponentCard(
        s,
        ChkobbaAiLevel.facile,
        random: () => 0.99,
      );
      expect(s.hands[Player.opponent]!.map((c) => c.id), contains(id));
    });

    test('les niveaux moyen et difficile jouent une carte de sa main', () {
      final s = makeState(
        hands: {
          Player.player: [card(1)],
          Player.opponent: [card(2), card(7), card(4)],
        },
        table: [card(7, ChkobbaSuit.coupes), card(3)],
      );
      for (final level in [ChkobbaAiLevel.moyen, ChkobbaAiLevel.difficile]) {
        final id = chooseOpponentCard(s, level);
        expect(s.hands[Player.opponent]!.map((c) => c.id), contains(id));
      }
    });

    test(
      'facile : sans prise quand r() est bas, la carte reste sur le tapis',
      () {
        final s = makeState(
          hands: {
            Player.player: [card(1)],
            Player.opponent: [card(6)],
          },
          table: [card(6, ChkobbaSuit.coupes)],
        );
        // Tirages à 0 : carte 0, et décision « ne pas prendre » (0 < 0,4).
        final move = chooseOpponentMove(
          s,
          ChkobbaAiLevel.facile,
          random: () => 0.0,
        );
        expect(move.cardId, 'batons-6');
        expect(move.capture, isFalse);

        final result = playCard(
          s,
          Player.opponent,
          move.cardId,
          discardOnly: true,
        );
        expect(result.captured, isEmpty);
        expect(
          result.state.table.map((c) => c.id),
          containsAll(['coupes-6', 'batons-6']),
        );
      },
    );

    test('moyen : priorité au 7 de carreau capturé', () {
      final s = makeState(
        hands: {
          Player.player: [card(1)],
          Player.opponent: [
            card(2, ChkobbaSuit.epees),
            card(7, ChkobbaSuit.coupes),
          ],
        },
        table: [card(7, ChkobbaSuit.deniers)],
      );
      final move = chooseOpponentMove(s, ChkobbaAiLevel.moyen);
      expect(move.cardId, 'coupes-7');
      expect(move.capture, isTrue);
    });

    test('difficile lit la main du joueur : ne laisse pas une table qu\'il ramasse d\'un coup', () {
      // Table 5 + 2 (somme 7). Le joueur a un 7 pour tout ramasser. L'IA ne doit pas
      // ajouter une carte qui laisse la table à ramasser d'un coup, quand une autre carte est sûre.
      final s = makeState(
        hands: {
          Player.player: [card(7, ChkobbaSuit.coupes)],
          Player.opponent: [
            card(4, ChkobbaSuit.epees),
            card(9, ChkobbaSuit.batons),
          ],
        },
        table: [card(5, ChkobbaSuit.deniers), card(2, ChkobbaSuit.coupes)],
      );
      final id = chooseOpponentCard(s, ChkobbaAiLevel.difficile);
      expect(s.hands[Player.opponent]!.map((c) => c.id), contains(id));
    });

    test('difficile ne lit pas la main du joueur : même coup quelle que soit sa main', () {
      final base = {
        Player.opponent: [
          card(4, ChkobbaSuit.epees),
          card(9, ChkobbaSuit.batons),
        ],
      };
      final table = [card(5, ChkobbaSuit.deniers), card(2, ChkobbaSuit.coupes)];
      final withSeven = makeState(
        hands: {
          ...base,
          Player.player: [card(7, ChkobbaSuit.coupes)],
        },
        table: table,
      );
      final withOne = makeState(
        hands: {
          ...base,
          Player.player: [card(1, ChkobbaSuit.batons)],
        },
        table: table,
      );
      expect(
        chooseOpponentCard(withSeven, ChkobbaAiLevel.difficile),
        chooseOpponentCard(withOne, ChkobbaAiLevel.difficile),
      );
    });
  });
}

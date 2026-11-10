import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_controller.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';

ChkobbaCard card(ChkobbaSuit suit, int rank) => ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

/// Duel : le joueur a le 1 de bâtons, l'adversaire le 2 de deniers, le tapis porte le 9 de coupes.
/// Le 1 ne prend rien (aucune somme ni carte de même valeur) : le tour passe à l'adversaire,
/// qui ne peut rien prendre non plus. Pioche vide : la manche se termine après la dernière carte.
ChkobbaState duel() => ChkobbaState(
      targetScore: 11,
      deck: const [],
      hands: {
        Player.player: [card(ChkobbaSuit.batons, 1)],
        Player.opponent: [card(ChkobbaSuit.deniers, 2)],
      },
      table: [card(ChkobbaSuit.coupes, 9)],
      won: {Player.player: [], Player.opponent: []},
      chkobbas: {Player.player: 0, Player.opponent: 0},
      scores: {Player.player: 0, Player.opponent: 0},
      lastCapturer: null,
      turn: Player.player,
      starter: Player.player,
      round: 1,
      winner: null,
    );

void main() {
  group('ChkobbaController : minuteurs (issue #20)', () {
    test('le tour de l\'adversaire : carte montrée à 1 s, jouée à 2,2 s', () {
      fakeAsync((async) {
        final ctrl = ChkobbaController(
          targetScore: 11,
          level: ChkobbaAiLevel.facile,
          initialState: duel(),
        );

        ctrl.tapPlayerCard('batons-1');
        expect(ctrl.game.turn, Player.opponent);
        expect(ctrl.isOpponentThinking, isTrue);

        async.elapse(const Duration(milliseconds: 999));
        expect(ctrl.revealedCardId, isNull, reason: 'pas encore montrée avant 1 s');

        async.elapse(const Duration(milliseconds: 1));
        expect(ctrl.revealedCardId, 'deniers-2');

        async.elapse(const Duration(milliseconds: 1200));
        expect(ctrl.game.turn, Player.player);
        expect(ctrl.revealedCardId, isNull);
        expect(ctrl.game.table.map((c) => c.id), containsAll(['coupes-9', 'batons-1', 'deniers-2']));

        ctrl.dispose();
      });
    });

    test('fin de manche : le récapitulatif apparaît 1,5 s après la dernière carte', () {
      fakeAsync((async) {
        final ctrl = ChkobbaController(
          targetScore: 11,
          level: ChkobbaAiLevel.facile,
          initialState: duel(),
        );

        ctrl.tapPlayerCard('batons-1');
        // Fin du tour de l'adversaire à 2,2 s, puis 1,5 s avant le décompte.
        async.elapse(const Duration(milliseconds: 2200));
        expect(ctrl.game.hands[Player.player], isEmpty);
        expect(ctrl.game.hands[Player.opponent], isEmpty);
        expect(ctrl.roundSummary, isNull);

        async.elapse(const Duration(milliseconds: 1499));
        expect(ctrl.roundSummary, isNull);

        async.elapse(const Duration(milliseconds: 1));
        expect(ctrl.roundSummary, isNotNull);

        ctrl.dispose();
      });
    });

    test('dispose annule tous les minuteurs en attente', () {
      fakeAsync((async) {
        final ctrl = ChkobbaController(
          targetScore: 11,
          level: ChkobbaAiLevel.facile,
          initialState: duel(),
        );

        ctrl.tapPlayerCard('batons-1');
        expect(async.pendingTimers, isNotEmpty);

        ctrl.dispose();
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('pendant le tour de l\'adversaire, un clic du joueur n\'a aucun effet', () {
      fakeAsync((async) {
        final ctrl = ChkobbaController(
          targetScore: 11,
          level: ChkobbaAiLevel.facile,
          initialState: duel(),
        );

        ctrl.tapPlayerCard('batons-1');
        final before = ctrl.game.table.length;
        ctrl.tapPlayerCard('batons-1');
        expect(ctrl.game.table.length, before);

        ctrl.dispose();
      });
    });
  });
}

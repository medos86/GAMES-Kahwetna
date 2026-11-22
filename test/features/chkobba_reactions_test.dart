import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/reactions/reaction_mood.dart';
import 'package:kahwetne/core/services/reaction_stickers.dart';
import 'package:kahwetne/features/chkobba/chkobba_controller.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';

ChkobbaCard card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

/// Le joueur pose le 9 de bâtons sur le 9 de coupes seul sur le tapis : Chkobba.
ChkobbaState chkobbaSetup() => ChkobbaState(
      targetScore: 11,
      deck: const [],
      hands: {
        Player.player: [card(ChkobbaSuit.batons, 9)],
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
  group('ChkobbaController : réactions des avatars (#761)', () {
    tearDown(() {
      reactionStickers.value = true;
    });

    test('réglage désactivé : aucune réaction après une Chkobba', () {
      fakeAsync((async) {
        reactionStickers.value = false;
        final ctrl = ChkobbaController(
          targetScore: 11,
          level: ChkobbaAiLevel.facile,
          initialState: chkobbaSetup(),
        );

        ctrl.tapPlayerCard('batons-9');
        expect(ctrl.reactionOf(Player.player), isNull);
        expect(ctrl.reactionOf(Player.opponent), isNull);

        ctrl.dispose();
      });
    });

    test('aucune réaction au départ', () {
      final ctrl = ChkobbaController(
        targetScore: 11,
        level: ChkobbaAiLevel.facile,
        initialState: chkobbaSetup(),
      );
      expect(ctrl.reactionOf(Player.player), isNull);
      expect(ctrl.reactionOf(Player.opponent), isNull);
      ctrl.dispose();
    });

    test('Chkobba : rire puis retour au calme', () {
      fakeAsync((async) {
        final ctrl = ChkobbaController(
          targetScore: 11,
          level: ChkobbaAiLevel.facile,
          initialState: chkobbaSetup(),
        );

        ctrl.tapPlayerCard('batons-9');
        expect(ctrl.reactionOf(Player.player), ReactionMood.laugh);
        expect(ctrl.reactionOf(Player.opponent), ReactionMood.shock);

        async.elapse(ChkobbaController.reactionDuration);
        expect(ctrl.reactionOf(Player.player), isNull);
        expect(ctrl.reactionOf(Player.opponent), isNull);

        ctrl.dispose();
      });
    });

    test('prise simple : capteur rit, adversaire réfléchit (#788)', () {
      fakeAsync((async) {
        final ctrl = ChkobbaController(
          targetScore: 11,
          level: ChkobbaAiLevel.facile,
          initialState: ChkobbaState(
            targetScore: 11,
            deck: const [],
            hands: {
              Player.player: [card(ChkobbaSuit.batons, 9)],
              Player.opponent: [card(ChkobbaSuit.deniers, 2)],
            },
            table: [
              card(ChkobbaSuit.coupes, 9),
              card(ChkobbaSuit.deniers, 2),
            ],
            won: {Player.player: [], Player.opponent: []},
            chkobbas: {Player.player: 0, Player.opponent: 0},
            scores: {Player.player: 0, Player.opponent: 0},
            lastCapturer: null,
            turn: Player.player,
            starter: Player.player,
            round: 1,
            winner: null,
          ),
        );

        ctrl.tapPlayerCard('batons-9');
        expect(ctrl.reactionOf(Player.player), ReactionMood.laugh);
        expect(ctrl.reactionOf(Player.opponent), ReactionMood.thinking);

        ctrl.dispose();
      });
    });

    test('durée d\'affichage des réactions : 2 s', () {
      expect(
        ChkobbaController.reactionDuration,
        const Duration(milliseconds: 2000),
      );
    });
  });
}

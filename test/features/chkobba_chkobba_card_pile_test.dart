import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_controller.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';

ChkobbaCard card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

// Chkobba (#594) : la carte qui a fait la Chkobba reste disponible pour être posée sous le tas de son auteur.
void main() {
  test('la carte de Chkobba est mémorisée pour le joueur qui la fait', () {
    final ctrl = ChkobbaController(
      targetScore: 11,
      level: ChkobbaAiLevel.facile,
      initialState: ChkobbaState(
        targetScore: 11,
        deck: const [],
        hands: {
          Player.player: [card(ChkobbaSuit.batons, 1)],
          Player.opponent: [card(ChkobbaSuit.deniers, 7)],
        },
        table: [card(ChkobbaSuit.coupes, 1)],
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
    expect(ctrl.chkobbaCardOf(Player.player), isNull);

    ctrl.tapPlayerCard('batons-1');

    expect(ctrl.game.chkobbas[Player.player], 1);
    expect(ctrl.chkobbaCardOf(Player.player)?.id, 'batons-1');
    expect(ctrl.chkobbaCardOf(Player.opponent), isNull);
    expect(
      ctrl.chkobbaCardsOf(Player.player).map((c) => c.id),
      ['batons-1'],
    );
    expect(ctrl.chkobbaCardsOf(Player.opponent), isEmpty);
  });
}

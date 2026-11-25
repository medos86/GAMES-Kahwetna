import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_controller.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';

ChkobbaCard card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

// Redonne en cours de manche : son joué ET drapeau levé pour que l'écran anime (#redonne).
void main() {
  group('ChkobbaController : redonne animée', () {
    test('la redonne automatique lève le drapeau une seule fois', () {
      fakeAsync((async) {
        final ctrl = ChkobbaController(
          targetScore: 11,
          level: ChkobbaAiLevel.facile,
          initialState: ChkobbaState(
            targetScore: 11,
            deck: [
              card(ChkobbaSuit.coupes, 1),
              card(ChkobbaSuit.coupes, 2),
              card(ChkobbaSuit.coupes, 3),
              card(ChkobbaSuit.coupes, 4),
              card(ChkobbaSuit.coupes, 6),
              card(ChkobbaSuit.coupes, 7),
            ],
            hands: {Player.player: [], Player.opponent: []},
            table: [card(ChkobbaSuit.coupes, 5)],
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

        // Avant la redonne : rien à animer.
        expect(ctrl.takeDeal(), isFalse);

        // Manche épuisée : la redonne part après 1 s.
        ctrl.startFresh();
        async.elapse(const Duration(milliseconds: 1000));

        expect(ctrl.game.hands[Player.player]!, isNotEmpty);
        expect(ctrl.game.hands[Player.opponent]!, isNotEmpty);
        expect(ctrl.takeDeal(), isTrue);
        // Le drapeau est lu une fois : la mise à jour suivante ne relance pas la distribution.
        expect(ctrl.takeDeal(), isFalse);

        ctrl.dispose();
      });
    });
  });
}

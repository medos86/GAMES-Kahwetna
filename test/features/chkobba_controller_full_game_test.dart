import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_controller.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';

/// Partie complète du contrôleur (issue #20) : le joueur humain joue automatiquement
/// (première carte, première capture proposée, récapitulatifs validés) jusqu'à la fin.
void main() {
  for (final level in ChkobbaAiLevel.values) {
    test('partie complète contre l\'IA ${level.name} : se termine sans exception, sans minuteur restant', () {
      fakeAsync((async) {
        final ctrl = ChkobbaController(targetScore: 11, level: level);
        var steps = 0;
        const maxSteps = 20000;

        while (ctrl.game.winner == null && steps++ < maxSteps) {
          final game = ctrl.game;
          final pending = ctrl.pendingCapture;
          if (pending != null) {
            ctrl.choosePendingCapture(pending.options.first);
          } else if (ctrl.roundSummary != null) {
            ctrl.continueAfterRound();
          } else if (game.turn == Player.player &&
              !ctrl.isOpponentThinking &&
              game.hands[Player.player]!.isNotEmpty) {
            ctrl.tapPlayerCard(game.hands[Player.player]!.first.id);
          }
          async.elapse(const Duration(milliseconds: 250));
        }

        expect(steps, lessThan(maxSteps), reason: 'la partie doit finir');
        expect(ctrl.game.winner, isNotNull);
        expect(ctrl.game.scores[Player.player], greaterThanOrEqualTo(0));

        ctrl.dispose();
        expect(async.pendingTimers, isEmpty);
      });
    });
  }
}

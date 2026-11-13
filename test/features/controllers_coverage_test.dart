import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_controller.dart';
import 'package:kahwetne/features/coinche/coinche_controller.dart';
import 'package:kahwetne/features/domino/domino_controller.dart';
import 'package:kahwetne/features/ludo/ludo_controller.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_controller.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/game/coinche.dart';
import 'package:kahwetne/game/domino.dart';
import 'package:kahwetne/game/ludo.dart';
import 'package:kahwetne/game/rami.dart' as rules;

// Parcours des contrôleurs de partie : actions du joueur, tour de l'IA et sauvegarde (#167).
void main() {
  test('Domino : sélection, pose, pioche et sauvegarde', () {
    fakeAsync((async) {
      final c = DominoController(
        targetScore: 50,
        difficulty: Difficulty.facile,
        random: () => 0.37,
      );
      final tile = c.playable.first;
      c.tapTile(tile);
      expect(c.selectedTileId, tile.id);
      c.tapTile(tile);
      c.tapTile(c.playable.first);
      c.playSelected(DominoSide.left);
      c.playSelected(DominoSide.right);
      c.drawOrPass();
      c.flagDrawInvalid();
      c.flagInvalid(tile.id);
      c.chainEnds;
      c.mustDraw;
      c.isAiTurn;
      c.aiDelay;
      async.elapse(const Duration(seconds: 3));
      final json = c.snapshot();
      final copy = DominoController(
        targetScore: 50,
        difficulty: Difficulty.facile,
        random: () => 0.37,
      );
      if (json != null) copy.applySnapshot(json);
      c.restart();
      c.startNextRound();
      c.newGame();
      c.startFresh();
      c.dispose();
      copy.dispose();
    });
  });

  test('Rami : sélection, dépôt, défausse et reprise', () {
    fakeAsync((async) {
      final c = RamiController(
        targetScore: 100,
        difficulty: rules.RamiAiLevel.facile,
        random: () => 0.0,
      );
      c.drawFromStock();
      final first = c.hand.first.id;
      c.tap(first);
      c.groupFor(first);
      c.sortBy(RamiSortMode.rank);
      c.sortBy(RamiSortMode.suit);
      c.pose();
      c.commit();
      c.cancel();
      c.layOffSelected('m1');
      c.layOffCard(first, 'm1');
      c.discardSelected();
      c.discardOne(first);
      c.dropCard(first, RamiDropHand(first, after: true));
      c.dropCard(first, RamiDropMeld('m1'));
      c.dropCard(first, const RamiDropTable());
      c.dropCard(first, const RamiDropDiscard());
      c.dropCard(first, null);
      c.readyPoints;
      c.stagedPoints;
      c.selectionIsMeld;
      c.layEligible;
      c.groupOf;
      c.nextRound();
      c.restart();
      async.elapse(const Duration(seconds: 3));
      final json = c.snapshot();
      if (json != null) {
        final copy = RamiController(
          targetScore: 100,
          difficulty: rules.RamiAiLevel.facile,
          random: () => 0.0,
        );
        copy.applySnapshot(json);
        copy.dispose();
      }
      c.startFresh();
      c.newGame();
      c.dispose();
    });
  });

  test('Coinche : enchères, annonce et jeu de la carte', () {
    fakeAsync((async) {
      final c = CoincheController(
        target: 1000,
        difficulty: Difficulty.facile,
        random: () => 0.37,
      );
      c.setChoiceMode(CoincheSuit.coupes);
      c.setChoiceValue(90);
      c.minValue;
      c.canContre;
      c.canSurcoinche;
      c.isBiddingTurn;
      c.isHumanPlayTurn;
      c.legalIds;
      c.announce();
      if (c.isHumanPlayTurn && c.legalIds.isNotEmpty) {
        c.playHuman(c.legalIds.first);
      }
      async.elapse(const Duration(seconds: 5));
      c.nextRound();
      c.restart();
      c.snapshot();
      c.startFresh();
      c.newGame();
      c.dispose();
    });
  });

  test('Ludo : lancer, jouer un pion et sauvegarde', () {
    fakeAsync((async) {
      final c = LudoController(
        playerCount: 2,
        difficulty: LudoAiLevel.facile,
        random: () => 0.37,
      );
      c.humans;
      c.solo;
      c.humanTurn;
      c.roundOver;
      c.canRoll;
      c.roll();
      for (final id in c.legalIds.toList()) {
        c.tapToken(id);
      }
      async.elapse(const Duration(seconds: 5));
      final json = c.snapshot();
      if (json != null) {
        final copy = LudoController(
          playerCount: 2,
          difficulty: LudoAiLevel.facile,
          random: () => 0.37,
        );
        copy.applySnapshot(json);
        copy.dispose();
      }
      c.restart();
      c.startFresh();
      c.newGame();
      c.dispose();
    });
  });

  test('Chkobba : carte jouée, capture au choix et fin de manche', () {
    fakeAsync((async) {
      final c = ChkobbaController(
        targetScore: 11,
        level: ChkobbaAiLevel.facile,
        random: () => 0.37,
      );
      c.tableSlots();
      c.revealedCardId;
      c.isOpponentThinking;
      c.tapPlayerCard(c.game.hands[Player.player]!.first.id);
      c.cancelPendingCapture();
      c.continueAfterRound();
      async.elapse(const Duration(seconds: 5));
      c.roundSummary;
      c.hayaBy;
      c.pendingCapture;
      c.snapshot();
      c.startFresh();
      c.newGame();
      c.startNewGame();
      c.dispose();
    });
  });
}

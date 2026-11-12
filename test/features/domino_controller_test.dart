import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/domino/domino_controller.dart';
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/game/domino.dart';
import 'package:kahwetne/game/domino_ai.dart';
import 'package:kahwetne/features/menu/menu_models.dart';

DominoState _state({
  required Map<Player, List<DominoTile>> hands,
  List<PlacedTile> chain = const [],
  int? leftEnd,
  int? rightEnd,
  Player turn = Player.player,
  List<DominoTile> boneyard = const [],
}) {
  return DominoState(
    hands: hands,
    boneyard: boneyard,
    chain: chain,
    leftEnd: leftEnd,
    rightEnd: rightEnd,
    scores: const {Player.player: 0, Player.opponent: 0},
    turn: turn,
    consecutivePasses: 0,
    roundWinner: null,
    matchWinner: null,
    pointsAwarded: 0,
    targetScore: 50,
    round: 1,
  );
}

const _t = DominoTile.new;

void main() {
  group('IA (chooseOpponentMove)', () {
    test('joue la tuile au plus grand total, côté droit si elle s\'y pose', () {
      // Chaîne 3|5 : extrémités gauche 3 et droite 5.
      final state = _state(
        hands: {
          Player.player: [_t(id: '0-1', a: 0, b: 1)],
          Player.opponent: [
            _t(id: '1-3', a: 1, b: 3), // total 4, pose à gauche (3)
            _t(id: '2-5', a: 2, b: 5), // total 7, pose à droite (5)
            _t(id: '0-2', a: 0, b: 2), // total 2
          ],
        },
        chain: [const PlacedTile(id: '3-5', a: 3, b: 5, left: 3, right: 5)],
        leftEnd: 3,
        rightEnd: 5,
        turn: Player.opponent,
      );
      final move = chooseOpponentMove(state);
      expect(move.action, DominoAction.play);
      expect(move.tile!.id, '2-5');
      expect(move.side, DominoSide.right);
    });

    test(
      'difficile garde les doubles pour la fin, le moyen joue le plus fort',
      () {
        final state = _state(
          hands: {
            Player.player: [_t(id: '0-1', a: 0, b: 1)],
            Player.opponent: [
              _t(id: '5-5', a: 5, b: 5), // total 10, double
              _t(id: '4-5', a: 4, b: 5), // total 9, pose à droite (5)
            ],
          },
          chain: [const PlacedTile(id: '3-5', a: 3, b: 5, left: 3, right: 5)],
          leftEnd: 3,
          rightEnd: 5,
          turn: Player.opponent,
        );
        expect(chooseOpponentMove(state).tile!.id, '5-5');
        final hard = chooseOpponentMove(state, level: DominoAiLevel.difficile);
        expect(hard.tile!.id, '4-5');
        expect(hard.side, DominoSide.right);
      },
    );

    test('facile : tirage à 0 joue la première tuile légale, sur le seul côté possible', () {
      final state = _state(
        hands: {
          Player.player: [_t(id: '0-1', a: 0, b: 1)],
          Player.opponent: [
            _t(id: '1-3', a: 1, b: 3), // pose à gauche (3)
            _t(id: '2-5', a: 2, b: 5), // pose à droite (5)
          ],
        },
        chain: [const PlacedTile(id: '3-5', a: 3, b: 5, left: 3, right: 5)],
        leftEnd: 3,
        rightEnd: 5,
        turn: Player.opponent,
      );
      final move = chooseOpponentMove(
        state,
        level: DominoAiLevel.facile,
        random: () => 0.0,
      );
      expect(move.tile!.id, '1-3');
      expect(move.side, DominoSide.left);
    });

    test(
      'pioche quand aucune tuile ne se pose et que la pioche n\'est pas vide',
      () {
        final state = _state(
          hands: {
            Player.player: [_t(id: '0-0', a: 0, b: 0)],
            Player.opponent: [_t(id: '4-6', a: 4, b: 6)],
          },
          chain: [const PlacedTile(id: '1-1', a: 1, b: 1, left: 1, right: 1)],
          leftEnd: 1,
          rightEnd: 1,
          turn: Player.opponent,
          boneyard: [_t(id: '2-2', a: 2, b: 2)],
        );
        expect(chooseOpponentMove(state).action, DominoAction.draw);
      },
    );

    test('passe quand rien ne se pose et la pioche est vide', () {
      final state = _state(
        hands: {
          Player.player: [_t(id: '0-0', a: 0, b: 0)],
          Player.opponent: [_t(id: '4-6', a: 4, b: 6)],
        },
        chain: [const PlacedTile(id: '1-1', a: 1, b: 1, left: 1, right: 1)],
        leftEnd: 1,
        rightEnd: 1,
        turn: Player.opponent,
      );
      expect(chooseOpponentMove(state).action, DominoAction.pass);
    });
  });

  group('contrôleur (tour de l\'IA)', () {
    test('après un coup du joueur, l\'IA agit après le délai du niveau', () {
      fakeAsync((async) {
        final controller = DominoController(
          targetScore: 50,
          difficulty: Difficulty.facile,
          random: () => 0.37,
        );
        // Premier coup du joueur : chaîne vide, pose libre.
        final opening = controller.playable.first;
        controller.tapTile(opening);
        final afterPlayer = controller.game.toJson();

        async.elapse(const Duration(milliseconds: 1249));
        expect(
          controller.game.toJson(),
          equals(afterPlayer),
          reason: 'pas encore de coup de l\'IA',
        );

        async.elapse(const Duration(milliseconds: 1));
        expect(
          controller.game.toJson(),
          isNot(equals(afterPlayer)),
          reason: 'l\'IA a agi à 1250 ms',
        );
        controller.dispose();
      });
    });

    test('le délai dépend du niveau (650 ms en difficile)', () {
      final controller = DominoController(
        targetScore: 50,
        difficulty: Difficulty.difficile,
        random: () => 0.37,
      );
      expect(controller.aiDelay, const Duration(milliseconds: 650));
      controller.dispose();
    });
  });
}

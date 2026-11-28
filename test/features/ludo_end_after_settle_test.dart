// Fin de partie : l'écran de fin n'apparaît qu'après l'arrivée du dernier pion (#1089).
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_controller.dart';
import 'package:kahwetne/game/ludo.dart';

List<Token> _tokens(LudoColor color, List<int> progress) {
  return [
    for (var i = 0; i < progress.length; i++)
      Token(id: '${color.name}-$i', color: color, progress: progress[i]),
  ];
}

void main() {
  test('la fin ne s affiche qu après l animation du dernier pion', () {
    fakeAsync((async) {
      // Rouge et vert sont déjà classés : le bleu, dernier pion à 56, finit la partie.
      final state = newLudoGame().copyWith(
        turn: LudoColor.blue,
        phase: LudoPhase.move,
        dice: 1,
        rankings: [LudoColor.red, LudoColor.green],
        tokens: [
          ..._tokens(LudoColor.red, [57, 57, 57, 57]),
          ..._tokens(LudoColor.green, [57, 57, 57, 57]),
          ..._tokens(LudoColor.yellow, [0, 0, 0, 0]),
          ..._tokens(LudoColor.blue, [56, 57, 57, 57]),
        ],
      );
      final c = LudoController(
        playerCount: 1,
        difficulty: LudoAiLevel.facile,
        random: () => 0.0,
      );
      c.applySnapshot(state.toJson());

      c.tapToken('blue-0');
      // Le calcul est fait, mais le pion est encore en chemin.
      expect(c.game.phase, LudoPhase.end);
      expect(c.roundOver, isFalse);
      expect(c.choiceOpen, isFalse);

      async.elapse(const Duration(seconds: 10));
      expect(c.roundOver, isTrue);
      expect(c.choiceOpen, isFalse);
      c.dispose();
    });
  });

  test('le choix de fin attend l animation du dernier pion', () {
    fakeAsync((async) {
      final state = newLudoGame().copyWith(
        turn: LudoColor.blue,
        phase: LudoPhase.move,
        dice: 1,
        rankings: [],
        tokens: [
          ..._tokens(LudoColor.blue, [56, 57, 57, 57]),
          ..._tokens(LudoColor.red, [10, 10, 10, 10]),
        ],
      );
      final c = LudoController(
        playerCount: 1,
        difficulty: LudoAiLevel.facile,
        random: () => 0.0,
      );
      c.applySnapshot(state.toJson());

      c.tapToken('blue-0');
      expect(c.humansDone, isTrue);
      expect(c.choiceOpen, isFalse);

      // Le choix s'ouvre dès que l'animation est finie (l'IA peut jouer entre-temps).
      var waited = 0;
      while (!c.choiceOpen && waited < 60000) {
        async.elapse(const Duration(milliseconds: 100));
        waited += 100;
      }
      expect(c.choiceOpen, isTrue);
      expect(c.roundOver, isFalse);
      c.dispose();
    });
  });
}

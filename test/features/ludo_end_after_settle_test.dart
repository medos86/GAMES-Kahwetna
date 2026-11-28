// Fin de partie : l'écran de fin n'apparaît qu'après l'arrivée du dernier pion (#1089).
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_controller.dart';
import 'package:kahwetne/game/ludo.dart';

void main() {
  test('le dernier pion arrivé n affiche la fin qu après son animation', () {
    fakeAsync((async) {
      // Rouge et vert sont déjà classés : le bleu, dernier pion à 56, rend la partie finie.
      final tokens = <Token>[
        for (var i = 0; i < 4; i++)
          Token(id: 'red-$i', color: LudoColor.red, progress: ludoFinish),
        for (var i = 0; i < 4; i++)
          Token(id: 'green-$i', color: LudoColor.green, progress: ludoFinish),
        for (var i = 0; i < 4; i++)
          Token(id: 'yellow-$i', color: LudoColor.yellow, progress: 0),
        for (var i = 0; i < 4; i++)
          Token(
            id: 'blue-$i',
            color: LudoColor.blue,
            progress: i == 0 ? 56 : ludoFinish,
          ),
      ];
      final state = newLudoGame().copyWith(
        turn: LudoColor.blue,
        phase: LudoPhase.move,
        dice: 1,
        rankings: [LudoColor.red, LudoColor.green],
        tokens: tokens,
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

  test('le choix de fin s affiche seulement une fois le dernier pion arrivé', () {
    fakeAsync((async) {
      final tokens = <Token>[
        for (var i = 0; i < 4; i++)
          Token(
            id: 'blue-$i',
            color: LudoColor.blue,
            progress: i == 0 ? 56 : ludoFinish,
          ),
        for (var i = 0; i < 4; i++)
          Token(id: 'red-$i', color: LudoColor.red, progress: 10),
      ];
      final state = newLudoGame().copyWith(
        turn: LudoColor.blue,
        phase: LudoPhase.move,
        dice: 1,
        rankings: [],
        tokens: tokens,
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

      async.elapse(const Duration(seconds: 10));
      expect(c.choiceOpen, isTrue);
      c.dispose();
    });
  });
}

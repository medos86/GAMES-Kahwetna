// Tests du contrôleur du Ludo : tour de l'IA après son délai, et dispose().
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_controller.dart';
import 'package:kahwetne/game/ludo.dart';

void main() {
  test('un tour humain sans coup possible passe au joueur suivant, puis l\'IA joue après 1100 ms', () {
    fakeAsync((async) {
      // Tirage constant 0.0 : dé = 1, aucun pion ne sort : le bleu passe.
      final c = LudoController(
        playerCount: 1,
        difficulty: LudoAiLevel.facile,
        random: () => 0.0,
      );
      expect(c.humanTurn, isTrue);
      expect(async.pendingTimers, isEmpty);

      c.roll();
      expect(c.game.turn, LudoColor.red); // rouge = IA
      final rollsBefore = c.game.rollId;

      async.elapse(const Duration(milliseconds: 1099));
      expect(c.game.rollId, rollsBefore);

      async.elapse(const Duration(milliseconds: 1));
      expect(c.game.rollId, rollsBefore + 1); // l'IA a lancé le dé
      c.dispose();
    });
  });

  test('dispose annule le minuteur de l\'IA', () {
    fakeAsync((async) {
      final c = LudoController(
        playerCount: 1,
        difficulty: LudoAiLevel.moyen,
        random: () => 0.0,
      );
      c.roll();
      expect(async.pendingTimers, isNotEmpty);
      c.dispose();
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('les humains sont les N premières couleurs du source', () {
    final c = LudoController(playerCount: 2, difficulty: LudoAiLevel.facile);
    expect(c.humans, [LudoColor.blue, LudoColor.yellow]);
    expect(c.solo, isFalse);
    c.dispose();
  });

  test('ludoRollDelay suit le niveau : 1100 / 850 / 600 ms', () {
    expect(
      ludoRollDelay(LudoAiLevel.facile),
      const Duration(milliseconds: 1100),
    );
    expect(ludoRollDelay(LudoAiLevel.moyen), const Duration(milliseconds: 850));
    expect(
      ludoRollDelay(LudoAiLevel.difficile),
      const Duration(milliseconds: 600),
    );
  });
}

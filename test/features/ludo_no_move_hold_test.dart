// Pause « non » après un lancer sans coup possible (#855).
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_controller.dart';
import 'package:kahwetne/game/ludo.dart';

void main() {
  test('pendant la pause, le joueur qui a lancé reste le joueur affiché', () {
    fakeAsync((async) {
      final c = LudoController(
        playerCount: 1,
        difficulty: LudoAiLevel.facile,
        random: () => 0.0,
      );
      c.roll();
      expect(c.game.note, isA<NoMoveNote>());
      expect(c.shownTurn, LudoColor.blue);
      expect(c.canRoll, isFalse);
      expect(c.legalIds, isEmpty);
      c.dispose();
    });
  });

  test('la pause dure ludoNoMoveHold puis le tour passe', () {
    fakeAsync((async) {
      final c = LudoController(
        playerCount: 1,
        difficulty: LudoAiLevel.facile,
        random: () => 0.0,
      );
      c.roll();
      async.elapse(kLudoDieRollDuration + ludoNoMoveHold);
      expect(c.refusedColor, isNull);
      expect(c.shownTurn, LudoColor.red);
      c.dispose();
    });
  });

  test('un lancer avec un coup possible ne déclenche pas la pause', () {
    fakeAsync((async) {
      // Tirage 0.99 : dé = 6, un pion sort de la base.
      final c = LudoController(
        playerCount: 1,
        difficulty: LudoAiLevel.facile,
        random: () => 0.99,
      );
      c.roll();
      expect(c.game.note, isNull);
      expect(c.refusedColor, isNull);
      expect(c.shownTurn, LudoColor.blue);
      c.dispose();
    });
  });

  test('#1046 : le dé roule entièrement avant le « non » et la pause', () {
    fakeAsync((async) {
      final c = LudoController(
        playerCount: 1,
        difficulty: LudoAiLevel.facile,
        random: () => 0.0,
      );
      c.roll();
      expect(c.rolling, isTrue);
      expect(c.refusedColor, isNull);
      async.elapse(kLudoDieRollDuration - const Duration(milliseconds: 1));
      expect(c.rolling, isTrue);
      expect(c.refusedColor, isNull);
      async.elapse(const Duration(milliseconds: 1));
      expect(c.rolling, isFalse);
      expect(c.refusedColor, LudoColor.blue);
      expect(c.shownTurn, LudoColor.blue);
      c.dispose();
    });
  });

  test('#1046 : un lancer avec coup possible reste bloqué le temps du dé', () {
    fakeAsync((async) {
      final c = LudoController(
        playerCount: 1,
        difficulty: LudoAiLevel.facile,
        random: () => 0.99,
      );
      c.roll();
      expect(c.rolling, isTrue);
      expect(c.legalIds, isEmpty);
      async.elapse(kLudoDieRollDuration);
      expect(c.rolling, isFalse);
      expect(c.refusedColor, isNull);
      expect(c.legalIds, isNotEmpty);
      c.dispose();
    });
  });
}

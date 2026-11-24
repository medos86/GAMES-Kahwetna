// Le dé du joueur suivant ne se lance qu'après la fin de l'animation du coup (#778).
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_controller.dart';
import 'package:kahwetne/features/ludo/ludo_layout.dart';
import 'package:kahwetne/game/ludo.dart';

void main() {
  test('aucun pion bougé : pas d\'animation à attendre', () {
    const tokens = [Token(id: 'b0', color: LudoColor.blue, progress: 3)];
    expect(ludoMoveSettleMs(tokens, tokens), 0);
  });

  test('un pion qui avance prend une durée positive', () {
    const before = [Token(id: 'b0', color: LudoColor.blue, progress: 3)];
    const after = [Token(id: 'b0', color: LudoColor.blue, progress: 5)];
    expect(ludoMoveSettleMs(before, after), greaterThan(0));
  });

  test('une capture ajoute le délai de la victime avant son trajet', () {
    const before = [
      Token(id: 'b0', color: LudoColor.blue, progress: 1),
      Token(id: 'r0', color: LudoColor.red, progress: 10),
    ];
    const after = [
      Token(id: 'b0', color: LudoColor.blue, progress: 2),
      Token(id: 'r0', color: LudoColor.red, progress: 0),
    ];
    expect(
      ludoMoveSettleMs(before, after),
      greaterThanOrEqualTo(ludoVictimDelayFor(before, after)),
    );
    expect(ludoVictimDelayFor(before, after), greaterThan(0));
  });

  test('le joueur suivant ne peut pas lancer pendant l\'animation du coup', () {
    fakeAsync((async) {
      // Tirage 0.99 : dé = 6, un pion sort de la base et le joueur rejoue.
      final c = LudoController(
        playerCount: 2,
        difficulty: LudoAiLevel.facile,
        random: () => 0.99,
      );
      c.roll();
      expect(c.legalIds, isNotEmpty);
      c.tapToken(c.legalIds.first);

      expect(c.game.phase, LudoPhase.roll);
      expect(c.canRoll, isFalse);
      expect(c.legalIds, isEmpty);

      async.elapse(const Duration(seconds: 3));
      expect(c.canRoll, isTrue);
      c.dispose();
    });
  });

  test('dispose annule aussi l\'attente de fin d\'animation', () {
    fakeAsync((async) {
      final c = LudoController(
        playerCount: 2,
        difficulty: LudoAiLevel.facile,
        random: () => 0.99,
      );
      c.roll();
      c.tapToken(c.legalIds.first);
      expect(async.pendingTimers, isNotEmpty);
      c.dispose();
      expect(async.pendingTimers, isEmpty);
    });
  });
  // #882 : la victime ne part qu'une fois l'attaquant arrivé, donc une capture dure plus longtemps.
  test('#882 : un coup de capture dure plus longtemps qu\'un coup normal', () {
    const redTrack = Token(id: 'r0', color: LudoColor.red, progress: 10);
    const blueBefore = Token(id: 'b0', color: LudoColor.blue, progress: 1);
    const blueMove = Token(id: 'b0', color: LudoColor.blue, progress: 3);
    final normal = ludoMoveSettleMs(
      const [blueBefore, redTrack],
      const [blueMove, redTrack],
    );
    final capture = ludoMoveSettleMs(
      const [blueBefore, redTrack],
      const [
        blueMove,
        Token(id: 'r0', color: LudoColor.red, progress: 0),
      ],
    );
    expect(normal, greaterThan(0));
    expect(capture, greaterThan(normal));
  });

  test('#869 : la sortie de base prend une durée positive et rapide', () {
    const before = [Token(id: 'b0', color: LudoColor.blue, progress: 0)];
    const after = [Token(id: 'b0', color: LudoColor.blue, progress: 1)];
    final ms = ludoMoveSettleMs(before, after);
    expect(ms, greaterThan(0));
  });
}

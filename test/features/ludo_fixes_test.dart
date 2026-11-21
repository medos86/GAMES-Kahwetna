import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_controller.dart';
import 'package:kahwetne/features/ludo/ludo_layout.dart';
import 'package:kahwetne/game/ludo.dart';

void main() {
  test('un pion qui sort ne déplace pas les autres pions de la base', () {
    final before = [
      for (var i = 0; i < 4; i++)
        Token(id: 'red-$i', color: LudoColor.red, progress: 0),
    ];
    final after = [
      Token(id: 'red-0', color: LudoColor.red, progress: 0),
      Token(id: 'red-1', color: LudoColor.red, progress: 1),
      Token(id: 'red-2', color: LudoColor.red, progress: 0),
      Token(id: 'red-3', color: LudoColor.red, progress: 0),
    ];
    final a = {for (final p in layoutTokens(before)) p.token.id: p};
    final b = {for (final p in layoutTokens(after)) p.token.id: p};
    for (final id in ['red-0', 'red-2', 'red-3']) {
      expect(b[id]!.x, a[id]!.x, reason: id);
      expect(b[id]!.y, a[id]!.y, reason: id);
    }
  });

  test('le dé garde la dernière face obtenue par le joueur', () {
    final c = LudoController(
      playerCount: 1,
      difficulty: LudoAiLevel.facile,
      random: () => 0.0,
    );
    expect(c.lastFaceOf(LudoColor.red), isNull);
    c.applySnapshot(
      newLudoGame(LudoColor.red).copyWith(phase: LudoPhase.roll).toJson(),
    );
    c.startFresh();
    c.roll();
    expect(c.lastFaceOf(LudoColor.red), 1);
    c.dispose();
  });

  test('les joueurs sont affichés dans l\'ordre bleu, rouge, vert, jaune', () {
    expect(ludoHumanOrder, [
      LudoColor.blue,
      LudoColor.red,
      LudoColor.green,
      LudoColor.yellow,
    ]);
  });
}

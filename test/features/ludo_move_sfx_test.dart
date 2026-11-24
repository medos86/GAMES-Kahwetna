// Sons des coups de Ludo (issue #794) : pion déplacé, capturé, entré à la maison.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/audio/sounds.dart';
import 'package:kahwetne/features/ludo/ludo_controller.dart';
import 'package:kahwetne/game/ludo.dart';

void main() {
  final before = newLudoGame();
  final first = before.tokens.first;

  LudoState moveFirstTokenTo(int progress, {Object? note}) {
    final tokens = [
      for (final t in before.tokens)
        if (t.id == first.id)
          Token(id: t.id, color: t.color, progress: progress)
        else
          t,
    ];
    return before.copyWith(tokens: tokens, note: note);
  }

  test('aucun pion bougé : pas de son', () {
    expect(ludoMoveSfx(before, before.copyWith(dice: 3)), isNull);
  });

  test('pion déplacé sans capture ni arrivée : pas de pion', () {
    expect(ludoMoveSfx(before, moveFirstTokenTo(5)), Sfx.pawnMove);
  });

  // #882 : le pion qui capture avance comme un pion ordinaire ; le son de capture
  // part avec la galipette de la victime (voir le contrôleur).
  test('capture : le pion joué garde son bruit de pion', () {
    final after = moveFirstTokenTo(
      5,
      note: CapturedNote(first.color, [LudoColor.red]),
    );
    expect(ludoMoveSfx(before, after), Sfx.pawnMove);
  });

  test('arrivée au centre : son de maison', () {
    final after = moveFirstTokenTo(
      57,
      note: FinishedNote(first.color, 1),
    );
    expect(ludoMoveSfx(before, after), Sfx.pawnHome);
  });
}

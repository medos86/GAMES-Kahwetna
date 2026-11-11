import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/game/domino.dart';
import 'package:kahwetne/game/domino_ai.dart';

void main() {
  test('difficile joue toujours une tuile légale, sur un côté légal', () {
    for (var seed = 0; seed < 50; seed++) {
      var state = newDominoRound(targetScore: 50, random: math.Random(seed).nextDouble);
      // Joue jusqu'à ce que l'IA ait au moins un coup, en laissant le joueur jouer la première tuile légale.
      for (var step = 0; step < 40 && state.roundWinner == null; step++) {
        if (state.turn == Player.opponent) {
          final move = chooseOpponentMove(state, level: DominoAiLevel.difficile);
          if (move.action == DominoAction.play) {
            expect(playableTiles(state, Player.opponent).map((t) => t.id), contains(move.tile!.id));
            expect(canPlace(move.tile!, state, move.side!), isTrue);
          }
          state = move.action == DominoAction.play
              ? playDomino(state, Player.opponent, move.tile!.id, move.side!)
              : move.action == DominoAction.draw
                  ? drawDomino(state, Player.opponent)
                  : passDomino(state, Player.opponent);
        } else {
          final mine = playableTiles(state, Player.player);
          if (mine.isEmpty) {
            state = drawDomino(state, Player.player);
            if (state.turn == Player.player && playableTiles(state, Player.player).isEmpty) {
              state = passDomino(state, Player.player);
            }
          } else {
            state = playDomino(state, Player.player, mine.first.id, DominoSide.right);
          }
        }
      }
    }
  });

  test('difficile ne lit pas la main du joueur : même coup quelle que soit sa main', () {
    final base = newDominoRound(targetScore: 50, random: math.Random(7).nextDouble);
    // Autre main pour le joueur (tuiles de la pioche) : la décision de l'IA ne doit pas changer.
    final other = base.copyWith(
      hands: {
        ...base.hands,
        Player.player: base.boneyard.take(7).toList(),
      },
    );
    final a = chooseOpponentMove(base, level: DominoAiLevel.difficile);
    final b = chooseOpponentMove(other, level: DominoAiLevel.difficile);
    expect(a.action, b.action);
    expect(a.tile?.id, b.tile?.id);
    expect(a.side, b.side);
  });
}

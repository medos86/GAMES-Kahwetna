// Décision de l'IA du Domino, reprise de DominoGameScreen.tsx (effet « IA »).
// Dart pur. Le délai entre deux coups est géré par le contrôleur, pas ici.

import 'domino.dart';
import 'common.dart';

enum DominoAction { play, draw, pass }

class DominoAiMove {
  const DominoAiMove._(this.action, this.tile, this.side);

  const DominoAiMove.play(DominoTile tile, DominoSide side) : this._(DominoAction.play, tile, side);
  const DominoAiMove.draw() : this._(DominoAction.draw, null, null);
  const DominoAiMove.pass() : this._(DominoAction.pass, null, null);

  final DominoAction action;
  final DominoTile? tile;
  final DominoSide? side;
}

int _pips(DominoTile tile) => tile.a + tile.b;

/// Jouer la tuile au plus grand total (la première en cas d'égalité, comme le tri stable du source),
/// côté droit si elle s'y pose, sinon à gauche ; à défaut piocher ; à défaut passer.
DominoAiMove chooseOpponentMove(DominoState state) {
  final moves = playableTiles(state, Player.opponent);
  if (moves.isNotEmpty) {
    var best = moves.first;
    for (final tile in moves.skip(1)) {
      if (_pips(tile) > _pips(best)) best = tile;
    }
    final side = state.chain.isNotEmpty && canPlace(best, state, DominoSide.right)
        ? DominoSide.right
        : DominoSide.left;
    return DominoAiMove.play(best, side);
  }
  if (state.boneyard.isNotEmpty) return const DominoAiMove.draw();
  return const DominoAiMove.pass();
}

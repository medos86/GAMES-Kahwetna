// Décision de l'IA du Domino, reprise de DominoGameScreen.tsx (effet « IA »).
// Dart pur. Le délai entre deux coups est géré par le contrôleur, pas ici.

import 'dart:math' as math;

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

/// Niveau de l'IA (même valeurs que Difficulty côté interface).
enum DominoAiLevel { facile, moyen, difficile }

/// Côté d'un coup : le droit si la tuile s'y pose, sinon le gauche (comportement du source).
DominoSide _preferredSide(DominoTile tile, DominoState state) =>
    state.chain.isNotEmpty && canPlace(tile, state, DominoSide.right) ? DominoSide.right : DominoSide.left;

/// Coup de l'IA.
/// - Facile : tuile légale au hasard, côté au hasard parmi les côtés possibles.
/// - Moyen : la tuile au plus grand total (la première en cas d'égalité, comme le tri stable du source),
///   côté droit si elle s'y pose, sinon à gauche.
/// - Difficile : comme le moyen, mais les doubles sont gardés pour la fin (ils posent des points
///   à l'adversaire en fin de partie). Pas de lecture de la main adverse.
/// À défaut de tuile jouable : piocher, puis passer.
DominoAiMove chooseOpponentMove(
  DominoState state, {
  DominoAiLevel level = DominoAiLevel.moyen,
  RandomDouble? random,
}) {
  final moves = playableTiles(state, Player.opponent);
  if (moves.isNotEmpty) {
    if (level == DominoAiLevel.facile) {
      final r = random ?? _defaultRandom.nextDouble;
      final tile = moves[(r() * moves.length).floor()];
      final sides = [
        for (final side in DominoSide.values)
          if (canPlace(tile, state, side)) side,
      ];
      final sideIndex = (r() * sides.length).floor();
      final side = sides.isEmpty
          ? DominoSide.left
          : sides[sideIndex >= sides.length ? sides.length - 1 : sideIndex];
      return DominoAiMove.play(tile, side);
    }

    var best = moves.first;
    for (final tile in moves.skip(1)) {
      if (_score(tile, level) > _score(best, level)) best = tile;
    }
    return DominoAiMove.play(best, _preferredSide(best, state));
  }
  if (state.boneyard.isNotEmpty) return const DominoAiMove.draw();
  return const DominoAiMove.pass();
}

int _score(DominoTile tile, DominoAiLevel level) {
  final pips = _pips(tile);
  return level == DominoAiLevel.difficile && tile.a == tile.b ? pips - 3 : pips;
}

final _defaultRandom = math.Random();

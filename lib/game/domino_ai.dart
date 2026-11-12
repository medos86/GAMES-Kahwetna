// Décision de l'IA du Domino, reprise de DominoGameScreen.tsx (effet « IA »).
// Dart pur. Le délai entre deux coups est géré par le contrôleur, pas ici.

import 'dart:math' as math;

import 'domino.dart';
import 'common.dart';

enum DominoAction { play, draw, pass }

class DominoAiMove {
  const DominoAiMove._(this.action, this.tile, this.side);

  const DominoAiMove.play(DominoTile tile, DominoSide side)
    : this._(DominoAction.play, tile, side);
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
    state.chain.isNotEmpty && canPlace(tile, state, DominoSide.right)
    ? DominoSide.right
    : DominoSide.left;

/// Coup de l'IA.
/// - Facile : tuile légale au hasard, côté au hasard parmi les côtés possibles.
/// - Moyen : la tuile au plus grand total (la première en cas d'égalité, comme le tri stable du source),
///   côté droit si elle s'y pose, sinon à gauche.
/// - Difficile : voir [_difficileMove] (estime les options du joueur, garde les doubles, sans lire sa main).
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

    if (level == DominoAiLevel.difficile) return _difficileMove(state, moves);

    var best = moves.first;
    for (final tile in moves.skip(1)) {
      if (_score(tile, level) > _score(best, level)) best = tile;
    }
    return DominoAiMove.play(best, _preferredSide(best, state));
  }
  if (state.boneyard.isNotEmpty) return const DominoAiMove.draw();
  return const DominoAiMove.pass();
}

int _score(DominoTile tile, DominoAiLevel level) => _pips(tile);

/// Toutes les tuiles du jeu (28), sans doublon.
List<DominoTile> _allTiles() => [
  for (var a = 0; a <= 6; a++)
    for (var b = a; b <= 6; b++) DominoTile(id: '$a-$b', a: a, b: b),
];

/// Extrémités (gauche, droite) après avoir posé `tile` du côté `side`.
List<int> _endsAfter(DominoTile tile, DominoState state, DominoSide side) {
  if (state.chain.isEmpty) return [tile.a, tile.b];
  final ends = <int>[state.leftEnd!, state.rightEnd!];
  if (side == DominoSide.left) {
    ends[0] = tile.a == state.leftEnd ? tile.b : tile.a;
  } else {
    ends[1] = tile.a == state.rightEnd ? tile.b : tile.a;
  }
  return ends;
}

/// Difficile (loyal) : ne lit que la chaîne et sa propre main.
/// Pour chaque coup, compte les tuiles inconnues que le joueur pourrait poser sur les extrémités
/// qui en résulteraient (pioche et main du joueur). Préfère les coups qui en laissent le moins,
/// garde les doubles pour la fin, et choisit le côté le plus restrictif.
DominoAiMove _difficileMove(DominoState state, List<DominoTile> moves) {
  final ownHand = {for (final t in state.hands[Player.opponent]!) t.id};
  final onTable = {for (final t in state.chain) t.id};
  final unseen = [
    for (final t in _allTiles())
      if (!ownHand.contains(t.id) && !onTable.contains(t.id)) t,
  ];

  DominoTile? bestTile;
  var bestSide = DominoSide.left;
  var bestValue = double.negativeInfinity;
  for (final tile in moves) {
    final sides = state.chain.isEmpty
        ? const [DominoSide.left]
        : [
            for (final side in DominoSide.values)
              if (canPlace(tile, state, side)) side,
          ];
    for (final side in sides) {
      final ends = _endsAfter(tile, state, side);
      final playerOptions = unseen
          .where(
            (u) =>
                u.id != tile.id && (ends.contains(u.a) || ends.contains(u.b)),
          )
          .length;
      final value =
          _pips(tile) - (tile.a == tile.b ? 3 : 0) - 0.5 * playerOptions;
      if (value > bestValue) {
        bestValue = value;
        bestTile = tile;
        bestSide = side;
      }
    }
  }
  return DominoAiMove.play(bestTile ?? moves.first, bestSide);
}

final _defaultRandom = math.Random();

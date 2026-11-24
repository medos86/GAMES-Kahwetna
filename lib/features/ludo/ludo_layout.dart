// Placement des pions sur le plateau 15 × 15 (layoutTokens de LudoGameScreen.tsx).
// Pur Dart : aucun import Flutter, donc testable sans émulateur.
// Les coordonnées sont exprimées en unités de case (le plateau fait 15 unités).

import 'dart:math' as math;

import '../../game/ludo.dart';
import '../../core/avatars/turn_avatar_motion.dart';

const ludoBoardUnits = 15;
const ludoTokenSize = 0.9;
const ludoStackSize = 0.52;

/// Décalages des pions quand plusieurs occupent la même case (diagonale).
const ludoStackOffsets = <List<double>>[
  [-0.24, -0.24],
  [0.24, -0.24],
  [-0.24, 0.24],
  [0.24, 0.24],
];

/// Taille d'un pion à l'écran : un pion en mouvement garde sa taille pleine,
/// il ne se réduit qu'en arrivant sur sa case (#798).
double ludoVisualBaseSize(bool moving, double placedSize) {
  return moving ? ludoTokenSize : placedSize;
}

/// Décalage d'un pion parmi [count] sur une même case ([order] à partir de 0) (#681).
/// Jusqu'à 4 pions : diagonales fixes. Au-delà : grille carrée, donc aucun nombre de pions ne sort des bornes.
List<double> ludoStackOffset(int order, int count) {
  if (count <= ludoStackOffsets.length) {
    return ludoStackOffsets[count == 2 ? order * 3 : order];
  }
  final side = math.sqrt(count).ceil();
  final step = 0.48 / (side - 1);
  return [-0.24 + (order % side) * step, -0.24 + (order ~/ side) * step];
}

/// Emplacements des pions en base, relatifs au coin de la maison ([dr, dc]).
const ludoBaseSlots = <List<double>>[
  [1.5, 1.5],
  [1.5, 4.5],
  [4.5, 1.5],
  [4.5, 4.5],
];

/// Coin de la maison de chaque couleur (ligne, colonne).
Cell ludoCorner(LudoColor color) => switch (color) {
      LudoColor.red => const Cell(0, 0),
      LudoColor.green => const Cell(0, 9),
      LudoColor.yellow => const Cell(9, 9),
      LudoColor.blue => const Cell(9, 0),
    };

class PlacedToken {
  const PlacedToken({
    required this.token,
    required this.x,
    required this.y,
    required this.size,
  });

  final Token token;

  /// Centre du pion, en unités de case (colonne, ligne).
  final double x;
  final double y;

  /// Diamètre, en unités de case.
  final double size;
}

/// Centre du plateau, en unités de case.
const ludoGoalCentre = 7.5;

/// Quatre emplacements d'arrivée d'une couleur, relatifs au centre, pour la couleur rouge
/// (triangle dans la pointe ouest du centre) : trois sommets et le centre du triangle (#859).
/// Côté 0,9 case, distance centre-sommet 0,52 case : un pion arrivé (diamètre 0,5 case)
/// ne touche aucun de ses voisins, et le triangle reste dans la pointe ouest.
const _ludoGoalTriangleRed = <List<double>>[
  [-1.21, -0.45],
  [-1.21, 0.45],
  [-0.43, 0],
  [-0.95, 0],
];

/// Nombre de quarts de tour (sens horaire) depuis le rouge : ouest, nord, est, sud.
int _ludoQuarterTurns(LudoColor color) => switch (color) {
      LudoColor.red => 0,
      LudoColor.green => 1,
      LudoColor.yellow => 2,
      LudoColor.blue => 3,
    };

/// Emplacement d'arrivée du pion de rang [order] (0 à 3) parmi les pions arrivés de [color] (#378, #859).
/// Les quatre pions d'une couleur forment un triangle dans la pointe de sa maison ; les autres
/// couleurs reprennent la même figure, tournée de 90° autour du centre : le plateau reste symétrique.
({double x, double y}) ludoGoalSlot(LudoColor color, [int order = 0]) {
  var dx = _ludoGoalTriangleRed[order % _ludoGoalTriangleRed.length][0];
  var dy = _ludoGoalTriangleRed[order % _ludoGoalTriangleRed.length][1];
  for (var turn = 0; turn < _ludoQuarterTurns(color); turn++) {
    final rx = -dy;
    dy = dx;
    dx = rx;
  }
  return (x: ludoGoalCentre + dx, y: ludoGoalCentre + dy);
}

/// Taille de l'avatar d'un joueur sur sa carte, en dp (#665).
const double ludoAvatarSize = 34;

/// Taille de l'avatar du joueur dont c'est le tour : plus grand que les autres (#665).
const double ludoActiveAvatarSize = 42;

/// Taille de l'avatar selon l'état actif (#665).
double ludoAvatarSizeFor({required bool active}) =>
    active ? ludoActiveAvatarSize : ludoAvatarSize;

/// Respiration du joueur actif, t de 0 à 1 sur un cycle : de 1 à 1,05 et retour (#665).
double ludoBreathScale(double t) => turnAvatarBreathScale(t);

/// Saut ordinaire d'un pion, en cases (#378).
const double ludoHopHeight = 0.45;

/// Saut de capture sur les deux dernières cases avant la cible (#662).
const double ludoCaptureHopHeight = 1.0;

/// Arc de la victime renvoyée à la base, en cases (#662).
const double ludoCatapultHeight = 1.6;

/// Agrandissement maximal de l'attaquant au sommet de son saut de capture (#662).
const double ludoCaptureMaxScale = 1.4;

/// Attente avant le départ de la victime : l'attaquant arrive d'abord (#662).
const int ludoVictimDelayMs = 900;

/// Hauteur du saut à la position [t] (0 à 1) d'un segment de trajet.
double ludoLiftAt(double t, {required bool capture, required bool lastCells}) {
  final height = capture && lastCells ? ludoCaptureHopHeight : ludoHopHeight;
  return math.sin(math.pi * t) * height;
}

/// Hauteur de l'arc de la victime à la position [t] (0 à 1).
double ludoCatapultLift(double t) => math.sin(math.pi * t) * ludoCatapultHeight;

/// Agrandissement de l'attaquant : 1 aux extrémités, maximal au sommet.
double ludoCaptureScale(double t) =>
    1 + (ludoCaptureMaxScale - 1) * math.sin(math.pi * t);

/// Centres des cases traversées de [from] à [to] (exclus). Sert à faire sauter le pion case par case.
List<({double x, double y})> ludoHopWaypoints(
  LudoColor color,
  int from,
  int to,
) {
  final points = <({double x, double y})>[];
  for (var p = from + 1; p < to; p++) {
    final cell = cellOf(Token(id: '', color: color, progress: p));
    if (cell == null) continue;
    points.add((x: cell.col + 0.5, y: cell.row + 0.5));
  }
  return points;
}

/// Calcule le centre et la taille de chaque pion.
List<PlacedToken> layoutTokens(List<Token> tokens) {
  final positions = [
    for (final token in tokens) (token: token, cell: cellOf(token)),
  ];

  final counts = <String, int>{};
  for (final p in positions) {
    final cell = p.cell;
    if (cell == null || p.token.progress == ludoFinish) continue;
    final key = '${cell.row}:${cell.col}';
    counts[key] = (counts[key] ?? 0) + 1;
  }

  final seen = <String, int>{};
  // Place fixe de chaque pion dans sa base : son rang parmi les pions de sa couleur,
  // quel que soit l'état des autres. Ainsi un pion qui sort ne fait pas bouger les autres.
  final ownRank = <String, int>{};
  final rankCount = <LudoColor, int>{};
  for (final token in tokens) {
    final rank = rankCount[token.color] ?? 0;
    ownRank[token.id] = rank;
    rankCount[token.color] = rank + 1;
  }

  return [
    for (final p in positions)
      if (p.cell == null)
        _basePlacement(p.token, ownRank[p.token.id]!)
      else if (p.token.progress == ludoFinish)
        _finishPlacement(p.token, ownRank[p.token.id]!)
      else
        _trackPlacement(p.token, p.cell!, counts, seen),
  ];
}

PlacedToken _finishPlacement(Token token, int rank) {
  final slot = ludoGoalSlot(token.color, rank);
  return PlacedToken(token: token, x: slot.x, y: slot.y, size: 0.5);
}

PlacedToken _basePlacement(Token token, int rank) {
  final slot = ludoBaseSlots[rank];
  final corner = ludoCorner(token.color);
  return PlacedToken(
    token: token,
    x: corner.col + slot[1],
    y: corner.row + slot[0],
    size: ludoTokenSize,
  );
}

PlacedToken _trackPlacement(
  Token token,
  Cell cell,
  Map<String, int> counts,
  Map<String, int> seen,
) {
  final key = '${cell.row}:${cell.col}';
  final count = counts[key] ?? 1;
  final order = seen[key] ?? 0;
  seen[key] = order + 1;
  final x = cell.col + 0.5;
  final y = cell.row + 0.5;
  if (count == 1) {
    return PlacedToken(token: token, x: x, y: y, size: ludoTokenSize);
  }
  // Deux pions : diagonale 0 puis 3 ; trois et plus : index d'ordre.
  final offset = ludoStackOffset(order, count);
  return PlacedToken(
    token: token,
    x: x + offset[0],
    y: y + offset[1],
    size: ludoStackSize,
  );
}

/// Points allumés sur chaque face du dé (grille 3 × 3 : index = ligne × 3 + colonne) (#682).
/// Une valeur hors 1 à 6, ou null, n'affiche aucun point au lieu de lever une exception.
List<int> ludoPipIndexes(int? face) => _ludoPipTable[face] ?? const [];

const _ludoPipTable = <int, List<int>>{
  1: [4],
  2: [0, 8],
  3: [0, 4, 8],
  4: [0, 2, 6, 8],
  5: [0, 2, 4, 6, 8],
  6: [0, 2, 3, 5, 6, 8],
};

/// Action à prendre sur l'animation d'un pion quand le plateau est reconstruit (#679).
/// [keep] : progression inchangée, on ne touche à rien (une capture en cours reste visible).
/// [instant] : déplacement sans animation (animations système désactivées).
/// [play] : déplacement animé.
enum LudoHopAction { keep, instant, play }

LudoHopAction ludoHopAction({
  required int from,
  required int to,
  required bool reduced,
}) {
  if (from == to) return LudoHopAction.keep;
  return reduced ? LudoHopAction.instant : LudoHopAction.play;
}

/// Vitesse du saut : millisecondes par case parcourue (#386). Même valeur que le plateau.
const int ludoHopMsPerCell = 150;

/// Décalage vertical du rebond d'un pion jouable, en cases (négatif = vers le haut).
const double ludoBobHeight = 0.18;

/// Rebond d'un pion jouable à la phase [t] (0 à 1) du cycle.
double ludoBobAt(double t) => -ludoBobHeight * math.sin(math.pi * t);

int _pathMs(List<({double x, double y})> points) {
  var cells = 0.0;
  for (var i = 1; i < points.length; i++) {
    final dx = points[i].x - points[i - 1].x;
    final dy = points[i].y - points[i - 1].y;
    cells += math.sqrt(dx * dx + dy * dy);
  }
  return (cells * ludoHopMsPerCell).round();
}

/// Durée (ms) de l'animation d'un coup : le pion joué saute case par case, puis
/// une victime éventuelle (progress remis à 0) part après [ludoVictimDelayMs]
/// et rejoint sa base. Renvoie 0 si aucun pion n'a bougé.
int ludoMoveSettleMs(List<Token> before, List<Token> after) {
  final placedBefore = {for (final p in layoutTokens(before)) p.token.id: p};
  final placedAfter = {for (final p in layoutTokens(after)) p.token.id: p};
  var moverMs = 0;
  var victimEnd = 0;
  for (final token in after) {
    final old = placedBefore[token.id];
    final now = placedAfter[token.id];
    if (old == null || now == null) continue;
    final from = old.token.progress;
    final to = token.progress;
    if (from == to) continue;
    if (to == 0) {
      final victimMs = _pathMs([
        (x: old.x, y: old.y),
        (x: now.x, y: now.y),
      ]);
      victimEnd = math.max(victimEnd, ludoVictimDelayMs + victimMs);
      continue;
    }
    final path = <({double x, double y})>[
      (x: old.x, y: old.y),
      ...ludoHopWaypoints(token.color, from, to),
      (x: now.x, y: now.y),
    ];
    moverMs = math.max(moverMs, _pathMs(path));
  }
  return math.max(moverMs, victimEnd);
}

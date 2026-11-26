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

/// Emplacements d'arrivée pour la couleur rouge, relatifs au centre (#996) : grille 2×2 dans
/// le triangle rouge (dx négatif, |dy| ≤ |dx|). Le rang 0 est le premier arrivé, le même ordre
/// pour toutes les couleurs (les autres couleurs tournent cette figure de 90° autour du centre).
const _ludoGoalGridRed = <List<double>>[
  [-0.6, -0.35],
  [-0.6, 0.35],
  [-1.2, -0.35],
  [-1.2, 0.35],
];

/// Nombre de quarts de tour (sens horaire) depuis le rouge : ouest, nord, est, sud.
int _ludoQuarterTurns(LudoColor color) => switch (color) {
      LudoColor.red => 0,
      LudoColor.green => 1,
      LudoColor.yellow => 2,
      LudoColor.blue => 3,
    };

/// Emplacement d'arrivée du pion de rang [order] (0 à 3) parmi les pions arrivés de [color] (#378, #996).
/// Les quatre couleurs reprennent la même figure, tournée de 90° autour du centre.
({double x, double y}) ludoGoalSlot(LudoColor color, [int order = 0]) {
  final base = _ludoGoalGridRed[order % _ludoGoalGridRed.length];
  var dx = base[0];
  var dy = base[1];
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

/// Arc de la victime renvoyée à la base, en cases (#662).
const double ludoCatapultHeight = 1.6;

/// Tours complets (galipettes) de la victime pendant sa catapulte.
const double ludoVictimSpinTurns = 2;

/// Angle (radians) de la victime à la position [t] (0 à 1) de sa catapulte.
double ludoVictimSpinAngle(double t) => 2 * math.pi * ludoVictimSpinTurns * t;

/// Hauteur du saut à la position [t] (0 à 1) d'un segment de trajet.
/// Le pion qui capture saute comme un pion ordinaire (#882).
double ludoLiftAt(double t) => math.sin(math.pi * t) * ludoHopHeight;

/// Hauteur de l'arc de la victime à la position [t] (0 à 1).
double ludoCatapultLift(double t) => math.sin(math.pi * t) * ludoCatapultHeight;

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
        _finishPlacement(p.token, _arrivalRank(p.token, tokens))
      else
        _trackPlacement(p.token, p.cell!, counts, seen),
  ];
}

/// Rang d'arrivée parmi les pions de la même couleur (0 = premier arrivé) (#996).
/// Sans rang enregistré (sauvegarde ancienne), l'ordre de la liste départage.
int _arrivalRank(Token token, List<Token> tokens) {
  const unknown = 1 << 30;
  final mine = token.arrival ?? unknown;
  var rank = 0;
  for (final item in tokens) {
    if (item.color != token.color || item.progress != ludoFinish) continue;
    final theirs = item.arrival ?? unknown;
    if (theirs < mine || (theirs == mine && item.id != token.id && _listIndex(tokens, item) < _listIndex(tokens, token))) {
      rank++;
    }
  }
  return rank;
}

int _listIndex(List<Token> tokens, Token token) =>
    tokens.indexWhere((item) => item.id == token.id);

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

/// Vitesse rapide : capture et sortie de base (ms par case).
const int ludoFastHopMsPerCell = 90;

/// Vitesse d'un coup : rapide pour une sortie de base, normale sinon (#882 : une capture
/// avance à vitesse normale).
int ludoHopMsPerCellFor({required bool fromBase}) =>
    fromBase ? ludoFastHopMsPerCell : ludoHopMsPerCell;

/// Décalage vertical du rebond d'un pion jouable, en cases (négatif = vers le haut).
const double ludoBobHeight = 0.18;

/// Rebond d'un pion jouable à la phase [t] (0 à 1) du cycle.
double ludoBobAt(double t) => -ludoBobHeight * math.sin(math.pi * t);

int _pathMs(List<({double x, double y})> points, int msPerCell) {
  var cells = 0.0;
  for (var i = 1; i < points.length; i++) {
    final dx = points[i].x - points[i - 1].x;
    final dy = points[i].y - points[i - 1].y;
    cells += math.sqrt(dx * dx + dy * dy);
  }
  return (cells * msPerCell).round();
}

/// Durée (ms) du trajet de chaque pion qui avance dans ce coup (hors victime).
/// Renvoie 0 si aucun pion n'a avancé.
int _moverMs(List<Token> before, List<Token> after) {
  final placedBefore = {for (final p in layoutTokens(before)) p.token.id: p};
  final placedAfter = {for (final p in layoutTokens(after)) p.token.id: p};
  var moverMs = 0;
  for (final token in after) {
    final old = placedBefore[token.id];
    final now = placedAfter[token.id];
    if (old == null || now == null) continue;
    final from = old.token.progress;
    final to = token.progress;
    if (from == to || to == 0) continue;
    final path = <({double x, double y})>[
      (x: old.x, y: old.y),
      ...ludoHopWaypoints(token.color, from, to),
      (x: now.x, y: now.y),
    ];
    moverMs = math.max(
      moverMs,
      _pathMs(path, ludoHopMsPerCellFor(fromBase: from == 0)),
    );
  }
  return moverMs;
}

/// Délai (ms) avant le départ de la victime d'une capture : le temps que l'attaquant
/// arrive sur sa case. La galipette et le son de capture commencent à ce moment (#882).
/// 0 si le coup ne renvoie aucun pion à la base.
int ludoVictimDelayFor(List<Token> before, List<Token> after) {
  final oldProgress = {for (final t in before) t.id: t.progress};
  final captured = after.any(
    (t) => t.progress == 0 && (oldProgress[t.id] ?? 0) != 0,
  );
  return captured ? _moverMs(before, after) : 0;
}

/// Durée (ms) de l'animation d'un coup : le pion joué avance, puis une victime
/// éventuelle (progress remis à 0) part une fois l'attaquant arrivé et rejoint sa base.
/// Renvoie 0 si aucun pion n'a bougé.
int ludoMoveSettleMs(List<Token> before, List<Token> after) {
  final placedBefore = {for (final p in layoutTokens(before)) p.token.id: p};
  final placedAfter = {for (final p in layoutTokens(after)) p.token.id: p};
  final moverMs = _moverMs(before, after);
  final victimDelay = ludoVictimDelayFor(before, after);
  var victimEnd = 0;
  for (final token in after) {
    final old = placedBefore[token.id];
    final now = placedAfter[token.id];
    if (old == null || now == null) continue;
    if (old.token.progress == token.progress || token.progress != 0) continue;
    final victimMs = _pathMs([
      (x: old.x, y: old.y),
      (x: now.x, y: now.y),
    ], ludoFastHopMsPerCell);
    victimEnd = math.max(victimEnd, victimDelay + victimMs);
  }
  return math.max(moverMs, victimEnd);
}

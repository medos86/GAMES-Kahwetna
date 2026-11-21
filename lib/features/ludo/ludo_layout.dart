// Placement des pions sur le plateau 15 × 15 (layoutTokens de LudoGameScreen.tsx).
// Pur Dart : aucun import Flutter, donc testable sans émulateur.
// Les coordonnées sont exprimées en unités de case (le plateau fait 15 unités).

import 'dart:math' as math;

import '../../game/ludo.dart';

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

/// Emplacement d'arrivée de chaque couleur : un triangle au centre, côté de sa couleur (#378).
({double x, double y}) ludoGoalSlot(LudoColor color) => switch (color) {
      LudoColor.red => (x: 6.7, y: 7.5),
      LudoColor.green => (x: 7.5, y: 6.7),
      LudoColor.yellow => (x: 8.3, y: 7.5),
      LudoColor.blue => (x: 7.5, y: 8.3),
    };

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
  final baseSlot = <LudoColor, int>{for (final c in LudoColor.values) c: 0};

  return [
    for (final p in positions)
      if (p.cell == null)
        _basePlacement(p.token, baseSlot)
      else if (p.token.progress == ludoFinish)
        _finishPlacement(p.token)
      else
        _trackPlacement(p.token, p.cell!, counts, seen),
  ];
}

PlacedToken _finishPlacement(Token token) {
  final slot = ludoGoalSlot(token.color);
  return PlacedToken(token: token, x: slot.x, y: slot.y, size: 0.5);
}

PlacedToken _basePlacement(Token token, Map<LudoColor, int> baseSlot) {
  final slot = ludoBaseSlots[baseSlot[token.color]!];
  baseSlot[token.color] = baseSlot[token.color]! + 1;
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
  final offset = ludoStackOffsets[count == 2 ? order * 3 : order];
  return PlacedToken(
    token: token,
    x: x + offset[0],
    y: y + offset[1],
    size: ludoStackSize,
  );
}

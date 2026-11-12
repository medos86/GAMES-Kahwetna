// Placement des pions sur le plateau 15 × 15 (layoutTokens de LudoGameScreen.tsx).
// Pur Dart : aucun import Flutter, donc testable sans émulateur.
// Les coordonnées sont exprimées en unités de case (le plateau fait 15 unités).

import '../../game/ludo.dart';

const ludoBoardUnits = 15;
const ludoTokenSize = 0.8;
const ludoStackSize = 0.46;

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

/// Calcule le centre et la taille de chaque pion.
List<PlacedToken> layoutTokens(List<Token> tokens) {
  final positions = [
    for (final token in tokens) (token: token, cell: cellOf(token)),
  ];

  final counts = <String, int>{};
  for (final p in positions) {
    final cell = p.cell;
    if (cell == null) continue;
    final key = '${cell.row}:${cell.col}';
    counts[key] = (counts[key] ?? 0) + 1;
  }

  final seen = <String, int>{};
  final baseSlot = <LudoColor, int>{for (final c in LudoColor.values) c: 0};

  return [
    for (final p in positions)
      if (p.cell == null)
        _basePlacement(p.token, baseSlot)
      else
        _trackPlacement(p.token, p.cell!, counts, seen),
  ];
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

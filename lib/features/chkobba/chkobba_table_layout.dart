import 'dart:ui' show Offset;

/// Espace entre deux cartes posées sur le tapis.
const double kChkobbaTableGap = 6;

/// Hauteur de la main du joueur : plus grande qu'avant pour une meilleure lisibilité.
double chkobbaHandCardHeight(double screenHeight) =>
    (screenHeight * 0.15).clamp(64.0, 120.0);

/// Position d'un emplacement du tapis, en cases, relative au centre du tapis.
///
/// Les cartes se posent au centre : d'abord la rangée centrale, puis les rangées
/// voisines. La position ne dépend que de l'index de l'emplacement et du nombre
/// de colonnes : retirer une carte ne fait jamais bouger les autres (#chkobba-stable).
Offset chkobbaCellOffset(int slot, int columns) {
  assert(columns > 0 && slot >= 0);
  final rows = slot ~/ columns + 1;
  final cells = <Offset>[
    for (var dy = -rows; dy <= rows; dy++)
      for (var c = 0; c < columns; c++)
        Offset(c - (columns - 1) / 2, dy.toDouble()),
  ];
  cells.sort((a, b) {
    final byRow = a.dy.abs().compareTo(b.dy.abs());
    if (byRow != 0) return byRow;
    final byCol = a.dx.abs().compareTo(b.dx.abs());
    if (byCol != 0) return byCol;
    final byX = a.dx.compareTo(b.dx);
    if (byX != 0) return byX;
    return a.dy.compareTo(b.dy);
  });
  return cells[slot];
}

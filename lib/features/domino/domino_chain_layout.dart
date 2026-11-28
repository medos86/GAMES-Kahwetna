import 'dart:math' as math;

// Placement de la chaîne autour de la première pierre (#930).
// Grille en unités d'une demi-pierre : une horizontale fait 2 x 1, une verticale 1 x 2.
// La première pierre est au centre. Le bras droit part vers la droite et descend ;
// le bras gauche est son symétrique : il part vers la gauche et monte. Le tapis reste centré.

/// Position d'une pierre dans la grille (coin haut-gauche, en unités de demi-pierre).
class ChainSlot {
  const ChainSlot({
    required this.x,
    required this.y,
    required this.vertical,
    required this.reverse,
  });

  final int x;
  final int y;
  final bool vertical;

  /// Vrai si la chaîne va de droite à gauche sur l'écran : les demi-pierres sont inversées.
  final bool reverse;

  int get width => vertical ? 1 : 2;
  int get height => vertical ? 2 : 1;
}

/// Place [count] pierres ; la pierre d'index [openIndex] est la pierre de départ.
/// Deux bras partent de la pierre de départ, chacun ouvert à une extrémité en permanence (#1069).
/// Chaque rangée complète a exactement un virage, au bord du tapis. [halfWidth] est la demi-largeur
/// du tapis en demi-pierres ; le tapis va de -halfWidth à halfWidth.
List<ChainSlot> layoutChainAroundCenter({
  required int count,
  required int openIndex,
  required int halfWidth,
}) {
  if (count < 1 || openIndex < 0 || openIndex >= count) {
    throw ArgumentError('index d\'ouverture hors de la chaîne');
  }
  if (halfWidth < 4) {
    throw ArgumentError('halfWidth doit être au moins 4');
  }
  final hw = halfWidth;
  final width = 2 * hw;
  // Pierre de départ : centrée si la parité le permet, décalée d'une case sinon.
  final c = hw.isEven ? hw - 1 : hw - 2;
  final slots = List<ChainSlot?>.filled(count, null);
  slots[openIndex] =
      ChainSlot(x: c - hw, y: 0, vertical: false, reverse: false);
  final leftTotal = openIndex;
  final rightTotal = count - 1 - openIndex;
  if (leftTotal > 0) {
    slots[openIndex - 1] =
        ChainSlot(x: c - 1 - hw, y: 0, vertical: true, reverse: false);
    final arm = _armSlots(
      isLeft: true,
      lo: 0,
      hi: c,
      vCol: c - 1,
      n: leftTotal - 1,
      offset: hw,
    );
    for (var j = 0; j < arm.length; j++) {
      slots[openIndex - 2 - j] = arm[j];
    }
  }
  if (rightTotal > 0) {
    slots[openIndex + 1] =
        ChainSlot(x: c + 2 - hw, y: 0, vertical: true, reverse: false);
    final arm = _armSlots(
      isLeft: false,
      lo: c + 2,
      hi: width,
      vCol: c + 2,
      n: rightTotal - 1,
      offset: hw,
    );
    for (var j = 0; j < arm.length; j++) {
      slots[openIndex + 2 + j] = arm[j];
    }
  }
  return [for (final slot in slots) slot!];
}

/// Un bras, en coordonnées du tapis (de 0 à la largeur), décalé de [offset] à la fin.
/// Chaque rangée a toutes ses horizontales puis un virage au bord, et la rangée suivante repart
/// du bord opposé. Les virages occupent deux bandes : les rangées sont donc sur les bandes paires.
List<ChainSlot> _armSlots({
  required bool isLeft,
  required int lo,
  required int hi,
  required int vCol,
  required int n,
  required int offset,
}) {
  final out = <ChainSlot>[];
  final halves = (hi - lo - 1) ~/ 2;
  var y = 2;
  var vAtLeft = isLeft;
  var cur = vCol;
  while (out.length < n) {
    final vx = vAtLeft ? lo : hi - 1;
    final starts = <int>[
      for (var j = 0; j < halves; j++) vAtLeft ? lo + 1 + 2 * j : lo + 2 * j,
    ];
    starts.sort((a, b) => (a - cur).abs().compareTo((b - cur).abs()));
    for (final x in starts) {
      if (out.length >= n) break;
      out.add(
        ChainSlot(x: x - offset, y: y, vertical: false, reverse: vAtLeft),
      );
    }
    if (out.length < n) {
      out.add(ChainSlot(x: vx - offset, y: y, vertical: true, reverse: false));
    }
    cur = vx;
    y += 2;
    vAtLeft = !vAtLeft;
  }
  return out;
}

/// Taille d'une demi-pierre au départ (#1022) : une pierre horizontale fait le tiers de la largeur,
/// pour que la chaîne commence grande sur tous les écrans. Le zoom arrière ne s'applique qu'en cas de débordement.
double chainStartUnit({required double width, required int halfWidth}) =>
    width / 6;

/// Zoom de la chaîne (#960, #1036, #1043) : 1 tant qu'elle tient en largeur ET en hauteur,
/// réduit dès qu'elle déborde dans l'une ou l'autre. La chaîne ne défile jamais.
/// [unit] est la taille d'une demi-pierre ; la première pierre est centrée en (0, 0.5).
double chainScale({
  required List<ChainSlot> slots,
  required double unit,
  required double width,
  required double height,
}) {
  var minX = 0;
  var maxX = 0;
  for (final slot in slots) {
    minX = math.min(minX, slot.x);
    maxX = math.max(maxX, slot.x + slot.width);
  }
  final halfWidth = math.max(-minX, maxX) * unit;
  final byWidth = halfWidth <= 0 ? 1.0 : (width / 2) / halfWidth;
  final halfHeight = chainHalfHeight(slots: slots, unit: unit);
  final byHeight = halfHeight <= 0 ? 1.0 : (height / 2) / halfHeight;
  return math.min(1.0, math.min(byWidth, byHeight));
}

/// Demi-hauteur de la chaîne en pixels, depuis le centre de la première pierre (#1036).
/// Sert à dimensionner la zone défilante verticale.
double chainHalfHeight({required List<ChainSlot> slots, required double unit}) {
  var minY = 0;
  var maxY = 1;
  for (final slot in slots) {
    minY = math.min(minY, slot.y);
    maxY = math.max(maxY, slot.y + slot.height);
  }
  return math.max(0.5 - minY, maxY - 0.5) * unit;
}

/// Chaîne placée et zoomée ensemble (#1028) : le bord du tapis est recalculé à partir du zoom appliqué.
class FittedChain {
  const FittedChain({required this.slots, required this.scale});

  final List<ChainSlot> slots;
  final double scale;
}

/// Demi-largeur du tapis en unités de demi-pierre, à un zoom donné : paire, au moins 4.
int chainEdgeAtZoom({
  required double width,
  required double unit,
  required double zoom,
}) {
  final edge = (width / 2 / (unit * zoom)).floor();
  return math.max(4, edge - edge % 2);
}

/// Place la chaîne pour un écran donné (#1069) : le tapis est calculé à partir de la largeur réelle.
/// On prend le plus grand nombre pair de demi-pierres qui tient en largeur, puis la taille de demi-pierre
/// est recalée pour que le bord tombe exactement sur le bord de l'écran. Si la chaîne déborde en hauteur,
/// on réduit le bord (toujours pair) et on recalcule. Chaque rangée reste donc complète : n pierres
/// entières puis le virage au bord.
FittedChain layoutChainFitted({
  required int count,
  required int openIndex,
  required double width,
  required double height,
  required double unit,
}) {
  final half = width / 2;
  var edge = math.max(4, (half / unit).floor());
  edge -= edge % 2;
  // Une chaîne trop haute se raccourcit en élargissant le bord : plus de pierres par rangée.
  final maxEdge = 2 * count + 4;
  while (true) {
    final cellUnit = half / edge;
    final slots = layoutChainAroundCenter(
      count: count,
      openIndex: openIndex,
      halfWidth: edge,
    );
    final halfHeight = chainHalfHeight(slots: slots, unit: cellUnit);
    if (halfHeight <= height / 2 || edge >= maxEdge) {
      return FittedChain(slots: slots, scale: cellUnit / unit);
    }
    edge += 2;
  }
}

/// Échelle qui fait tenir exactement [edge] demi-pierres dans la moitié de la largeur.
double fullWidthScale({
  required int edge,
  required double width,
  required double unit,
}) =>
    (width / 2) / (edge * unit);

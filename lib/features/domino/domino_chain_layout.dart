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

/// Place [count] pierres ; la pierre d'index [openIndex] est au centre.
/// [halfWidth] est la demi-largeur du tapis en unités (pair, au moins 4).
List<ChainSlot> layoutChainAroundCenter({
  required int count,
  required int openIndex,
  required int halfWidth,
}) {
  if (count < 1 || openIndex < 0 || openIndex >= count) {
    throw ArgumentError('index d\'ouverture hors de la chaîne');
  }
  if (halfWidth < 4 || halfWidth.isOdd) {
    throw ArgumentError('halfWidth doit être pair et au moins 4');
  }
  final right = _arm(count - 1 - openIndex, halfWidth);
  final left = _arm(openIndex, halfWidth).map(_mirror).toList();
  final slots = List<ChainSlot?>.filled(count, null);
  slots[openIndex] =
      const ChainSlot(x: -1, y: 0, vertical: false, reverse: false);
  for (var j = 0; j < right.length; j++) {
    slots[openIndex + 1 + j] = right[j];
  }
  for (var j = 0; j < left.length; j++) {
    slots[openIndex - 1 - j] = left[j];
  }
  return [for (final slot in slots) slot!];
}

/// Un bras : rangées horizontales, virage vertical en bout de rangée, vers le bas.
/// Chaque rangée va jusqu'au bord du tapis (droit puis gauche, en alternance) avant de tourner.
List<ChainSlot> _arm(int count, int halfWidth) {
  final out = <ChainSlot>[];
  var y = 0;
  var rightward = true;
  var cx = 1;
  while (out.length < count) {
    if (rightward) {
      if (cx <= halfWidth - 3) {
        out.add(ChainSlot(x: cx, y: y, vertical: false, reverse: false));
        cx += 2;
      } else {
        out.add(
          ChainSlot(x: halfWidth - 1, y: y, vertical: true, reverse: false),
        );
        y += 2;
        rightward = false;
        cx = halfWidth - 2;
      }
    } else {
      // La rangée de retour va jusqu'au bord gauche du tapis, comme la première rangée va jusqu'au bord droit.
      if (cx >= 2 - halfWidth) {
        out.add(ChainSlot(x: cx, y: y, vertical: false, reverse: true));
        cx -= 2;
      } else {
        out.add(
          ChainSlot(x: 1 - halfWidth, y: y, vertical: true, reverse: false),
        );
        y += 2;
        rightward = true;
        cx = 1 - halfWidth;
      }
    }
  }
  return out;
}

/// Symétrie par rapport à l'axe vertical du centre, puis miroir vertical autour de la pierre d'ouverture.
ChainSlot _mirror(ChainSlot slot) => ChainSlot(
      x: -(slot.x + slot.width),
      y: 1 - (slot.y + slot.height),
      vertical: slot.vertical,
      reverse: slot.reverse,
    );

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

/// Place la chaîne au zoom réel : on part du zoom 1, on recalcule le bord du tapis à ce zoom,
/// puis on réduit le zoom tant que la chaîne déborde en largeur ou en hauteur. Le virage se fait
/// donc au bord affiché, et la chaîne tient toujours dans la zone sans défilement (#1043).
FittedChain layoutChainFitted({
  required int count,
  required int openIndex,
  required double width,
  required double height,
  required double unit,
}) {
  var zoom = 1.0;
  var slots = <ChainSlot>[];
  var fit = 1.0;
  for (var i = 0; i < 40; i++) {
    final edge = chainEdgeAtZoom(width: width, unit: unit, zoom: zoom);
    slots = layoutChainAroundCenter(
      count: count,
      openIndex: openIndex,
      halfWidth: edge,
    );
    fit = chainScale(slots: slots, unit: unit, width: width, height: height);
    if (fit >= zoom - 1e-9) break;
    zoom = fit;
  }
  // Remplissage de la largeur (#1064) : l'arrondi pair peut laisser une case vide au bord du tapis.
  // On agrandit l'échelle pour que le bord calculé tombe exactement sur le bord de l'écran,
  // tant que la chaîne tient toujours en hauteur. Toujours : une rangée ne tourne qu'au bord.
  final edge = chainEdgeAtZoom(width: width, unit: unit, zoom: fit);
  final fill = fullWidthScale(edge: edge, width: width, unit: unit);
  if (fill > fit) {
    final filled = layoutChainAroundCenter(
      count: count,
      openIndex: openIndex,
      halfWidth: edge,
    );
    final heightFit = chainScale(
      slots: filled,
      unit: unit * fill,
      width: width,
      height: height,
    );
    if (heightFit >= 1.0 - 1e-9) {
      return FittedChain(slots: filled, scale: fill);
    }
  }
  return FittedChain(slots: slots, scale: fit);
}

/// Échelle qui fait tenir exactement [edge] demi-pierres dans la moitié de la largeur.
double fullWidthScale({
  required int edge,
  required double width,
  required double unit,
}) =>
    (width / 2) / (edge * unit);

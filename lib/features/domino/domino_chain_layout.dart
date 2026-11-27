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
      if (cx >= 2) {
        out.add(ChainSlot(x: cx, y: y, vertical: false, reverse: true));
        cx -= 2;
      } else {
        out.add(ChainSlot(x: 1, y: y, vertical: true, reverse: false));
        y += 2;
        rightward = true;
        cx = 1;
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

/// Zoom de la chaîne (#960) : 1 tant qu'elle tient dans le tapis, réduit seulement quand elle déborde.
/// [unit] est la taille d'une demi-pierre ; la première pierre est centrée en (0, 0.5).
double chainScale({
  required List<ChainSlot> slots,
  required double unit,
  required double width,
  required double height,
}) {
  var minX = 0;
  var minY = 0;
  var maxX = 0;
  var maxY = 1;
  for (final slot in slots) {
    minX = math.min(minX, slot.x);
    minY = math.min(minY, slot.y);
    maxX = math.max(maxX, slot.x + slot.width);
    maxY = math.max(maxY, slot.y + slot.height);
  }
  final halfWidth = math.max(-minX, maxX) * unit;
  final halfHeight = math.max(0.5 - minY, maxY - 0.5) * unit;
  final byWidth = halfWidth <= 0 ? 1.0 : (width / 2) / halfWidth;
  final byHeight = halfHeight <= 0 ? 1.0 : (height / 2) / halfHeight;
  return math.min(1.0, math.min(byWidth, byHeight));
}

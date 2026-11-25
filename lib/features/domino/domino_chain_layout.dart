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

import 'dart:math' as math;

/// Inclinaison (en radians) de la carte [index] d'une main de [count] cartes.
/// La main forme un éventail : le centre reste droit, les bords penchent vers l'extérieur.
double ramiFanAngle(int index, int count) {
  if (count <= 1) return 0;
  // Au plus environ 4° pour les cartes du bord (0,07 rad).
  final tilt = math.min(0.012, 0.07 / math.max(1, (count - 1) / 2));
  return (index - (count - 1) / 2) * tilt;
}

/// Décalage horizontal de la carte [index] pendant un glissement : à partir de [gapAt],
/// les cartes s'écartent pour ouvrir l'emplacement où la carte va atterrir.
/// [gapAt] vaut -1 quand il n'y a pas de dépôt dans la main.
double ramiGapOffset(int index, int gapAt, double step) =>
    gapAt >= 0 && index >= gapAt ? step * 0.9 : 0;

/// Ordre de dessin de la main : de gauche à droite (chaque carte recouvre seulement la
/// précédente, donc les coins d'index restent visibles), la carte déplacée en dernier.
List<int> ramiDrawOrder(int count, int? dragged) {
  final order = <int>[];
  for (var j = 0; j < count; j++) {
    if (j != dragged) order.add(j);
  }
  if (dragged != null) order.add(dragged);
  return order;
}

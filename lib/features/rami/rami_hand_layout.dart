import '../../game/rami.dart' as rules;

/// Facteur d'agrandissement des cartes de la main (#314 : plus grandes, lisibles).
const double ramiHandCardScale = 1.6;

/// Écart vertical entre le tapis et la main du joueur (#319) : 2 px au-dessus de la main,
/// soit 4 px au total (au lieu de 12 px avant).
const double ramiHandGap = 2;

/// Pioche et défausse, en fraction de la largeur d'une carte de la main (plus grandes qu'avant).
const double ramiPileScale = 0.6;

/// Largeur d'une carte de la pioche ou de la défausse.
double ramiPileWidth(double handWidth) => handWidth * ramiPileScale;

/// Écartement des cartes d'un paquet sur le tapis, en fraction de la largeur d'une carte.
const double ramiMeldStepRatio = 0.4;

const double _meldPadding = 6;
const double _meldGap = 3;
const double _minTableCardWidth = 36;

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

double _meldWidth(int count, double cardWidth) =>
    cardWidth + cardWidth * ramiMeldStepRatio * (count - 1) + _meldPadding;

/// Nombre de rangées nécessaires pour ranger les paquets de [sizes] (de gauche à droite,
/// comme un Wrap). Renvoie null si un paquet seul ne tient pas dans [areaWidth].
int? ramiMeldRows(List<int> sizes, double cardWidth, double areaWidth) {
  var rows = 0;
  var used = 0.0;
  for (final count in sizes) {
    final width = _meldWidth(count, cardWidth);
    if (width > areaWidth) return null;
    if (rows == 0) {
      rows = 1;
      used = width;
    } else if (used + _meldGap + width <= areaWidth) {
      used += _meldGap + width;
    } else {
      rows++;
      used = width;
    }
  }
  return rows;
}

/// Largeur de carte du tapis : la plus grande (entre le minimum et [maxWidth]) pour que
/// tous les paquets tiennent dans la zone [areaWidth] × [areaHeight].
double ramiTableCardWidth(
  List<int> sizes,
  double areaWidth,
  double areaHeight,
  double maxWidth,
) {
  if (sizes.isEmpty) return maxWidth;
  bool fits(double w) {
    final rows = ramiMeldRows(sizes, w, areaWidth);
    if (rows == null) return false;
    final height = rows * (w * 1.4 + _meldPadding) + (rows - 1) * _meldGap;
    return height <= areaHeight;
  }

  if (!fits(_minTableCardWidth)) return _minTableCardWidth;
  if (fits(maxWidth)) return maxWidth;
  var lo = _minTableCardWidth;
  var hi = maxWidth;
  for (var i = 0; i < 20; i++) {
    final mid = (lo + hi) / 2;
    if (fits(mid)) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return lo;
}

/// Coup d'un adversaire (#316) : détecté en comparant l'état avant et après.
enum RamiAiMove { drawStock, takeDiscard, discard }

/// Coups joués par l'adversaire qui vient de jouer (`prev.turn`), pour animer sa pioche
/// et sa défausse. Vide si c'était le tour du joueur ou si rien n'a bougé dans la pioche/défausse.
List<RamiAiMove> ramiAiMoves(rules.RamiState prev, rules.RamiState next) {
  if (prev.turn == 0) return const [];
  final moves = <RamiAiMove>[];
  if (next.stock.length < prev.stock.length) moves.add(RamiAiMove.drawStock);
  if (next.discard.length < prev.discard.length) {
    moves.add(RamiAiMove.takeDiscard);
  } else if (next.discard.length > prev.discard.length) {
    moves.add(RamiAiMove.discard);
  }
  return moves;
}

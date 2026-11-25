import '../../game/rami.dart' as rules;

/// Facteur d'agrandissement des cartes de la main (#314 : plus grandes, lisibles).
const double ramiHandCardScale = 1.55;

/// Remontée d'une carte sélectionnée, en fraction de sa largeur (#906).
const double ramiSelectLift = 0.25;

/// Pioche et défausse, en fraction de la largeur d'une carte de la main (plus grandes qu'avant).
const double ramiPileScale = 0.6;

/// Largeur d'une carte de la pioche ou de la défausse.
double ramiPileWidth(double handWidth) => handWidth * ramiPileScale;

/// Écartement des cartes d'un paquet sur le tapis, en fraction de la largeur d'une carte.
const double ramiMeldStepRatio = 0.4;

/// Décalage entre deux cartes posées dans une même combinaison (#592).
const Duration ramiPoseStagger = Duration(milliseconds: 120);

/// Coin gauche de la carte n°[index] d'une combinaison dont le coin gauche est [left] (#592).
double ramiMeldSlotLeft(double left, double cardWidth, int index) =>
    left + cardWidth * ramiMeldStepRatio * index;

/// Délai de la carte n°[index] posée : les cartes d'un paquet volent une à une (#592).
Duration ramiPoseDelay(int index) => ramiPoseStagger * index;

/// Pause entre deux paquets posés : le suivant part quand le précédent est presque posé (#943).
const Duration ramiPackGap = Duration(milliseconds: 400);

/// Délai de chaque carte de paquets posés (#943) : un paquet part après le précédent,
/// et ses cartes volent une à une à [ramiPoseStagger] d'écart. Les paquets vides sont ignorés.
List<Duration> ramiPackDelays(List<int> packSizes) {
  final delays = <Duration>[];
  var start = Duration.zero;
  for (final size in packSizes) {
    if (size <= 0) continue;
    for (var i = 0; i < size; i++) {
      delays.add(start + ramiPoseStagger * i);
    }
    start += ramiPoseStagger * (size - 1) + ramiPackGap;
  }
  return delays;
}

/// Marge réelle d'un paquet sur le tapis : 4 px de padding + bordure de 2 px, de chaque côté (#453).
const double _meldPadding = 12;
const double _meldGap = 3;
const double _minTableCardWidth = 36;

/// Décalage horizontal de la carte [index] pendant un glissement : à partir de [gapAt],
/// les cartes s'écartent pour ouvrir l'emplacement où la carte va atterrir.
/// [gapAt] vaut -1 quand il n'y a pas de dépôt dans la main.
double ramiGapOffset(int index, int gapAt, double step) =>
    gapAt >= 0 && index >= gapAt ? step * 0.9 : 0;

/// Pas entre deux cartes de la main (#896, #922) : 60 % de la largeur de carte, resserré
/// pour tenir exactement sur [maxW]. La largeur de carte ne change jamais : seul le
/// chevauchement varie. Pas de plancher : la main ne dépasse jamais la largeur et ne défile pas.
double ramiHandStep(int n, double cardWidth, double maxW) {
  if (n <= 1) return 0;
  final room = (maxW - cardWidth) / (n - 1);
  final natural = 0.6 * cardWidth;
  final step = room < natural ? room : natural;
  return step < 0 ? 0 : step;
}

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

/// Range les paquets de [sizes] dans des rangées : chaque paquet va dans la première rangée
/// où il tient, donc les trous du haut sont remplis. Renvoie, pour chaque paquet, l'index de
/// sa rangée. Renvoie null si un paquet seul ne tient pas dans [areaWidth].
List<int>? ramiPackMelds(List<int> sizes, double cardWidth, double areaWidth) {
  final rowUsed = <double>[];
  final rowOf = <int>[];
  for (final count in sizes) {
    final width = _meldWidth(count, cardWidth);
    if (width > areaWidth) return null;
    var placed = -1;
    for (var r = 0; r < rowUsed.length; r++) {
      if (rowUsed[r] + _meldGap + width <= areaWidth) {
        placed = r;
        break;
      }
    }
    if (placed == -1) {
      rowUsed.add(width);
      placed = rowUsed.length - 1;
    } else {
      rowUsed[placed] += _meldGap + width;
    }
    rowOf.add(placed);
  }
  return rowOf;
}

/// Ordre d'affichage des paquets, groupés par rangée (ordre d'origine conservé dans chaque
/// rangée) : un Wrap reproduit alors exactement le rangement de [ramiPackMelds].
List<int> ramiPackedOrder(List<int> rowOf) {
  final order = List<int>.generate(rowOf.length, (i) => i);
  order.sort((a, b) {
    final byRow = rowOf[a].compareTo(rowOf[b]);
    return byRow != 0 ? byRow : a.compareTo(b);
  });
  return order;
}

/// Nombre de rangées nécessaires pour ranger les paquets de [sizes]. Renvoie null si un
/// paquet seul ne tient pas dans [areaWidth].
int? ramiMeldRows(List<int> sizes, double cardWidth, double areaWidth) {
  final rowOf = ramiPackMelds(sizes, cardWidth, areaWidth);
  if (rowOf == null) return null;
  if (rowOf.isEmpty) return 0;
  return rowOf.reduce((a, b) => a > b ? a : b) + 1;
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
enum RamiAiMove { recycle, drawStock, takeDiscard, discard }

/// Nombre de cartes animées lors d'un recyclage de la défausse (au plus ce nombre, pour rester fluide).
const int ramiRecycleVisualCards = 6;

/// Distribution (#876) : un tour de table dure [ramiDealStep] par carte ; dans un tour,
/// chaque siège attend [ramiDealSeatStagger] de plus. Chaque carte vole [ramiDealFlight].
const Duration ramiDealStep = Duration(milliseconds: 220);
const Duration ramiDealSeatStagger = Duration(milliseconds: 70);
const Duration ramiDealFlight = Duration(milliseconds: 420);

/// Décalage entre deux cartes qui reviennent de la défausse vers la pioche.
const Duration ramiRecycleStagger = Duration(milliseconds: 70);

/// Vol d'une carte de la défausse vers la pioche.
const Duration ramiRecycleFlight = Duration(milliseconds: 350);

/// Nombre de cartes à animer pour un recyclage de [discardSize] cartes (0 : rien à animer).
int ramiRecycleFlightCount(int discardSize) {
  final movable = discardSize - 1; // la carte du dessus reste à la défausse
  if (movable <= 0) return 0;
  return movable < ramiRecycleVisualCards ? movable : ramiRecycleVisualCards;
}

/// Durée totale d'un recyclage animé : la pioche part une fois le recyclage terminé.
Duration ramiRecycleTotal(int flightCount) => flightCount == 0
    ? Duration.zero
    : ramiRecycleStagger * (flightCount - 1) + ramiRecycleFlight;

/// Cartes de [ids] présentes sur le tapis de [state], groupées par paquet (#943).
/// Un paquet sans carte retenue n'apparaît pas.
List<List<rules.RamiCard>> ramiPacksAmong(
  rules.RamiState state,
  Set<String> ids,
) {
  final packs = <List<rules.RamiCard>>[];
  for (final meld in state.table) {
    final picked = [
      for (final card in meld.cards)
        if (ids.contains(card.id)) card,
    ];
    if (picked.isNotEmpty) packs.add(picked);
  }
  return packs;
}

/// Cartes posées sur le tapis par l'adversaire qui vient de jouer (#878), groupées par
/// paquet dans l'ordre du tapis (#943). Vide pendant son propre tour.
List<List<rules.RamiCard>> ramiNewTablePacks(
  rules.RamiState prev,
  rules.RamiState next,
) {
  if (prev.turn == 0) return const [];
  final before = {
    for (final meld in prev.table)
      for (final card in meld.cards) card.id,
  };
  final fresh = {
    for (final meld in next.table)
      for (final card in meld.cards)
        if (!before.contains(card.id)) card.id,
  };
  return ramiPacksAmong(next, fresh);
}

/// Cartes posées sur le tapis par l'adversaire qui vient de jouer (#878) : celles
/// absentes du tapis précédent, dans l'ordre des paquets. Vide pendant son propre tour.
List<rules.RamiCard> ramiNewTableCards(
  rules.RamiState prev,
  rules.RamiState next,
) {
  return [for (final pack in ramiNewTablePacks(prev, next)) ...pack];
}

/// Coups joués par l'adversaire qui vient de jouer (`prev.turn`), pour animer sa pioche
/// et sa défausse. Vide si c'était le tour du joueur ou si rien n'a bougé dans la pioche/défausse.
List<RamiAiMove> ramiAiMoves(rules.RamiState prev, rules.RamiState next) {
  if (prev.turn == 0) return const [];
  final moves = <RamiAiMove>[];
  // Recyclage : la défausse redevient pioche avant la pioche de l'adversaire (#646).
  final recycled = next.recycles > prev.recycles;
  if (recycled) moves.add(RamiAiMove.recycle);
  if (recycled || next.stock.length < prev.stock.length) {
    moves.add(RamiAiMove.drawStock);
  }
  // Après un recyclage, la défausse ne garde que sa carte du dessus : ce n'est pas une prise.
  if (!recycled) {
    if (next.discard.length < prev.discard.length) {
      moves.add(RamiAiMove.takeDiscard);
    } else if (next.discard.length > prev.discard.length) {
      moves.add(RamiAiMove.discard);
    }
  }
  return moves;
}

/// Vol des cartes qui quittent la main ? Non quand le geste est un glisser-déposer :
/// seule la pose par bouton (ou tap) anime le départ (#944).
bool ramiShouldFlyLeaving({
  required bool silentDrop,
  required bool hasLeaving,
}) =>
    !silentDrop && hasLeaving;

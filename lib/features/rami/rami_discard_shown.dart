import '../../game/rami.dart' as rules;

/// Carte visible sur le tas de défausse (#346).
///
/// Pendant qu'une carte vole vers la défausse (son identifiant est dans
/// [landing]), le tas montre la carte précédente au lieu de rester vide.
/// Sans carte précédente, le tas est vide.
rules.RamiCard? ramiDiscardShown(
  List<rules.RamiCard> discard,
  Set<String> landing,
) {
  if (discard.isEmpty) return null;
  final top = discard.last;
  if (!landing.contains(top.id)) return top;
  return discard.length >= 2 ? discard[discard.length - 2] : null;
}

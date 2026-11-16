/// Texte d'une manche : valeur signée (#298). Gagnant -10 donne « -10 », perdant « +100 ».
String ramiPenaltyText(int penalty) => penalty > 0 ? '+$penalty' : '$penalty';

/// Motif affiché sous le nom de chaque joueur en fin de manche (#298).
String ramiSeatReason({
  required bool isWinner,
  required bool opened,
}) {
  if (isWinner) return 'Gagnant';
  if (!opened) return 'Pas ouvert';
  return 'Cartes en main';
}
